module MCollective
  # The main runner for the daemon, supports running in the foreground
  # and the background, keeps detailed stats and provides hooks to access
  # all this information
  class Runner
    include Translatable

    def initialize(configfile)
      @config = Config.instance
      @config.loadconfig(configfile) unless @config.configured
      @config.mode = :server

      @stats = PluginManager["global_stats"]

      @security = PluginManager["security_plugin"]
      @security.initiated_by = :node

      @connection = PluginManager["connector_plugin"]
      @connection.connect

      @agents = Agents.new

      unless Util.windows?
        Signal.trap("USR1") do
          log_code(:PLMC2, "Reloading all agents after receiving USR1 signal", :info)
          @agents.loadagents
        end

        Signal.trap("USR2") do
          log_code(:PLMC3, "Cycling logging level due to USR2 signal", :info)

          Log.cycle_level
        end
      else
        Util.setup_windows_sleeper
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
        logexception(:PLMC4, "Failed to start registration plugin: %{error}", :error, e)
      end

      loop do
        begin
          request = receive

          unless request.agent == "mcollective"
            agentmsg(request)
          else
            log_code(:PLMC5, "Received a control message, possibly via 'mco controller' but this has been deprecated", :error)
          end
        rescue SignalException => e
          logexception(:PLMC7, "Exiting after signal: %{error}", :warn, e)
          @connection.disconnect
          raise

        rescue MsgTTLExpired => e
          logexception(:PLMC9, "Expired Message: %{error}", :warn, e)

        rescue NotTargettedAtUs => e
          log_code(:PLMC6, "Message does not pass filters, ignoring", :debug)

        rescue Exception => e
          logexception(:PLMC10, "Failed to handle message: %{error}", :warn, e, true)
        end
      end
    end

    private
    # Deals with messages directed to agents
    def agentmsg(request)
      log_code(:PLMC8, "Handling message for agent '%{agent}' on collective '%{collective} with requestid '%{requestid}'", :debug, :agent => request.agent, :collective => request.collective, :requestid => request.requestid)

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

