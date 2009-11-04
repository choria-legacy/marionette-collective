module MCollective
    module Facts
        require 'yaml'

        # A factsource that reads a hash of facts from a YAML file
        class Yaml<Base
            def self.get_facts
                config = MCollective::Config.instance

                YAML.load_file(config.pluginconf["yaml"])
            end
        end
    end
end
# vi:tabstop=4:expandtab:ai
