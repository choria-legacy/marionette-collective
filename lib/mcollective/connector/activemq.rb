require 'stomp'

module MCollective
  module Connector
    # Handles sending and receiving messages over the Stomp protocol for ActiveMQ
    # servers specifically, we take advantages of ActiveMQ specific features and
    # enhancements to the Stomp protocol.  For best results in a clustered environment
    # use ActiveMQ 5.5.0 at least.
    #
    # This plugin takes an entirely different approach to dealing with ActiveMQ
    # from the more generic stomp connector.
    #
    #  - Agents use /topic/<collective>.<agent>.agent
    #  - Replies use temp-topics so they are private and transient.
    #  - Point to Point messages using topics are supported by subscribing to
    #    /queue/<collective>.nodes with a selector "mc_identity = 'identity'
    #
    # The use of temp-topics for the replies is a huge improvement over the old style.
    # In the old way all clients got replies for all clients that were active at that
    # time, this would mean that they would need to decrypt, validate etc in order to
    # determine if they need to ignore the message, this was computationally expensive
    # and on large busy networks the messages were being sent all over the show cross
    # broker boundaries.
    #
    # The new way means the messages go point2point back to only whoever requested the
    # message, they only get their own replies and this is ap private channel that
    # casual observers cannot just snoop into.
    #
    # This plugin supports 1.1.6 and newer of the Stomp rubygem.
    #
    #    connector = activemq
    #    plugin.activemq.pool.size = 2
    #
    #    plugin.activemq.pool.1.host = stomp1.your.net
    #    plugin.activemq.pool.1.port = 61613
    #    plugin.activemq.pool.1.user = you
    #    plugin.activemq.pool.1.password = secret
    #    plugin.activemq.pool.1.ssl = true
    #    plugin.activemq.pool.1.ssl.cert = /path/to/your.cert
    #    plugin.activemq.pool.1.ssl.key = /path/to/your.key
    #    plugin.activemq.pool.1.ssl.ca = /path/to/your.ca
    #    plugin.activemq.pool.1.ssl.fallback = true
    #    plugin.activemq.pool.1.ssl.ciphers = TLSv1:!MD5:!LOW:!EXPORT
    #
    #    plugin.activemq.pool.2.host = stomp2.your.net
    #    plugin.activemq.pool.2.port = 61613
    #    plugin.activemq.pool.2.user = you
    #    plugin.activemq.pool.2.password = secret
    #    plugin.activemq.pool.2.ssl = false
    #
    # Using this method you can supply just STOMP_USER and STOMP_PASSWORD.  The port will
    # default to 61613 if not specified.
    #
    # The ssl options are only usable in version of the Stomp gem newer than 1.2.2 where these
    # will imply full SSL validation will be done and you'll only be able to connect to a
    # ActiveMQ server that has a cert signed by the same CA.  If you only set ssl = true
    # and do not supply the cert, key and ca properties or if you have an older gem it
    # will fall back to unverified mode only if ssl.fallback is true
    #
    # In addition you can set the following options for the rubygem:
    #
    #     plugin.activemq.initial_reconnect_delay = 0.01
    #     plugin.activemq.max_reconnect_delay = 30.0
    #     plugin.activemq.use_exponential_back_off = true
    #     plugin.activemq.back_off_multiplier = 2
    #     plugin.activemq.max_reconnect_attempts = 0
    #     plugin.activemq.randomize = false
    #     plugin.activemq.timeout = -1
    #
    # You can set the initial connetion timeout - this is when your stomp server is simply
    # unreachable - after which it would failover to the next in the pool:
    #
    #     plugin.activemq.connect_timeout = 30
    #
    # ActiveMQ JMS message priorities can be set:
    #
    #     plugin.activemq.priority = 4
    #
    # This plugin supports Stomp protocol 1.1 when combined with the stomp gem version
    # 1.2.10 or newer.  To enable network heartbeats which will help keep the connection
    # alive over NAT connections and aggresive session tracking firewalls you can set:
    #
    #     plugin.activemq.heartbeat_interval = 30
    #
    # which will cause a heartbeat to be sent on 30 second intervals and one to be expected
    # from the broker every 30 seconds.  The shortest supported period is 30 seconds, if
    # you set it lower it will get forced to 30 seconds.
    #
    # After 2 failures to receive a heartbeat the connection will be reset via the normal
    # failover mechanism.
    #
    # By default if heartbeat_interval is set it will request Stomp 1.1 but support fallback
    # to 1.0, but you can enable strict Stomp 1.1 only operation
    #
    #     plugin.activemq.stomp_1_0_fallback = 0
    class Activemq<Base
      attr_reader :connection

      # Older stomp gems do not have these error classes, in order to be able to
      # handle these exceptions if they are present and still support older gems
      # we're assigning the constants to a dummy exception that will never be thrown
      # by us.  End result is that the code catching these exceptions become noops on
      # older gems but on newer ones they become usable and handle those new errors
      # intelligently
      class DummyError<RuntimeError; end

      ::Stomp::Error = DummyError unless defined?(::Stomp::Error)
      ::Stomp::Error::NoCurrentConnection = DummyError unless defined?(::Stomp::Error::NoCurrentConnection)
      ::Stomp::Error::DuplicateSubscription = DummyError unless defined?(::Stomp::Error::DuplicateSubscription)

      # Class for Stomp 1.1.9 callback based logging
      class EventLogger
        def on_connecting(params=nil)
          Log.info("TCP Connection attempt %d to %s" % [params[:cur_conattempts], stomp_url(params)])
        rescue
        end

        def on_connected(params=nil)
          Log.info("Connected to #{stomp_url(params)}")
        rescue
        end

        def on_disconnect(params=nil)
          Log.info("Disconnected from #{stomp_url(params)}")
        rescue
        end

        def on_connectfail(params=nil)
          Log.info("TCP Connection to #{stomp_url(params)} failed on attempt #{params[:cur_conattempts]}")
        rescue
        end

        def on_miscerr(params, errstr)
          Log.error("Unexpected error on connection #{stomp_url(params)}: #{errstr}")
        rescue
        end

        def on_ssl_connecting(params)
          Log.info("Establishing SSL session with #{stomp_url(params)}")
        rescue
        end

        def on_ssl_connected(params)
          Log.info("SSL session established with #{stomp_url(params)}")
        rescue
        end

        def on_ssl_connectfail(params)
          Log.error("SSL session creation with #{stomp_url(params)} failed: #{params[:ssl_exception]}")
        end

        # Stomp 1.1+ - heart beat read (receive) failed.
        def on_hbread_fail(params, ticker_data)
          if ticker_data["lock_fail"]
            if params[:max_hbrlck_fails] == 0
              # failure is disabled
              Log.debug("Heartbeat failed to acquire readlock for '%s': %s" % [stomp_url(params), ticker_data.inspect])
            elsif ticker_data['lock_fail_count'] >= params[:max_hbrlck_fails]
              # we're about to force a disconnect
              Log.error("Heartbeat failed to acquire readlock for '%s': %s" % [stomp_url(params), ticker_data.inspect])
            else
              Log.warn("Heartbeat failed to acquire readlock for '%s': %s" % [stomp_url(params), ticker_data.inspect])
            end
          else
            if params[:max_hbread_fails] == 0
              # failure is disabled
              Log.debug("Heartbeat read failed from '%s': %s" % [stomp_url(params), ticker_data.inspect])
            elsif ticker_data['read_fail_count'] >= params[:max_hbread_fails]
              # we're about to force a reconnect
              Log.error("Heartbeat read failed from '%s': %s" % [stomp_url(params), ticker_data.inspect])
            else
              Log.warn("Heartbeat read failed from '%s': %s" % [stomp_url(params), ticker_data.inspect])
            end
          end
        rescue Exception => e
        end

        # Stomp 1.1+ - heart beat send (transmit) failed.
        def on_hbwrite_fail(params, ticker_data)
          Log.error("Heartbeat write failed from '%s': %s" % [stomp_url(params), ticker_data.inspect])
        rescue Exception => e
        end

        # Log heart beat fires
        def on_hbfire(params, srind, curt)
          case srind
            when "receive_fire"
              Log.debug("Received heartbeat from %s: %s, %s" % [stomp_url(params), srind, curt])
            when "send_fire"
              Log.debug("Publishing heartbeat to %s: %s, %s" % [stomp_url(params), srind, curt])
          end
        rescue Exception => e
        end

        def stomp_url(params)
          "%s://%s@%s:%d" % [ params[:cur_ssl] ? "stomp+ssl" : "stomp", params[:cur_login], params[:cur_host], params[:cur_port]]
        end
      end

      def initialize
        @config = Config.instance
        @subscriptions = []
        @msgpriority = 0
        @base64 = false
        @use_exponential_back_off = get_bool_option("activemq.use_exponential_back_off", "true")
        @initial_reconnect_delay = Float(get_option("activemq.initial_reconnect_delay", 0.01))
        @back_off_multiplier = Integer(get_option("activemq.back_off_multiplier", 2))
        @max_reconnect_delay = Float(get_option("activemq.max_reconnect_delay", 30.0))
        @reconnect_delay = @initial_reconnect_delay

        Log.info("ActiveMQ connector initialized.  Using stomp-gem #{stomp_version}")
      end

      # Connects to the ActiveMQ middleware
      def connect(connector = ::Stomp::Connection)
        if @connection
          Log.debug("Already connection, not re-initializing connection")
          return
        end

        begin
          @base64 = get_bool_option("activemq.base64", "false")
          @msgpriority = get_option("activemq.priority", 0).to_i

          pools = Integer(get_option("activemq.pool.size"))
          hosts = []
          middleware_user = ''
          middleware_password = ''
          prompt_for_username = get_bool_option("activemq.prompt_user", "false")
          prompt_for_password = get_bool_option("activemq.prompt_password", "false")
          
          if prompt_for_username
            Log.debug("No previous user exists and activemq.prompt-user is set to true")
            print "Please enter user to connect to middleware: "
            middleware_user = STDIN.gets.chomp
          end

          if prompt_for_password
            Log.debug("No previous password exists and activemq.prompt-password is set to true")
            middleware_password = MCollective::Util.get_hidden_input("Please enter password: ")
            print "\n"
          end

          1.upto(pools) do |poolnum|
            host = {}

            host[:host] = get_option("activemq.pool.#{poolnum}.host")
            host[:port] = get_option("activemq.pool.#{poolnum}.port", 61613).to_i
            host[:ssl] = get_bool_option("activemq.pool.#{poolnum}.ssl", "false")
            
            # read user from config file
            host[:login] = get_env_or_option("STOMP_USER", "activemq.pool.#{poolnum}.user", middleware_user)
            if prompt_for_username and host[:login] != middleware_user
                Log.info("Using #{host[:login]} from config file to connect to #{host[:host]}. "+
                        "plugin.activemq.prompt_user should be set to false to remove the prompt.")
            end
            
            # read user from config file
            host[:passcode] = get_env_or_option("STOMP_PASSWORD", "activemq.pool.#{poolnum}.password", middleware_password)
            if prompt_for_password and host[:passcode] != middleware_password
                Log.info("Using password from config file to connect to #{host[:host]}. "+
                        "plugin.activemq.prompt_password should be set to false to remove the prompt.")
            end

            # if ssl is enabled set :ssl to the hash of parameters
            if host[:ssl]
              host[:ssl] = ssl_parameters(poolnum, get_bool_option("activemq.pool.#{poolnum}.ssl.fallback", "false"))
            end

            Log.debug("Adding #{host[:host]}:#{host[:port]} to the connection pool")
            hosts << host
          end

          raise "No hosts found for the ActiveMQ connection pool" if hosts.size == 0

          connection = {:hosts => hosts}

          # Various STOMP gem options, defaults here matches defaults for 1.1.6 the meaning of
          # these can be guessed, the documentation isn't clear
          connection[:use_exponential_back_off] = @use_exponential_back_off
          connection[:initial_reconnect_delay] = @initial_reconnect_delay
          connection[:back_off_multiplier] = @back_off_multiplier
          connection[:max_reconnect_delay] = @max_reconnect_delay
          connection[:max_reconnect_attempts] = Integer(get_option("activemq.max_reconnect_attempts", 0))
          connection[:randomize] = get_bool_option("activemq.randomize", "false")
          connection[:backup] = get_bool_option("activemq.backup", "false")
          connection[:timeout] = Integer(get_option("activemq.timeout", -1))
          connection[:connect_timeout] = Integer(get_option("activemq.connect_timeout", 30))
          connection[:reliable] = true
          connection[:connect_headers] = connection_headers
          connection[:max_hbrlck_fails] = Integer(get_option("activemq.max_hbrlck_fails", 0))
          connection[:max_hbread_fails] = Integer(get_option("activemq.max_hbread_fails", 2))

          connection[:logger] = EventLogger.new

          @connection = connector.new(connection)

        rescue ClientTimeoutError => e
          raise e
        rescue Exception => e
          raise("Could not connect to ActiveMQ Server: #{e}")
        end
      end

      def stomp_version
        ::Stomp::Version::STRING
      end

      def stomp_version_supports_heartbeat?
        return Util.versioncmp(stomp_version, "1.2.10") >= 0
      end

      def connection_headers
        headers = {:"accept-version" => "1.0"}

        heartbeat_interval = Integer(get_option("activemq.heartbeat_interval", 0))
        stomp_1_0_fallback = get_bool_option("activemq.stomp_1_0_fallback", true)

        headers[:host] = get_option("activemq.vhost", "mcollective")

        if heartbeat_interval > 0
          unless stomp_version_supports_heartbeat?
            raise("Setting STOMP 1.1 properties like heartbeat intervals require at least version 1.2.10 of the STOMP gem")
          end

          if heartbeat_interval < 30
            Log.warn("Connection heartbeat is set to %d, forcing to minimum value of 30s")
            heartbeat_interval = 30
          end

          heartbeat_interval = heartbeat_interval * 1000
          headers[:"heart-beat"] = "%d,%d" % [heartbeat_interval + 500, heartbeat_interval - 500]

          if stomp_1_0_fallback
            headers[:"accept-version"] = "1.1,1.0"
          else
            headers[:"accept-version"] = "1.1"
          end
        else
          if stomp_version_supports_heartbeat?
            Log.info("Connecting without STOMP 1.1 heartbeats, if you are using ActiveMQ 5.8 or newer consider setting plugin.activemq.heartbeat_interval")
          end
        end

        headers
      end

      # Sets the SSL paramaters for a specific connection
      def ssl_parameters(poolnum, fallback)
        params = {
          :cert_file => get_cert_file(poolnum),
          :key_file  => get_key_file(poolnum),
          :ts_files  => get_option("activemq.pool.#{poolnum}.ssl.ca", false),
          :ciphers   => get_option("activemq.pool.#{poolnum}.ssl.ciphers", false),
        }

        raise "cert, key and ca has to be supplied for verified SSL mode" unless params[:cert_file] && params[:key_file] && params[:ts_files]

        raise "Cannot find certificate file #{params[:cert_file]}" unless File.exist?(params[:cert_file])
        raise "Cannot find key file #{params[:key_file]}" unless File.exist?(params[:key_file])

        params[:ts_files].split(",").each do |ca|
          raise "Cannot find CA file #{ca}" unless File.exist?(ca)
        end

        begin
          ::Stomp::SSLParams.new(params)
        rescue NameError
          raise "Stomp gem >= 1.2.2 is needed"
        end

      rescue Exception => e
        if fallback
          Log.warn("Failed to set full SSL verified mode, falling back to unverified: #{e.class}: #{e}")
          return true
        else
          Log.error("Failed to set full SSL verified mode: #{e.class}: #{e}")
          raise(e)
        end
      end

      # Returns the name of the private key file used by ActiveMQ
      # Will first check if an environment variable MCOLLECTIVE_ACTIVEMQ_POOLX_SSL_KEY exists,
      # where X is the ActiveMQ pool number.
      # If the environment variable doesn't exist, it will try and load the value from the config.
      def get_key_file(poolnum)
        ENV["MCOLLECTIVE_ACTIVEMQ_POOL%s_SSL_KEY" % poolnum] || get_option("activemq.pool.#{poolnum}.ssl.key", false)
      end

      # Returns the name of the certficate file used by ActiveMQ
      # Will first check if an environment variable MCOLLECTIVE_ACTIVEMQ_POOLX_SSL_CERT exists,
      # where X is the ActiveMQ pool number.
      # If the environment variable doesn't exist, it will try and load the value from the config.
      def get_cert_file(poolnum)
        ENV["MCOLLECTIVE_ACTIVEMQ_POOL%s_SSL_CERT" % poolnum] || get_option("activemq.pool.#{poolnum}.ssl.cert", false)
      end

      # Calculate the exponential backoff needed
      def exponential_back_off
        if !@use_exponential_back_off
          return nil
        end

        backoff = @reconnect_delay

        # calculate next delay
        @reconnect_delay = @reconnect_delay * @back_off_multiplier

        # cap at max reconnect delay
        if @reconnect_delay > @max_reconnect_delay
          @reconnect_delay = @max_reconnect_delay
        end

        return backoff
      end

      # Receives a message from the ActiveMQ connection
      def receive
        Log.debug("Waiting for a message from ActiveMQ")

        # When the Stomp library > 1.2.0 is mid reconnecting due to its reliable connection
        # handling it sets the connection to closed.  If we happen to be receiving at just
        # that time we will get an exception warning about the closed connection so handling
        # that here with a sleep and a retry.
        begin
          msg = @connection.receive
        rescue ::Stomp::Error::NoCurrentConnection
          sleep 1
          retry
        end

        # In older stomp gems an attempt to receive after failed authentication can return nil
        if msg.nil?
          raise MessageNotReceived.new(exponential_back_off), "No message received from ActiveMQ."

        end

        # We expect all messages we get to be of STOMP frame type MESSAGE, raise on unexpected types
        if msg.command != 'MESSAGE'
          Log.debug("Unexpected '#{msg.command}' frame.  Headers: #{msg.headers.inspect} Body: #{msg.body.inspect}")
          raise UnexpectedMessageType.new(exponential_back_off),
            "Received frame of type '#{msg.command}' expected 'MESSAGE'"
        end

        Message.new(msg.body, msg, :base64 => @base64, :headers => msg.headers)
      end

      # Sends a message to the ActiveMQ connection
      def publish(msg)
        msg.base64_encode! if @base64

        target = target_for(msg)

        if msg.type == :direct_request
          msg.discovered_hosts.each do |node|
            target[:headers] = headers_for(msg, node)

            Log.debug("Sending a direct message to ActiveMQ target '#{target[:name]}' with headers '#{target[:headers].inspect}'")

            @connection.publish(target[:name], msg.payload, target[:headers])
          end
        else
          target[:headers].merge!(headers_for(msg))

          Log.debug("Sending a broadcast message to ActiveMQ target '#{target[:name]}' with headers '#{target[:headers].inspect}'")

          @connection.publish(target[:name], msg.payload, target[:headers])
        end
      end

      # Subscribe to a topic or queue
      def subscribe(agent, type, collective)
        source = make_target(agent, type, collective)

        unless @subscriptions.include?(source[:id])
          Log.debug("Subscribing to #{source[:name]} with headers #{source[:headers].inspect.chomp}")
          @connection.subscribe(source[:name], source[:headers], source[:id])
          @subscriptions << source[:id]
        end
      rescue ::Stomp::Error::DuplicateSubscription
        Log.error("Received subscription request for #{source.inspect.chomp} but already had a matching subscription, ignoring")
      end

      # UnSubscribe to a topic or queue
      def unsubscribe(agent, type, collective)
        source = make_target(agent, type, collective)

        Log.debug("Unsubscribing from #{source[:name]}")
        @connection.unsubscribe(source[:name], source[:headers], source[:id])
        @subscriptions.delete(source[:id])
      end

      def target_for(msg)
        if msg.type == :reply
          target = {:name => msg.request.headers["reply-to"], :headers => {}}
        elsif [:request, :direct_request].include?(msg.type)
          target = make_target(msg.agent, msg.type, msg.collective)
        else
          raise "Don't now how to create a target for message type #{msg.type}"
        end

        return target
      end

      # Disconnects from the ActiveMQ connection
      def disconnect
        Log.debug("Disconnecting from ActiveMQ")
        @connection.disconnect
        @connection = nil
      end

      def headers_for(msg, identity=nil)
        headers = {}

        headers = {"priority" => @msgpriority} if @msgpriority > 0

        headers["timestamp"] = (Time.now.utc.to_i * 1000).to_s

        # set the expires header based on the TTL, we build a small additional
        # timeout of 10 seconds in here to allow for network latency etc
        headers["expires"] = ((Time.now.utc.to_i + msg.ttl + 10) * 1000).to_s

        if [:request, :direct_request].include?(msg.type)
          target = make_target(msg.agent, :reply, msg.collective)

          if msg.reply_to
            headers["reply-to"] = msg.reply_to
          else
            headers["reply-to"] = target[:name]
          end

          headers["mc_identity"] = identity if msg.type == :direct_request
        end

        headers["mc_sender"] = Config.instance.identity

        return headers
      end

      def make_target(agent, type, collective)
        raise("Unknown target type #{type}") unless [:directed, :broadcast, :reply, :request, :direct_request].include?(type)
        raise("Unknown collective '#{collective}' known collectives are '#{@config.collectives.join ', '}'") unless @config.collectives.include?(collective)

        target = {:name => nil, :headers => {}}

        case type
          when :reply
            target[:name] = ["/queue/" + collective, :reply, "#{Config.instance.identity}_#{$$}", Client.request_sequence].join(".")

          when :broadcast
            target[:name] = ["/topic/" + collective, agent, :agent].join(".")

          when :request
            target[:name] = ["/topic/" + collective, agent, :agent].join(".")

          when :direct_request
            target[:name] = ["/queue/" + collective, :nodes].join(".")

          when :directed
            target[:name] = ["/queue/" + collective, :nodes].join(".")
            target[:headers]["selector"] = "mc_identity = '#{@config.identity}'"
            target[:id] = "%s_directed_to_identity" % collective
        end

        target[:id] = target[:name] unless target[:id]

        target
      end

      # looks in the environment first then in the config file
      # for a specific option, accepts an optional default.
      #
      # raises an exception when it cant find a value anywhere
      def get_env_or_option(env, opt, default=nil)
        return ENV[env] if ENV.include?(env)
        return @config.pluginconf[opt] if @config.pluginconf.include?(opt)
        return default if default

        raise("No #{env} environment or plugin.#{opt} configuration option given")
      end

      # looks for a config option, accepts an optional default
      #
      # raises an exception when it cant find a value anywhere
      def get_option(opt, default=nil)
        return @config.pluginconf[opt] if @config.pluginconf.include?(opt)
        return default unless default.nil?

        raise("No plugin.#{opt} configuration option given")
      end

      # looks up a boolean value in the config
      def get_bool_option(val, default)
        Util.str_to_bool(@config.pluginconf.fetch(val, default))
      end
    end
  end
end

# vi:tabstop=4:expandtab:ai
