module MCollective
    # Some basic utility helper methods useful to clients, agents, runner etc.
    module Util
        # Finds out if this MCollective has an agent by the name passed
        #
        # If the passed name starts with a / it's assumed to be regex
        # and will use regex to match
        def self.has_agent?(agent)
            agent = Regexp.new(agent.gsub("\/", "")) if agent.match("^/")

            if agent.is_a?(Regexp)
                if Agents.agentlist.grep(agent).size > 0
                    return true
                else
                    return false
                end
            else
                return Agents.agentlist.include?(agent)
            end

            false
        end

        # Checks if this node has a puppet class by parsing the 
        # puppet classes.txt
        #
        # If the passed name starts with a / it's assumed to be regex
        # and will use regex to match
        def self.has_puppet_class?(klass)
            klass = Regexp.new(klass.gsub("\/", "")) if klass.match("^/")

            File.readlines("/var/lib/puppet/classes.txt").each do |k|
                if klass.is_a?(Regexp)
                    return true if k.chomp.match(klass)
                else
                    return true if k.chomp == klass
                end
            end

            false
        end

        # Gets the value of a specific fact, mostly just a duplicate of MCollective::Facts.get_fact
        # but it kind of goes with the other classes here
        def self.get_fact(fact)
            Facts.get_fact(fact)
        end

        # Compares fact == value,
        #
        # If the passed value starts with a / it's assumed to be regex
        # and will use regex to match
        def self.has_fact?(fact, value)
            value = Regexp.new(value.gsub("\/", "")) if value.match("^/")

            if value.is_a?(Regexp)
                return true if Facts.get_fact(fact).match(value)
            else
                return true if Facts.get_fact(fact) == value
            end

            false
        end

        # Checks if the configured identity matches the one supplied
        #
        # If the passed name starts with a / it's assumed to be regex
        # and will use regex to match
        def self.has_identity?(identity)
            identity = Regexp.new(identity.gsub("\/", "")) if identity.match("^/")

            if identity.is_a?(Regexp)
                return Config.instance.identity.match(identity)
            else
                return true if Config.instance.identity == identity
            end
            
            false
        end

        # Checks if the passed in filter is an empty one
        def self.empty_filter?(filter)
            filter == {"identity"=>[], "puppet_class"=>[], "fact"=>[], "agent"=>[]} || filter == {}
        end

        # Constructs the full target name based on topicprefix and topicsep config options
        def self.make_target(agent, type)
            config = Config.instance

            raise("Uknown target type #{type}") unless type == :command || type == :reply

            [config.topicprefix, agent, type].join(config.topicsep)
        end

        # Wrapper around PluginManager.loadclass
        def self.loadclass(klass)
            PluginManager.loadclass(klass)
        end
    end
end

# vi:tabstop=4:expandtab:ai
