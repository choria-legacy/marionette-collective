require 'logger'

module MCollective
  module Logger
    # Impliments a file based logger using the standard ruby logger class
    #
    # To configure you should set:
    #
    #   - config.logfile
    #   - config.keeplogs defaults to 2097152
    #   - config.max_log_size defaults to 5
    class File_logger<Base
      def start
        config = Config.instance

        @logger = ::Logger.new(config.logfile, config.keeplogs, config.max_log_size)
        @logger.formatter = ::Logger::Formatter.new

        set_level(config.loglevel.to_sym)
      end

      def set_logging_level(level)
        @logger.level = map_level(level)
      rescue Exception => e
        @logger.level = ::Logger::DEBUG
        log(:error, "", "Could not set logging to #{level} using debug instead: #{e.class} #{e}")
      end

      def valid_levels
        {:info  => ::Logger::INFO,
         :warn  => ::Logger::WARN,
         :debug => ::Logger::DEBUG,
         :fatal => ::Logger::FATAL,
         :error => ::Logger::ERROR}
      end

      def log(level, from, msg)
        @logger.add(map_level(level)) { "#{from} #{msg}" }
      rescue
        # if this fails we probably cant show the user output at all,
        # STDERR it as last resort
        STDERR.puts("#{level}: #{msg}")
      end

      def reopen
        level = @logger.level
        @logger.close
        start
        @logger.level = level
      end
    end
  end
end
