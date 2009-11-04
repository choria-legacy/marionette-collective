module MCollective
    module Security
        # This is a base class the other security modules should inherit from
        # it handles statistics and validation of messages that should in most 
        # cases apply to all security models
        class Base
            attr_reader :stats
    
            # Initializes configuration and logging as well as prepare a zero'd hash of stats
            # various security methods and filter validators should increment stats, see MCollective::Security::Psk for a sample
            def initialize
                @config = MCollective::Config.instance
                @log = MCollective::Log.instance
    
                @stats = {:passed => 0,
                          :filtered => 0,
                          :validated => 0,
                          :unvalidated => 0}
            end
    
            # Takes a Hash with a filter in it and validates it against host information.
            #
            # At present this supports filter matches against the following criteria:
            #
            # - puppet_class - Presence of a Puppet class in classes.txt
            # - agent - Presence of a MCollective agent with a supplied name
            # - fact - The value of a fact avout this system
            # - identity - the configured identity of the system
            def validate_filter?(filter)
                failed = 0
                passed = 0
    
                passed = 1 if filter == {}
    
                filter.keys.each do |key|
                    case key
                        when "puppet_class"
                            if MCollective::Util.has_puppet_class?(filter[key]) then
                                @log.debug("Passing based on puppet class #{filter[key]}")
                                passed += 1
                            else
                                @log.debug("Failing based on puppet class #{filter[key]}")
                                failed += 1
                            end
            
                        when "agent"
                            if MCollective::Util.has_agent?(filter[key]) || filter[key] == "mcollective"
                                @log.debug("Passing based on agent #{filter[key]}")
                                passed += 1
                            else
                                @log.debug("Failing based on agent #{filter[key]}")
                                failed += 1
                            end
            
                        when "fact"
                            fact = filter[key]
    
                            if MCollective::Facts.has_fact?(fact[:fact], fact[:value]) 
                                @log.debug("Passing based on fact #{fact} = #{filter[key]}")
                                passed += 1
                            else
                                @log.debug("Failing based on fact #{fact} = #{filter[key]}")
                                failed += 1
                            end
    
                        when "identity"
                            if @config.identity == filter[key]
                                @log.debug("Passing based on identity = #{filter[key]}")
                                passed += 1
                            else
                                @log.debug("Failed based on identity = #{filter[key]}")
                                failed += 1
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
# vi:tabstop=4:expandtab:ai
