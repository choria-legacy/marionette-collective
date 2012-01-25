require 'syslog'

module MCollective
  module Logger
    # Impliments a syslog based logger using the standard ruby syslog class
    class Syslog_logger<Base
      include Syslog::Constants

      def start
        config = Config.instance

        set_syslog_facility(config.logfacility.upcase)

        Syslog.close if Syslog.opened?
        Syslog.open(File.basename($0),3,@logfacility)

        set_level(config.loglevel.to_sym)
      end

      def set_syslog_facility(facility)
        begin
          @logfacility = Syslog.const_get("LOG_#{facility}")
        rescue NameError => e
          STDERR.puts("Invalid syslog facility #{facility}")
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
