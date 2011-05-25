module MCollective
    module Registration
        # This is a base class that other registration plugins can use
        # to handle regular announcements to the mcollective
        #
        # The configuration file determines how often registration messages
        # gets sent using the _registerinterval_ option, the plugin runs in the
        # background in a thread.
        class Base
            # Register plugins that inherits base
            def self.inherited(klass)
                PluginManager << {:type => "registration_plugin", :class => klass.to_s}
            end

            # Creates a background thread that periodically send a registration notice.
            #
            # The actual registration notices comes from the 'body' method of the registration
            # plugins.
            def run(connection)
                return false if interval == 0

                Thread.new do
                    loop do
                        begin
                            publish(body, connection)

                            sleep interval
                        rescue Exception => e
                            Log.error("Sending registration message failed: #{e}")
                            sleep interval
                        end
                    end
                end
            end

            def config
                Config.instance
            end

            def identity
                config.identity
            end

            def msg_filter
                {"agent" => "registration"}
            end

            def msg_id(target)
                reqid = Digest::MD5.hexdigest("#{config.identity}-#{Time.now.to_f.to_s}-#{target}")
            end

            def msg_target
                Util.make_target("registration", :command, target_collective)
            end

            def target_collective
                main_collective = config.main_collective

                collective = config.registration_collective || main_collective

                unless config.collectives.include?(collective)
                    Log.warn("Sending registration to #{main_collective}: #{collective} is not a valid collective")
                    collective = main_collective
                end

                return collective
            end

            def interval
                config.registerinterval
            end

            def publish(message, connection)
                unless message
                    Log.debug("Skipping registration due to nil body")
                else
                    target = msg_target
                    reqid = msg_id(target)

                    req = PluginManager["security_plugin"].encoderequest(identity, target, message, reqid, msg_filter)

                    Log.debug("Sending registration #{reqid} to #{target}")

                    connection.publish(target, req)
                end
            end
        end
    end
end
# vi:tabstop=4:expandtab:ai
