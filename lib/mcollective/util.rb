module MCollective
    # Some basic utility helper methods useful to clients, agents, runner etc.
    class Util
        # Finds out if this MCollective has an agent by the name passed
        def self.has_agent?(agent)
            MCollective::Agents.agentlist.include?(agent)
        end

        # Checks if this node has a puppet class by parsing the 
        # puppet classes.txt
        def self.has_puppet_class?(klass)
            File.readlines("/var/lib/puppet/classes.txt").each do |k|
                return true if k.chomp == klass
            end

            false
        end

        # Gets the value of a specific fact, mostly just a duplicate of MCollective::Facts.get_fact
        # bt it kind of goes with the other classes here
        def self.get_fact(fact)
            MCollective::Facts.get_fact(fact)
        end

        # Compares fact == value, mostly just a duplicate of MCollective::Facts.get_fact
        # bt it kind of goes with the other classes here
        def self.has_fact?(fact, value)
            MCollective::Facts.has_fact?(fact, value)
        end
    end
end

# vi:tabstop=4:expandtab:ai
