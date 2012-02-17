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
    #    /topic/<collective>.nodes with a selector "mc_identity = 'identity'
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
    # This plugin supports 1.1.6 and newer of the Stomp rubygem
    #
    #    connector = activemq
    #    plugin.activemq.pool.size = 2
    #
    #    plugin.activemq.pool.1.host = stomp1.your.net
    #    plugin.activemq.pool.1.port = 6163
    #    plugin.activemq.pool.1.user = you
    #    plugin.activemq.pool.1.password = secret
    #    plugin.activemq.pool.1.ssl = true
    #
    #    plugin.activemq.pool.2.host = stomp2.your.net
    #    plugin.activemq.pool.2.port = 6163
    #    plugin.activemq.pool.2.user = you
    #    plugin.activemq.pool.2.password = secret
    #    plugin.activemq.pool.2.ssl = false
    #
    # Using this method you can supply just STOMP_USER and STOMP_PASSWORD.  The port will
    # default to 61613 if not specified.
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
    # ActiveMQ JMS message priorities can be set:
    #
    #     plugin.activemq.priority = 4
    #
    class Activemq<Base
      attr_reader :connection

      # Class for Stomp 1.9.2 callback based logging
      class EventLogger
        def on_connecting(params=nil)
          Log.info("Connection attempt %d to %s" % [params[:cur_conattempts], stomp_url(params)])
        rescue
        end

        def on_connected(params=nil)
          Log.info("Conncted to #{stomp_url(params)}")
        rescue
        end

        def on_disconnect(params=nil)
          Log.info("Disconnected from #{stomp_url(params)}")
        rescue
        end

        def on_connectfail(params=nil)
          Log.info("Connction to #{stomp_url(params)} failed on attempt #{params[:cur_conattempts]}")
        rescue
        end

        def on_miscerr(params, errstr)
          Log.error("Unexpected error on connection #{stomp_url(params)}: #{errstr}")
        rescue
        end

        def stomp_url(params)
          "stomp://%s@%s:%d" % [params[:cur_login], params[:cur_host], params[:cur_port]]
        end
      end

      def initialize
        @config = Config.instance
        @subscriptions = []
        @msgpriority = 0
        @base64 = false
      end

      # Connects to the ActiveMQ middleware
      def connect(connector = ::Stomp::Connection)
        if @connection
          Log.debug("Already connection, not re-initializing connection")
          return
        end

        begin
          @base64 = get_bool_option("activemq.base64", false)
          @msgpriority = get_option("activemq.priority", 0).to_i

          pools = @config.pluginconf["activemq.pool.size"].to_i
          hosts = []

          1.upto(pools) do |poolnum|
            host = {}

            host[:host] = get_option("activemq.pool.#{poolnum}.host")
            host[:port] = get_option("activemq.pool.#{poolnum}.port", 6163).to_i
            host[:login] = get_env_or_option("STOMP_USER", "activemq.pool.#{poolnum}.user")
            host[:passcode] = get_env_or_option("STOMP_PASSWORD", "activemq.pool.#{poolnum}.password")
            host[:ssl] = get_bool_option("activemq.pool.#{poolnum}.ssl", false)

            Log.debug("Adding #{host[:host]}:#{host[:port]} to the connection pool")
            hosts << host
          end

          raise "No hosts found for the ActiveMQ connection pool" if hosts.size == 0

          connection = {:hosts => hosts}

          # Various STOMP gem options, defaults here matches defaults for 1.1.6 the meaning of
          # these can be guessed, the documentation isn't clear
          connection[:initial_reconnect_delay] = get_option("activemq.initial_reconnect_delay", 0.01).to_f
          connection[:max_reconnect_delay] = get_option("activemq.max_reconnect_delay", 30.0).to_f
          connection[:use_exponential_back_off] = get_bool_option("activemq.use_exponential_back_off", true)
          connection[:back_off_multiplier] = get_bool_option("activemq.back_off_multiplier", 2).to_i
          connection[:max_reconnect_attempts] = get_option("activemq.max_reconnect_attempts", 0).to_i
          connection[:randomize] = get_bool_option("activemq.randomize", false)
          connection[:backup] = get_bool_option("activemq.backup", false)
          connection[:timeout] = get_option("activemq.timeout", -1).to_i
          connection[:logger] = EventLogger.new

          @connection = connector.new(connection)
        rescue Exception => e
          raise("Could not connect to ActiveMQ Server: #{e}")
        end
      end

      # Receives a message from the ActiveMQ connection
      def receive
        Log.debug("Waiting for a message from ActiveMQ")
        msg = @connection.receive

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

      # Subscribe to a topic or queue
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
      end

      def headers_for(msg, identity=nil)
        headers = {}
        headers = {"priority" => @msgpriority} if @msgpriority > 0

        if [:request, :direct_request].include?(msg.type)
          target = make_target(msg.agent, :reply, msg.collective)

          if msg.reply_to
            headers["reply-to"] = msg.reply_to
          else
            headers["reply-to"] = target[:name]
          end

          headers["mc_identity"] = identity if msg.type == :direct_request
        end

        return headers
      end

      def make_target(agent, type, collective)
        raise("Unknown target type #{type}") unless [:directed, :broadcast, :reply, :request, :direct_request].include?(type)
        raise("Unknown collective '#{collective}' known collectives are '#{@config.collectives.join ', '}'") unless @config.collectives.include?(collective)

        target = {:name => nil, :headers => {}}

        case type
          when :reply
            target[:name] = ["/queue/" + collective, :reply, "#{Config.instance.identity}_#{$$}"].join(".")

          when :broadcast
            target[:name] = ["/topic/" + collective, agent, :agent].join(".")

          when :request
            target[:name] = ["/topic/" + collective, agent, :agent].join(".")

          when :direct_request
            target[:name] = ["/queue/" + collective, :nodes].join(".")

          when :directed
            target[:name] = ["/queue/" + collective, :nodes].join(".")
            target[:headers]["selector"] = "mc_identity = '#{@config.identity}'"
            target[:id] = "directed_to_identity"
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
        return default if default

        raise("No plugin.#{opt} configuration option given")
      end

      # gets a boolean option from the config, supports y/n/true/false/1/0
      def get_bool_option(opt, default)
        return default unless @config.pluginconf.include?(opt)

        val = @config.pluginconf[opt]

        if val =~ /^1|yes|true/
          return true
        elsif val =~ /^0|no|false/
          return false
        else
          return default
        end
      end
    end
  end
end

# vi:tabstop=4:expandtab:ai
