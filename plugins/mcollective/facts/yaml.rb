module MCollective
    module Facts
        require 'yaml'

        # A factsource that reads a hash of facts from a YAML file
        class Yaml<Base
            def get_facts
                config = Config.instance

                facts = {}

                YAML.load_file(config.pluginconf["yaml"]).each_pair do |k, v|
                    facts[k] = v.to_s
                end

                facts
            end
        end
    end
end
# vi:tabstop=4:expandtab:ai
