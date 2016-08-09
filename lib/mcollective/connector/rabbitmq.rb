require 'stomp'

module MCollective
  module Connector
    class Rabbitmq<Base
      attr_reader :connection

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
        @base64 = false
        @use_exponential_back_off = get_bool_option("rabbitmq.use_exponential_back_off", "true")
        @initial_reconnect_delay = Float(get_option("rabbitmq.initial_reconnect_delay", 0.01))
        @back_off_multiplier = Integer(get_option("rabbitmq.back_off_multiplier", 2))
        @max_reconnect_delay = Float(get_option("rabbitmq.max_reconnect_delay", 30.0))
        @reconnect_delay = @initial_reconnect_delay

        Log.info("RabbitMQ connector initialized.  Using stomp-gem #{stomp_version}")
      end

      # Connects to the RabbitMQ middleware
      def connect(connector = ::Stomp::Connection)
        if @connection
          Log.debug("Already connection, not re-initializing connection")
          return
        end

        begin
          @base64 = get_bool_option("rabbitmq.base64", "false")

          pools = Integer(get_option("rabbitmq.pool.size"))
          hosts = []
          middleware_user = ''
          middleware_password = ''
          prompt_for_username = get_bool_option("rabbitmq.prompt_user", "false")
          prompt_for_password = get_bool_option("rabbitmq.prompt_password", "false")
          if prompt_for_username
            Log.debug("No previous user exists and rabbitmq.prompt-user is set to true")
            print "Please enter user to connect to middleware: "
            middleware_user = STDIN.gets.chomp
          end

          if prompt_for_password
            Log.debug("No previous password exists and rabbitmq.prompt-password is set to true")
            middleware_password = MCollective::Util.get_hidden_input("Please enter password: ")
            print "\n"
          end
          
          1.upto(pools) do |poolnum|
            host = {}

            host[:host] = get_option("rabbitmq.pool.#{poolnum}.host")
            host[:port] = get_option("rabbitmq.pool.#{poolnum}.port", 61613).to_i
            host[:ssl] = get_bool_option("rabbitmq.pool.#{poolnum}.ssl", "false")
            
            # read user from config file
            host[:login] = get_env_or_option("STOMP_USER", "rabbitmq.pool.#{poolnum}.user", middleware_user)
            if prompt_for_username and host[:login] != middleware_user
              Log.info("Using #{host[:login]} from config file to connect to #{host[:host]}. "+
                        "plugin.rabbitmq.prompt_user should be set to false to remove the prompt.")
            end
            
            # read password from config file
            host[:passcode] = get_env_or_option("STOMP_PASSWORD", "rabbitmq.pool.#{poolnum}.password", middleware_password)
            if prompt_for_password and host[:passcode] != middleware_password
                Log.info("Using password from config file to connect to #{host[:host]}. "+
                        "plugin.rabbitmq.prompt_password should be set to false to remove the prompt.")
            end
           
            # if ssl is enabled set :ssl to the hash of parameters
            if host[:ssl]
              host[:ssl] = ssl_parameters(poolnum, get_bool_option("rabbitmq.pool.#{poolnum}.ssl.fallback", "false"))
            end

            Log.debug("Adding #{host[:host]}:#{host[:port]} to the connection pool")
            hosts << host
          end

          raise "No hosts found for the RabbitMQ connection pool" if hosts.size == 0

          connection = {:hosts => hosts}

          # Various STOMP gem options, defaults here matches defaults for 1.1.6 the meaning of
          # these can be guessed, the documentation isn't clear
          connection[:use_exponential_back_off] = @use_exponential_back_off
          connection[:initial_reconnect_delay] = @initial_reconnect_delay
          connection[:back_off_multiplier] = @back_off_multiplier
          connection[:max_reconnect_delay] = @max_reconnect_delay
          connection[:max_reconnect_attempts] = Integer(get_option("rabbitmq.max_reconnect_attempts", 0))
          connection[:randomize] = get_bool_option("rabbitmq.randomize", "false")
          connection[:backup] = get_bool_option("rabbitmq.backup", "false")

          connection[:timeout] = Integer(get_option("rabbitmq.timeout", -1))
          connection[:connect_timeout] = Integer(get_option("rabbitmq.connect_timeout", 30))
          connection[:reliable] = true
          connection[:max_hbrlck_fails] = Integer(get_option("rabbitmq.max_hbrlck_fails", 0))
          connection[:max_hbread_fails] = Integer(get_option("rabbitmq.max_hbread_fails", 2))

          connection[:connect_headers] = connection_headers

          connection[:logger] = EventLogger.new

          @connection = connector.new(connection)

        rescue ClientTimeoutError => e
          raise e
        rescue Exception => e
          raise("Could not connect to RabbitMQ Server: #{e}")
        end
      end

      def connection_headers
        headers = {:"accept-version" => "1.0"}

        heartbeat_interval = Integer(get_option("rabbitmq.heartbeat_interval", 0))
        stomp_1_0_fallback = get_bool_option("rabbitmq.stomp_1_0_fallback", true)

        headers[:host] = get_option("rabbitmq.vhost", "/")

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
            Log.info("Connecting without STOMP 1.1 heartbeats, consider setting plugin.rabbitmq.heartbeat_interval")
          end
        end

        headers
      end

      def stomp_version
        ::Stomp::Version::STRING
      end

      def stomp_version_supports_heartbeat?
        return Util.versioncmp(stomp_version, "1.2.10") >= 0
      end

      # Sets the SSL paramaters for a specific connection
      def ssl_parameters(poolnum, fallback)
        params = {
          :cert_file => get_cert_file(poolnum),
          :key_file  => get_key_file(poolnum),
          :ts_files  => get_option("rabbitmq.pool.#{poolnum}.ssl.ca", false),
          :ciphers   => get_option("rabbitmq.pool.#{poolnum}.ssl.ciphers", false),
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

      # Returns the name of the private key file used by RabbitMQ
      # Will first check if an environment variable MCOLLECTIVE_RABBITMQ_POOLX_SSL_KEY exists,
      # where X is the RabbitMQ pool number.
      # If the environment variable doesn't exist, it will try and load the value from the config.
      def get_key_file(poolnum)
        ENV["MCOLLECTIVE_RABBITMQ_POOL%s_SSL_KEY" % poolnum] || get_option("rabbitmq.pool.#{poolnum}.ssl.key", false)
      end

      # Returns the name of the certificate file used by RabbitMQ
      # Will first check if an environment variable MCOLLECTIVE_RABBITMQ_POOLX_SSL_CERT exists,
      # where X is the RabbitMQ pool number.
      # If the environment variable doesn't exist, it will try and load the value from the config.
      def get_cert_file(poolnum)
        ENV["MCOLLECTIVE_RABBITMQ_POOL%s_SSL_CERT" % poolnum] || get_option("rabbitmq.pool.#{poolnum}.ssl.cert", false)
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

      # Receives a message from the RabbitMQ connection
      def receive
        Log.debug("Waiting for a message from RabbitMQ")

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
          raise MessageNotReceived.new(exponential_back_off), "No message received from RabbitMQ."
        end

        raise "Received a processing error from RabbitMQ: '%s'" % msg.body.chomp if msg.body =~ /Processing error/

        # We expect all messages we get to be of STOMP frame type MESSAGE, raise on unexpected types
        if msg.command != 'MESSAGE'
          Log.debug("Unexpected '#{msg.command}' frame.  Headers: #{msg.headers.inspect} Body: #{msg.body.inspect}")
          raise UnexpectedMessageType.new(exponential_back_off),
            "Received frame of type '#{msg.command}' expected 'MESSAGE'"
        end

        Message.new(msg.body, msg, :base64 => @base64, :headers => msg.headers)
      end

      # Sends a message to the RabbitMQ connection
      def publish(msg)
        msg.base64_encode! if @base64

        if msg.type == :direct_request
          msg.discovered_hosts.each do |node|
            target = target_for(msg, node)

            Log.debug("Sending a direct message to RabbitMQ target '#{target[:name]}' with headers '#{target[:headers].inspect}'")

            @connection.publish(target[:name], msg.payload, target[:headers])
          end
        else
          target = target_for(msg)

          Log.debug("Sending a broadcast message to RabbitMQ target '#{target[:name]}' with headers '#{target[:headers].inspect}'")

          @connection.publish(target[:name], msg.payload, target[:headers])
        end
      end

      def target_for(msg, node=nil)
        if msg.type == :reply
          target = {:name => msg.request.headers["reply-to"], :headers => {}, :id => ""}

        elsif [:request, :direct_request].include?(msg.type)
          target = make_target(msg.agent, msg.type, msg.collective, msg.reply_to, node)

        else
          raise "Don't now how to create a target for message type #{msg.type}"

        end

        # marks messages as valid for ttl + 10 seconds, we do this here
        # rather than in make_target as this should only be set on publish
        target[:headers]["expiration"] = ((msg.ttl + 10) * 1000).to_s

        target[:headers]["mc_sender"] = Config.instance.identity

        return target
      end

      def make_target(agent, type, collective, reply_to=nil, node=nil)
        raise("Unknown target type #{type}") unless [:directed, :broadcast, :reply, :request, :direct_request].include?(type)
        raise("Unknown collective '#{collective}' known collectives are '#{@config.collectives.join ', '}'") unless @config.collectives.include?(collective)

        target = {:name => "", :headers => {}, :id => nil}

        if reply_to
          reply_path = reply_to
        elsif get_bool_option("rabbitmq.use_reply_exchange", false)
          reply_path = "/exchange/mcollective_reply/%s_%s_%s" % [ @config.identity, $$, Client.request_sequence ]
        else
          reply_path = "/temp-queue/mcollective_reply_%s" % agent
        end
        case type
          when :reply # receiving replies on a temp queue
            target[:name] = reply_path
            target[:id] = "mcollective_%s_replies" % agent

          when :broadcast, :request # publishing a request to all nodes with an agent
            target[:name] = "/exchange/%s_broadcast/%s" % [collective, agent]
            if reply_to
              target[:headers]["reply-to"] = reply_to
            else
              target[:headers]["reply-to"] = reply_path
            end
            target[:id] = "%s_broadcast_%s" % [collective, agent]

          when :direct_request # a request to a specific node
            raise "Directed requests need to have a node identity" unless node

            target[:name] = "/exchange/%s_directed/%s" % [ collective, node]
            target[:headers]["reply-to"] = reply_path

          when :directed # subscribing to directed messages
            target[:name] = "/exchange/%s_directed/%s" % [ collective, @config.identity ]
            target[:id] = "%s_%s_directed_to_identity" % [ collective, @config.identity ]
        end

        target
      end

      # Subscribe to a topic or queue
      def subscribe(agent, type, collective)
        if type == :reply
          # On rabbitmq if you send a message with a reply-to: header set to
          # '/temp-queue/*' it automatically creates a private queue, munges
          # the reply-to: header to point to this private queue, and
          # subscribes you to it.  As such you should never attempt to
          # SUBSCRIBE or UNSUBSCRIBE to '/temp-queue/*' directly as that'll
          # cause great pain and suffering.
          # https://www.rabbitmq.com/stomp.html#d.tqd

          # The exception to this is in 'use_reply_exchange' mode, when the
          # reply-to will be set to a queue in an explicit exchange.
          if !get_bool_option("rabbitmq.use_reply_exchange", false)
            # We aren't in 'use_reply_exchange' mode, don't subscribe.
            return
          end
        end

        source = make_target(agent, type, collective)

        unless @subscriptions.include?(source[:id])
          Log.debug("Subscribing to #{source[:name]} with headers #{source[:headers].inspect.chomp}")
          @connection.subscribe(source[:name], source[:headers], source[:id])
          @subscriptions << source[:id]
        end
      rescue ::Stomp::Error::DuplicateSubscription
        Log.error("Received subscription request for #{source.inspect.chomp} but already had a matching subscription, ignoring")
      end

      # Subscribe to a topic or queue
      def unsubscribe(agent, type, collective)
        if type == :reply
          # For a more detailed discussion of this logic, please see #subscribe
          if !get_bool_option("rabbitmq.use_reply_exchange", false)
            # We shouldn't try to unsubscribe from a '/temp-queue/*' queue.
            return
          end
        end

        source = make_target(agent, type, collective)

        Log.debug("Unsubscribing from #{source[:name]}")
        @connection.unsubscribe(source[:name], source[:headers], source[:id])
        @subscriptions.delete(source[:id])
      end

      # Disconnects from the RabbitMQ connection
      def disconnect
        Log.debug("Disconnecting from RabbitMQ")
        @connection.disconnect
        @connection = nil
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
