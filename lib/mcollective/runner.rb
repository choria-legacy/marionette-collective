module MCollective
  class Runner
    attr_reader :state

    def initialize(configfile)
      begin
        @config = Config.instance
        @config.loadconfig(configfile) unless @config.configured
        @config.mode = :server
        @stats = PluginManager["global_stats"]
        @connection = PluginManager["connector_plugin"]

        # @state describes the current contextual state of the MCollective runner.
        # Valid states are:
        #   :running   - MCollective is alive and receiving messages from the middleware
        #   :stopping  - MCollective is shutting down and in the process of terminating
        #   :stopped   - MCollective is not running
        #   :pausing   - MCollective is going into it's paused state
        #   :unpausing - MCollective is waking up from it's paused state
        #   :paused    - MCollective is paused and not receiving messages but can be woken up
        @state = :stopped
        @exit_receiver_thread = false
        @registration_thread = nil
        @agent_threads = []

        @security = PluginManager["security_plugin"]
        @security.initiated_by = :node

        unless Util.windows?
          Signal.trap("USR1") do
            Thread.new do
              Log.info("Reloading all agents after receiving USR1 signal")
              @agents.loadagents
            end
          end

          Signal.trap("USR2") do
            Thread.new do
              Log.info("Cycling logging level due to USR2 signal")
              Log.cycle_level
            end
          end

          Signal.trap("WINCH") do
            Thread.new do
              Log.info("Reopening logfiles due to WINCH signal")
              Log.reopen
              Log.info("Reopened logfiles due to WINCH signal")
            end
          end
        else
          Util.setup_windows_sleeper
        end
      rescue => e
        Log.error("Failed to initialize MCollective runner.")
        Log.error(e)
        Log.error(e.backtrace.join("\n\t"))
        raise e
      end
    end

    # Deprecated
    def run
      Log.warn("The #run method has been deprecated. Use #main_loop instead.")
      main_loop
    end

    # The main runner loop
    def main_loop
      # Enter the main context
      @receiver_thread = start_receiver_thread
      loop do
        begin
          case @state
          when :stopping
            Log.debug("Stopping MCollective server")

            # If soft_shutdown has been enabled we wait for all running agents to
            # finish, one way or the other.
            if @config.soft_shutdown
              soft_shutdown
            end

            stop_threads
            @state = :stopped
            return

          # When pausing we stop the receiver thread but keep everything else alive
          # This means that running agents also run to completion.
          when :pausing
            Log.debug("Pausing MCollective server")
            stop_threads
            @state = :paused

          when :unpausing
            Log.debug("Unpausing MCollective server")
            start_receiver_thread
          end

          # prune dead threads from the agent_threads array
          @agent_threads.reject! { |t| !t.alive? }
          sleep 0.1
        rescue SignalException => e
          Log.info("Exiting after signal: #{e}")
          stop
        rescue => e
          Log.error("A failure occurred in the MCollective runner.")
          Log.error(e)
          Log.error(e.backtrace.join("\n\t"))
          stop
        end
      end
    end

    def stop
      @state = :stopping
    end

    def pause
      if @state == :running
        @state = :pausing
      else
        Log.error("Cannot pause MCollective while not in a running state")
      end
    end

    def resume
      if @state == :paused
        @state = :unpausing
      else
        Log.error("Cannot unpause MCollective when it is not paused")
      end
    end

    private

    def start_receiver_thread
      @state = :running
      @parent = Thread.current
      Thread.new do
        begin
          receiver_thread
        rescue Exception => e
          # When we are pausing the receiver thread will be killed.
          # If the thread raises an exception at any other time
          # reraise it in the main thread.
          if @state != :pausing
            @parent.raise(e)
          end
        end
      end
    end

    def stop_threads
      @receiver_thread.kill if @receiver_thread.alive?
      # Kill the registration thread if it was made and alive
      if @registration_thread && @registration_thread.alive?
        @registration_thread.kill
      end
    end

    def receiver_thread
      # Create internal connection in Connector
      @connection.connect

      # Subscribe to the direct addressing queue if direct_addressing is enabled
      if @config.direct_addressing
        Util.subscribe_to_direct_addressing_queue
      end

      #   Create the agents and let them create their subscriptions
      @agents ||= Agents.new

      #   Load data sources
      Data.load_data_sources

      # Start the registration plugin if interval isn't 0
      begin
        if @config.registerinterval != 0
          @registration_thread = PluginManager["registration_plugin"].run(@connection)
        end
      rescue Exception => e
        Log.error("Failed to start registration plugin: #{e}")
      end

      # Start the receiver loop
      loop do
        begin
          request = receive

          @agent_threads << agentmsg(request)
        rescue MsgTTLExpired => e
          Log.warn(e)

        rescue NotTargettedAtUs => e
          Log.debug("Message does not pass filters, ignoring")

        rescue MessageNotReceived, UnexpectedMessageType => e
          Log.warn(e)
          if e.backoff && @state != :stopping
            Log.info("sleeping for suggested #{e.backoff} seconds")
            sleep e.backoff
          end

        rescue Exception => e
          Log.warn("Failed to handle message: #{e} - #{e.class}\n")
          Log.warn(e.backtrace.join("\n\t"))
        end

        return if @exit_receiver_thread
      end
    end

    # Deals with messages directed to agents
    def agentmsg(request)
      Log.debug("Handling message for agent '#{request.agent}' on collective '#{request.collective}'")

      @agents.dispatch(request, @connection) do |reply_message|
        reply(reply_message, request) if reply_message
      end
    end

    # Receive a message from the connection handler
    def receive
      request = @connection.receive
      request.type = :request

      @stats.received

      request.decode!
      request.validate

      request
    end

    # Sends a reply to a specific target topic
    def reply(msg, request)
      msg = Message.new(msg, nil, :request => request)
      msg.encode!
      msg.publish

      @stats.sent
    end

    # Waits for all agent threads to complete
    # If soft_shutdown_timeout has been defined it will wait for the
    # configured grace period before killing all the threads
    def soft_shutdown
      timeout = @config.soft_shutdown_timeout

      if timeout && timeout <= 0
        Log.warn("soft_shutdown_timeout has been set to '#{timeout}'. soft_shutdown_timeout must be > 0")
        Log.warn("Shutting down normally.")
        return
      end

      if Util.windows?
        windows_soft_shutdown(timeout)
        return
      end

      posix_soft_shutdown(timeout)
    end

    # Implements soft shutdown on the Windows platform
    # Logs and returns without doing anything if a timeout
    # hasn't been specified since waiting for long running threads
    # to exit on Windows can put the MCollective service in a broken state
    def windows_soft_shutdown(timeout)
      if !timeout
        Log.warn("soft_shutdown specified but not soft_shutdown_timeout specified.")
        Log.warn("To enable soft_shutdown on windows a soft_shutdown_timeout must be specified.")
        Log.warn("Shutting down normally.")
        return
      end

      shutdown_with_timeout(timeout)
    end

    # Implements soft shutdown on posix systems
    def posix_soft_shutdown(timeout)
      if timeout
        shutdown_with_timeout(timeout)
        return
      end

      stop_agent_threads
    end

    def shutdown_with_timeout(timeout)
      Log.debug("Shutting down agents with a timeout of '#{timeout}' seconds")
      begin
        Timeout.timeout(timeout) do
          stop_agent_threads
        end
      rescue Timeout::Error
        Log.warn("soft_shutdown_timeout reached. Terminating all running agent threads.")
      end
    end

    def stop_agent_threads
      Log.debug("Waiting for all running agents to finish or timeout.")
      @agent_threads.each do |t|
        if t.alive?
          t.join
        end
      end
      Log.debug("All running agents have completed. Stopping.")
    end
  end
end
