module MCollective
    module Registration
        # This is a base class that other registration plugins can use
        # to handle regular announcements to the mcollective
        class Base
            # Register plugins that inherits base
            def self.inherited(klass)
                MCollective::PluginManager << {:type => "registration_plugin", :class => klass.to_s}
            end

            def initialize
                @config = MCollective::Config.instance
                @log = MCollective::Log.instance
                @security = eval("MCollective::Security::#{@config.securityprovider}.new")
            end

            def run(connection)
                return if @config.registerinterval == 0

                Thread.new do
                    loop do
                        target = Util.make_target("registration", :command)
                        reqid = Digest::MD5.hexdigest("#{@config.identity}-#{Time.now.to_f.to_s}-#{target}")
                        filter = {"agent" => "registration"}
                        req = @security.encoderequest(@config.identity, target, body, reqid, filter)
                            
                        @log.debug("Sending registration #{reqid} to #{target}")
                        connection.send(target, req)
    
                        sleep @config.registerinterval             
                    end
                end
            end
        end
    end
end
# vi:tabstop=4:expandtab:ai
