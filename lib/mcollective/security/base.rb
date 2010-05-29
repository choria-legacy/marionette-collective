module MCollective
    module Security
        # This is a base class the other security modules should inherit from
        # it handles statistics and validation of messages that should in most 
        # cases apply to all security models.
        # 
        # To create your own security plugin you should provide a plugin that inherits
        # from this and provides the following methods:
        #
        # decodemsg      - Decodes a message that was received from the middleware
        # encodereply    - Encodes a reply message to a previous request message
        # encoderequest  - Encodes a new request message
        # validrequest?  - Validates a request received from the middleware
        # 
        # Specifics of each of these are a bit fluid and the interfaces for this is not
        # set in stone yet, specifically the encode methods will be provided with a helper
        # that takes care of encoding the core requirements.  The best place to see how security
        # works is by looking at the provided MCollective::Security::PSK plugin.
        class Base
            attr_reader :stats
    
            # Register plugins that inherits base
            def self.inherited(klass)
                PluginManager << {:type => "security_plugin", :class => klass.to_s}
            end

            # Initializes configuration and logging as well as prepare a zero'd hash of stats
            # various security methods and filter validators should increment stats, see MCollective::Security::Psk for a sample
            def initialize
                @config = Config.instance
                @log = Log.instance
    
                @stats = {:passed => 0,
                          :filtered => 0,
                          :validated => 0,
                          :unvalidated => 0}
            end
    
            # Takes a Hash with a filter in it and validates it against host information.
            #
            # At present this supports filter matches against the following criteria:
            #
            # - puppet_class|cf_class - Presence of a configuration management class in
            #                           the file configured with classesfile
            # - agent - Presence of a MCollective agent with a supplied name
            # - fact - The value of a fact avout this system
            # - identity - the configured identity of the system
            #
            # TODO: Support REGEX and/or multiple filter keys to be AND'd
            def validate_filter?(filter)
                failed = 0
                passed = 0
    
                passed = 1 if Util.empty_filter?(filter)
    
                filter.keys.each do |key|
                    case key
                        when /puppet_class|cf_class/
                            filter[key].each do |f|
                                @log.debug("Checking for class #{f}")
                                if Util.has_cf_class?(f) then
                                    @log.debug("Passing based on configuration management class #{f}")
                                    passed += 1
                                else
                                    @log.debug("Failing based on configuration management class #{f}")
                                    failed += 1
                                end
                            end
            
                        when "agent"
                            filter[key].each do |f|
                                if Util.has_agent?(f) || f == "mcollective"
                                    @log.debug("Passing based on agent #{f}")
                                    passed += 1
                                else
                                    @log.debug("Failing based on agent #{f}")
                                    failed += 1
                                end
                            end
            
                        when "fact"
                            filter[key].each do |f|
                                if Util.has_fact?(f[:fact], f[:value]) 
                                    @log.debug("Passing based on fact #{f[:fact]} = #{f[:value]}")
                                    passed += 1
                                else
                                    @log.debug("Failing based on fact #{f[:fact]} = #{f[:value]}")
                                    failed += 1
                                end
                            end
    
                        when "identity"
                            filter[key].each do |f|
                                if Util.has_identity?(f)
                                    @log.debug("Passing based on identity = #{f}")
                                    passed += 1
                                else
                                    @log.debug("Failed based on identity = #{f}")
                                    failed += 1
                                end
                            end
                    end
                end
            
                if failed == 0 && passed > 0
                    @log.debug("Message passed the filter checks")
    
                    @stats[:passed] += 1
                    return true
                else
                    @log.debug("Message failed the filter checks")
    
                    @stats[:filtered] += 1
                    return false
                end
            end

            # Security providers should provide this, see MCollective::Security::Psk
            def validrequest?(req)
                @log.error("validrequest? is not implimented in #{this.class}")
            end
    
            # Security providers should provide this, see MCollective::Security::Psk
            def encoderequest(sender, target, msg, filter={})
                @log.error("encoderequest is not implimented in #{this.class}")
            end
    
            # Security providers should provide this, see MCollective::Security::Psk
            def encodereply(sender, target, msg, filter={})
                @log.error("encodereply is not implimented in #{this.class}")
            end
    
            # Security providers should provide this, see MCollective::Security::Psk
            def decodemsg(msg)
                @log.error("decodemsg is not implimented in #{this.class}")
            end
        end
    end
end
# vi:tabstop=4:expandtab:ai
