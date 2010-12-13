module MCollective
    module Logger
        # Impliments a syslog based logger using the standard ruby syslog class
        class Console_logger<Base
            def start
                config = Config.instance
                set_level(config.loglevel.to_sym)
            end

            def set_logging_level(level)
                # nothing to do here, we ignore high levels when we log
            end

            def valid_levels
                {:info  => :info,
                 :warn  => :warning,
                 :debug => :debug,
                 :fatal => :crit,
                 :error => :err}
            end

            def log(level, from, msg)
                if @known_levels.index(level) <= @known_levels.index(@active_level)
                    time = Time.new.strftime("%Y/%m/%d %H:%M:%S")
                    lvltxt = colorize(level, level)
                    STDERR.puts("#{lvltxt} #{time}: #{from} #{msg}")
                end
            rescue
                # if this fails we probably cant show the user output at all,
                # STDERR it as last resort
                STDERR.puts("#{level}: #{msg}")
            end

            # Set some colors for various logging levels, will honor the
            # color configuration option and return nothing if its configured
            # not to
            def color(level)
                colorize = Config.instance.color

                colors = {:error => "[31m",
                          :fatal => "[31m",
                          :warn => "[33m",
                          :info => "[32m",
                          :reset => "[0m"}

                if colorize
                    return colors[level] || ""
                else
                    return ""
                end
            end

            # Helper to return a string in specific color
            def colorize(level, msg)
                "#{self.color(level)}#{msg}#{self.color(:reset)}"
            end
        end
    end
end
