require 'bunny'

module MCollective
    module Connector
        # Handles sending and receiving messages over the AMQP protocol using Bunny
        class Bunny<Base
            attr_reader :connection

            def initialize
                @config = Config.instance
                @log = Log.instance
            end

            # Connects to the AMQP middleware
            def connect
                begin
                    opts = {}

                    opts[:host] = ENV["AMQP_SERVER"] || @config.pluginconf["amqp.host"] || nil
                    opts[:port] = ENV["AMQP_PORT"] || @config.pluginconf["amqp.port"] || nil
                    opts[:user] = ENV["AMQP_USER"] || @config.pluginconf["amqp.user"] || nil
                    opts[:pass] = ENV["AMQP_PASSWORD"] || @config.pluginconf["amqp.password"] || nil

                    @log.debug("Connecting to amqp...")

                    @bunny = ::Bunny.new(opts.delete_if{|k, v| v == nil})

                    @bunny.start

                    @exchange = @bunny.exchange("mcollective", :type => :topic)

                    queuename = @config.identity + "_" + $$.to_s
                    @log.debug("Creating queue #{queuename}")
                    @queue = @bunny.queue(queuename)
                rescue Exception => e
                    raise("Could not connect to AMQP Server #{e}")
                end
            end

            # Receives a message from the AMQP connection
            def receive
                @log.debug("Waiting for a message from AMQP")

                loop do
                    msg = @queue.pop

                    return Request.new(msg[:payload]) unless msg[:payload] == :queue_empty
                     
                    sleep 0.1
                end
            end

            # Sends a message to the AMQP connection
            def send(target, msg)
                @log.debug("Sending a message to AMQP target '#{target}'")
                @exchange.publish(msg, :key => target)
            end

            # Subscribe to a topic or queue
            def subscribe(source)
                @log.debug("Subscribing to #{source}")

                @queue.bind(@exchange, :key => source)
            end

            # Subscribe to a topic or queue
            def unsubscribe(source)
                @log.debug("Unsubscribing from #{source}")

                @queue.unbind(@exchange, :key => source)
            end

            # Disconnects from the AMQP connection
            def disconnect
                @log.debug("Disconnecting from AMQP")
                @bunny.stop
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai
