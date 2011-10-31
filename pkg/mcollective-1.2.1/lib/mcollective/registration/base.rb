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
                config = Config.instance
                return if config.registerinterval == 0

                Thread.new do
                    loop do
                        begin
                            target = Util.make_target("registration", :command, config.main_collective)
                            reqid = Digest::MD5.hexdigest("#{config.identity}-#{Time.now.to_f.to_s}-#{target}")
                            filter = {"agent" => "registration"}

                            registration_message = body

                            unless registration_message.nil?
                                req = PluginManager["security_plugin"].encoderequest(config.identity, target, registration_message, reqid, filter)

                                Log.debug("Sending registration #{reqid} to #{target}")
                                connection.send(target, req)
                            else
                                Log.debug("Skipping registration due to nil body")
                            end

                            sleep config.registerinterval
                        rescue Exception => e
                            Log.error("Sending registration message failed: #{e}")
                            sleep config.registerinterval
                        end
                    end
                end
            end
        end
    end
end
# vi:tabstop=4:expandtab:ai
