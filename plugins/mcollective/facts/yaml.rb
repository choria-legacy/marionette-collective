module MCollective
    module Facts
        require 'yaml'

        # A factsource that reads a hash of facts from a YAML file
        #
        # Multiple files can be specified seperated with a : in the
        # config file, they will be merged with later files overriding
        # earlier ones in the list.
        class Yaml<Base
            @@facts = {}
            @@last_good_facts = {}

            def get_facts
                Thread.exclusive do
                    reload_facts
                end
            end

            private
            def reload_facts
                config = Config.instance
                logger = Log.instance

                fact_files = config.pluginconf["yaml"].split(":")
                facts = {}

                fact_files.each do |file|
                    begin
                        if File.exist?(file)
                            facts.merge!(YAML.load_file(file))
                        else
                            raise("Can't find YAML file to load: #{file}")
                        end
                    rescue Exception => e
                        logger.error("Failed to load yaml facts from #{file}: #{e.class}: #{e}")
                    end
                end

                facts.each_pair do |key,value|
                    @@facts[key.to_s] = value.to_s
                end

                if @@facts.empty?
                    logger.error("Got empty facts, resetting to last known good")

                    @@facts = @last_good_facts.clone
                else
                    @@last_good_facts = @@facts.clone
                end
            end
        end
    end
end
# vi:tabstop=4:expandtab:ai
