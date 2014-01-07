module MCollective
  module Logger
    # Implements a syslog based logger using the standard ruby syslog class
    class Syslog_logger<Base
      require 'syslog'

      include Syslog::Constants

      def start
        config = Config.instance

        facility = syslog_facility(config.logfacility)
        level = config.loglevel.to_sym

        Syslog.close if Syslog.opened?
        Syslog.open(File.basename($0), 3, facility)

        set_level(level)
      end

      def syslog_facility(facility)
        begin
          Syslog.const_get("LOG_#{facility.upcase}")
        rescue NameError => e
          STDERR.puts "Invalid syslog facility #{facility} supplied, reverting to USER"
          Syslog::LOG_USER
        end
      end

      def set_logging_level(level)
        # noop
      end

      def valid_levels
        {:info  => :info,
         :warn  => :warning,
         :debug => :debug,
         :fatal => :crit,
         :error => :err}
      end

      def log(level, from, msg)
        if @known_levels.index(level) >= @known_levels.index(@active_level)
          Syslog.send(map_level(level), "#{from} #{msg}")
        end
      rescue
        # if this fails we probably cant show the user output at all,
        # STDERR it as last resort
        STDERR.puts("#{level}: #{msg}")
      end
    end
  end
end
