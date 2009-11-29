require 'stomp'

module MCollective
    module Connector
        # Handles sending and receiving messages over the Stomp protocol
        class Stomp<Base
            attr_reader :connection

            def initialize
                @config = Config.instance

                @log = Log.instance
            end

            # Connects to the Stomp middleware
            def connect
                begin
                    host = nil
                    port = nil
                    user = nil
                    password = nil

                    if ENV.include?("STOMP_SERVER") 
                        host = ENV["STOMP_SERVER"]
                    else
                        raise("No STOMP_SERVER environment or plugin.stomp.host configuration option given") unless @config.pluginconf.include?("stomp.host")
                        host = @config.pluginconf["stomp.host"]
                    end

                    if ENV.include?("STOMP_PORT") 
                        port = ENV["STOMP_PORT"]
                    else
                        @config.pluginconf.include?("stomp.port") ? port = @config.pluginconf["stomp.port"].to_i : port = 6163
                    end

                    if ENV.include?("STOMP_USER") 
                        user = ENV["STOMP_USER"]
                    else
                        raise("No STOMP_USER environment or plugin.stomp.user configuration option given") unless @config.pluginconf.include?("stomp.user")
                        user = @config.pluginconf["stomp.user"]
                    end

                    if ENV.include?("STOMP_PASSWORD") 
                        password = ENV["STOMP_PASSWORD"]
                    else
                        raise("No STOMP_PASSWORD environment or plugin.stomp.password configuration option given") unless @config.pluginconf.include?("stomp.password")
                        password = @config.pluginconf["stomp.password"]
                    end


                    @log.debug("Connecting to #{host}:#{port}")
                    @connection = ::Stomp::Connection.new(user, password, host, port, true)
                rescue Exception => e
                    raise("Could not connect to Stomp Server '#{host}:#{port}' #{e}")
                end
            end

            # Receives a message from the Stomp connection
            def receive
                @log.debug("Waiting for a message from Stomp")
                @connection.receive
            end

            # Sends a message to the Stomp connection
            def send(target, msg)
                @log.debug("Sending a message to Stomp target '#{target}'")
                @connection.send(target, msg)
            end

            # Subscribe to a topic or queue
            def subscribe(source)
                @log.debug("Subscribing to #{source}")
                @connection.subscribe(source)
            end

            # Disconnects from the Stomp connection
            def disconnect
                @log.debug("Disconnecting from Stomp")
                @connection.disconnect
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai
