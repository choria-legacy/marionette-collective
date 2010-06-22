module MCollective
    module RPC
        # Various utilities for the RPC system
        class Util
            # Return color codes, if the config color= option is false
            # just return a empty string
            def self.color(code)
                colorize = Config.instance.color

                colors = {:red => "[31m",
                          :green => "[32m",
                          :yellow => "[33m",
                          :cyan => "[36m",
                          :bold => "[1m",
                          :reset => "[0m"}

                if colorize
                    return colors[code] || ""
                else
                    return ""
                end
            end

            # Helper to return a string in specific color
            def self.colorize(code, msg)
                "#{self.color(code)}#{msg}#{self.color(:reset)}"
            end
        end
    end
end
