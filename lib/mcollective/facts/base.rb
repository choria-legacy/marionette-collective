module MCollective
    module Facts
        # A base class for fact providers, to make a new fully functional fact provider 
        # inherit from this and simply provide a self.get_facts method that returns a 
        # hash like:
        #
        #  {"foo" => "bar",
        #   "bar" => "baz"}
        class Base
            # Returns the value of a single fact
            def self.get_fact(fact)
                facts = get_facts

                facts.include?(fact) ? facts[fact] : nil
            end

            # Returns true if we know about a specific fact, false otherwise
            def self.has_fact?(fact)
                facts = get_facts

                facts.include?(fact)
            end
        end
    end
end
