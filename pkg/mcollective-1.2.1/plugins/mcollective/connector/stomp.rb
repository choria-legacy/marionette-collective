require 'stomp'

module MCollective
    module Connector
        # Handles sending and receiving messages over the Stomp protocol
        #
        # This plugin supports version 1.1 or 1.1.6 and newer of the Stomp rubygem
        # the versions between those had multi threading issues.
        #
        # For all versions you can configure it as follows:
        #
        #    connector = stomp
        #    plugin.stomp.host = stomp.your.net
        #    plugin.stomp.port = 6163
        #    plugin.stomp.user = you
        #    plugin.stomp.password = secret
        #
        # All of these can be overriden per user using environment variables:
        #
        #    STOMP_SERVER, STOMP_PORT, STOMP_USER, STOMP_PASSWORD
        #
        # Version 1.1.6 onward support supplying multiple connections and it will
        # do failover between these servers, you can configure it as follows:
        #
        #     connector = stomp
        #     plugin.stomp.pool.size = 2
        #
        #     plugin.stomp.pool.host1 = stomp1.your.net
        #     plugin.stomp.pool.port1 = 6163
        #     plugin.stomp.pool.user1 = you
        #     plugin.stomp.pool.password1 = secret
        #     plugin.stomp.pool.ssl1 = true
        #
        #     plugin.stomp.pool.host2 = stomp2.your.net
        #     plugin.stomp.pool.port2 = 6163
        #     plugin.stomp.pool.user2 = you
        #     plugin.stomp.pool.password2 = secret
        #     plugin.stomp.pool.ssl2 = false
        #
        # Using this method you can supply just STOMP_USER and STOMP_PASSWORD
        # you have to supply the hostname for each pool member in the config.
        # The port will default to 6163 if not specified.
        #
        # In addition you can set the following options but only when using
        # pooled configuration:
        #
        #     plugin.stomp.pool.initial_reconnect_delay = 0.01
        #     plugin.stomp.pool.max_reconnect_delay = 30.0
        #     plugin.stomp.pool.use_exponential_back_off = true
        #     plugin.stomp.pool.back_off_multiplier = 2
        #     plugin.stomp.pool.max_reconnect_attempts = 0
        #     plugin.stomp.pool.randomize = false
        #     plugin.stomp.pool.timeout = -1
        #
        # For versions of ActiveMQ that supports message priorities
        # you can set a priority, this will cause a "priority" header
        # to be emitted if present:
        #
        #     plugin.stomp.priority = 4
        #
        class Stomp<Base
            attr_reader :connection

            def initialize
                @config = Config.instance
                @subscriptions = []
            end

            # Connects to the Stomp middleware
            def connect
                if @connection
                    Log.debug("Already connection, not re-initializing connection")
                    return
                end

                begin
                    host = nil
                    port = nil
                    user = nil
                    password = nil
                    @base64 = get_bool_option("stomp.base64", false)
                    @msgpriority = get_option("stomp.priority", 0).to_i

                    # Maintain backward compat for older stomps
                    unless @config.pluginconf.include?("stomp.pool.size")
                        host = get_env_or_option("STOMP_SERVER", "stomp.host")
                        port = get_env_or_option("STOMP_PORT", "stomp.port", 6163).to_i
                        user = get_env_or_option("STOMP_USER", "stomp.user")
                        password = get_env_or_option("STOMP_PASSWORD", "stomp.password")

                        Log.debug("Connecting to #{host}:#{port}")
                        @connection = ::Stomp::Connection.new(user, password, host, port, true)
                    else
                        pools = @config.pluginconf["stomp.pool.size"].to_i
                        hosts = []

                        1.upto(pools) do |poolnum|
                            host = {}

                            host[:host] = get_option("stomp.pool.host#{poolnum}")
                            host[:port] = get_option("stomp.pool.port#{poolnum}", 6163).to_i
                            host[:login] = get_env_or_option("STOMP_USER", "stomp.pool.user#{poolnum}")
                            host[:passcode] = get_env_or_option("STOMP_PASSWORD", "stomp.pool.password#{poolnum}")
                            host[:ssl] = get_bool_option("stomp.pool.ssl#{poolnum}", false)

                            Log.debug("Adding #{host[:host]}:#{host[:port]} to the connection pool")
                            hosts << host
                        end

                        raise "No hosts found for the STOMP connection pool" if hosts.size == 0

                        connection = {:hosts => hosts}

                        # Various STOMP gem options, defaults here matches defaults for 1.1.6 the meaning of
                        # these can be guessed, the documentation isn't clear
                        connection[:initial_reconnect_delay] = get_option("stomp.pool.initial_reconnect_delay", 0.01).to_f
                        connection[:max_reconnect_delay] = get_option("stomp.pool.max_reconnect_delay", 30.0).to_f
                        connection[:use_exponential_back_off] = get_bool_option("stomp.pool.use_exponential_back_off", true)
                        connection[:back_off_multiplier] = get_bool_option("stomp.pool.back_off_multiplier", 2).to_i
                        connection[:max_reconnect_attempts] = get_option("stomp.pool.max_reconnect_attempts", 0)
                        connection[:randomize] = get_bool_option("stomp.pool.randomize", false)
                        connection[:backup] = get_bool_option("stomp.pool.backup", false)
                        connection[:timeout] = get_option("stomp.pool.timeout", -1).to_i

                        @connection = ::Stomp::Connection.new(connection)
                    end
                rescue Exception => e
                    raise("Could not connect to Stomp Server: #{e}")
                end
            end

            # Receives a message from the Stomp connection
            def receive
                Log.debug("Waiting for a message from Stomp")
                msg = @connection.receive

                # STOMP puts the payload in the body variable, pass that
                # into the payload of MCollective::Request and discard all the
                # other headers etc that stomp provides
                if @base64
                    Request.new(SSL.base64_decode(msg.body))
                else
                    Request.new(msg.body)
                end
            end

            # Sends a message to the Stomp connection
            def send(target, msg)
                Log.debug("Sending a message to Stomp target '#{target}'")

                msg = SSL.base64_encode(msg) if @base64

                # deal with deprecation warnings in newer stomp gems
                if @connection.respond_to?("publish")
                    @connection.publish(target, msg, msgheaders)
                else
                    @connection.send(target, msg, msgheaders)
                end
            end

            # Subscribe to a topic or queue
            def subscribe(source)
                unless @subscriptions.include?(source)
                    Log.debug("Subscribing to #{source}")
                    @connection.subscribe(source)
                    @subscriptions << source
                end
            end

            # Subscribe to a topic or queue
            def unsubscribe(source)
                Log.debug("Unsubscribing from #{source}")
                @connection.unsubscribe(source)
                @subscriptions.delete(source)
            end

            # Disconnects from the Stomp connection
            def disconnect
                Log.debug("Disconnecting from Stomp")
                @connection.disconnect
            end

            private
            def msgheaders
                headers = {}
                headers = {"priority" => @msgpriority} if @msgpriority > 0

                return headers
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
