module MCollective
    module Facts
        require 'yaml'

        # A factsource that reads a hash of facts from a YAML file
        #
        # Multiple files can be specified seperated with a : in the
        # config file, they will be merged with later files overriding
        # earlier ones in the list.
        class Yaml_facts<Base
            def load_facts_from_source
                config = Config.instance

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
                        Log.error("Failed to load yaml facts from #{file}: #{e.class}: #{e}")
                    end
                end

                facts
            end
        end
    end
end
# vi:tabstop=4:expandtab:ai
