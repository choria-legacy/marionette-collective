module MCollective
  # The main runner for the daemon, supports running in the foreground
  # and the background, keeps detailed stats and provides hooks to access
  # all this information
  class Runner
    def initialize(configfile)
      begin
        @config = Config.instance
        @config.loadconfig(configfile) unless @config.configured
        @config.mode = :server
        @state = :running
        @stats = PluginManager["global_stats"]

        @security = PluginManager["security_plugin"]
        @security.initiated_by = :node

        @connection = PluginManager["connector_plugin"]
        @connection.connect

        @agents = Agents.new

        unless Util.windows?
          Signal.trap("USR1") do
            Log.info("Reloading all agents after receiving USR1 signal")
            @agents.loadagents
          end

          Signal.trap("USR2") do
            Log.info("Cycling logging level due to USR2 signal")
            Log.cycle_level
          end
        else
          Util.setup_windows_sleeper
        end
      rescue => e
        Log.error("Failed to start MCollective runner.")
        Log.error(e)
        Log.error(e.backtrace.join("\n\t"))
        raise e
      end
    end

    # Starts the main loop, before calling this you should initialize the MCollective::Config singleton.
    def run
      Data.load_data_sources

      Util.subscribe(Util.make_subscriptions("mcollective", :broadcast))
      Util.subscribe(Util.make_subscriptions("mcollective", :directed)) if @config.direct_addressing

      # Start the registration plugin if interval isn't 0
      begin
        PluginManager["registration_plugin"].run(@connection) unless @config.registerinterval == 0
      rescue Exception => e
        Log.error("Failed to start registration plugin: #{e}")
      end

      loop do
        begin
          request = receive

          unless request.agent == "mcollective"
            agentmsg(request)
          else
            Log.error("Received a control message, possibly via 'mco controller' but this has been deprecated")
          end
        rescue SignalException => e
          Log.warn("Exiting after signal: #{e}")
          @connection.disconnect
          raise

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

        return if @state == :stopping
      end
    end

    # Flag the runner to stop
    def stop
      @state = :stopping
    end

    private
    # Deals with messages directed to agents
    def agentmsg(request)
      Log.debug("Handling message for agent '#{request.agent}' on collective '#{request.collective}'")

      @agents.dispatch(request, @connection) do |reply_message|
        reply(reply_message, request) if reply_message
      end
    end

    # Deals with messages sent to our control topic
    def controlmsg(request)
      Log.debug("Handling message for mcollectived controller")

      begin
        case request.payload[:body]
        when /^stats$/
          reply(@stats.to_hash, request)

        when /^reload_agent (.+)$/
          reply("reloaded #{$1} agent", request) if @agents.loadagent($1)

        when /^reload_agents$/

          reply("reloaded all agents", request) if @agents.loadagents

        else
          Log.error("Received an unknown message to the controller")

        end
      rescue Exception => e
        Log.error("Failed to handle control message: #{e}")
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
  end
end

