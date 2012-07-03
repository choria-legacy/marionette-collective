module MCollective
  module Logger
    # Implements a syslog based logger using the standard ruby syslog class
    class Console_logger<Base
      def start
        set_level(:info)

        config = Config.instance
        set_level(config.loglevel.to_sym) if config.configured
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

      def log(level, from, msg, normal_output=STDERR, last_resort_output=STDERR)
        if @known_levels.index(level) >= @known_levels.index(@active_level)
          time = Time.new.strftime("%Y/%m/%d %H:%M:%S")

          normal_output.puts("%s %s: %s %s" % [colorize(level, level), time, from, msg])
        end
      rescue
        # if this fails we probably cant show the user output at all,
        # STDERR it as last resort
        last_resort_output.puts("#{level}: #{msg}")
      end

      # Set some colors for various logging levels, will honor the
      # color configuration option and return nothing if its configured
      # not to
      def color(level)
        colorize = Config.instance.color

        colors = {:error => Util.color(:red),
                  :fatal => Util.color(:red),
                  :warn  => Util.color(:yellow),
                  :info  => Util.color(:green),
                  :reset => Util.color(:reset)}

        if colorize
          return colors[level] || ""
        else
          return ""
        end
      end

      # Helper to return a string in specific color
      def colorize(level, msg)
        "%s%s%s" % [ color(level), msg, color(:reset) ]
      end
    end
  end
end
