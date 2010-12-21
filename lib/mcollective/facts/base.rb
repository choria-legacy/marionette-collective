module MCollective
    module Facts
        # A base class for fact providers, to make a new fully functional fact provider
        # inherit from this and simply provide a self.get_facts method that returns a
        # hash like:
        #
        #  {"foo" => "bar",
        #   "bar" => "baz"}
        class Base
            @@facts = {}
            @@last_good_facts = {}
            @@last_facts_load = 0

            # Registers new fact sources into the plugin manager
            def self.inherited(klass)
                PluginManager << {:type => "facts_plugin", :class => klass.to_s}
            end

            # Returns the value of a single fact
            def get_fact(fact=nil)
                config = Config.instance
                logger = Log.instance

                cache_time = config.fact_cache_time || 300

                Thread.exclusive do
                    begin
                        if (Time.now.to_i - @@last_facts_load > cache_time.to_i )
                            logger.debug("Resetting facter cache after #{cache_time} seconds, now: #{Time.now.to_i} last-known-good: #{@@last_facts_load}")

                            @@facts = load_facts_from_source

                            # Force reset to last known good state on empty facts
                            raise "Got empty facts" if @@facts.empty?

                            @@facts.each_pair do |key,value|
                                @@facts[key.to_s] = value.to_s
                            end

                            @@last_good_facts = @@facts.clone
                            @@last_facts_load = Time.now.to_i
                        else
                            logger.debug("Using cached facts now: #{Time.now.to_i} last-known-good: #{@@last_facts_load}")
                        end
                    rescue Exception => e
                        logger.error("Failed to load facts: #{e.class}: #{e}")

                        # Avoid loops where failing fact loads cause huge CPU
                        # loops, this way it only retries once every cache_time
                        # seconds
                        @@last_facts_load = Time.now.to_i

                        # Revert to last known good state
                        @@facts = @@last_good_facts.clone
                    end
                end


                # If you do not supply a specific fact all facts will be returned
                if fact.nil?
                    return @@facts
                else
                    @@facts.include?(fact) ? @@facts[fact] : nil
                end
            end

            # Returns all facts
            def get_facts
                get_fact(nil)
            end

            # Returns true if we know about a specific fact, false otherwise
            def has_fact?(fact)
                get_fact(fact).nil?
            end
        end
    end
end
