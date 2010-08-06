module MCollective
    module Facts
        require 'yaml'

        # A factsource that reads a hash of facts from a YAML file
        #
        # Multiple files can be specified seperated with a : in the
        # config file, they will be merged with later files overriding
        # earlier ones in the list.
        class Yaml<Base
            def get_facts
                config = Config.instance

                fact_files = config.pluginconf["yaml"].split(":")
                facts = {}

                fact_files.each do |file|
                    if File.exist?(file)
                        facts.merge!(YAML.load_file(file))
                    else
                        Log.instance.error("Can't find YAML file to load: #{file}")
                    end
                end

                facts
            end
        end
    end
end
# vi:tabstop=4:expandtab:ai
