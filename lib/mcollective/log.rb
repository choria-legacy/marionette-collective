module MCollective
  # A simple class that allows logging at various levels.
  class Log
    class << self
      @logger = nil

      # Obtain the class name of the currently configured logger
      def logger
        @logger.class
      end

      # Logs at info level
      def info(msg)
        log(:info, msg)
      end

      # Logs at warn level
      def warn(msg)
        log(:warn, msg)
      end

      # Logs at debug level
      def debug(msg)
        log(:debug, msg)
      end

      # Logs at fatal level
      def fatal(msg)
        log(:fatal, msg)
      end

      # Logs at error level
      def error(msg)
        log(:error, msg)
      end

      # handle old code that relied on this class being a singleton
      def instance
        self
      end

      # increments the active log level
      def cycle_level
        @logger.cycle_level if @configured
      end

      # reopen log files
      def reopen
        if @configured
          @logger.reopen
        end
      end

      # logs a message at a certain level
      def log(level, msg)
        configure unless @configured

        raise "Unknown log level" unless [:error, :fatal, :debug, :warn, :info].include?(level)

        if @logger
          @logger.log(level, from, msg)
        else
          t = Time.new.strftime("%H:%M:%S")

          STDERR.puts "#{t}: #{level}: #{from}: #{msg}"
        end
      end

      # sets the logger class to use
      def set_logger(logger)
        @logger = logger
      end

      # configures the logger class, if the config has not yet been loaded
      # we default to the console logging class and do not set @configured
      # so that future calls to the log method will keep attempting to configure
      # the logger till we eventually get a logging preference from the config
      # module
      def configure(logger=nil)
        unless logger
          logger_type = "console"

          config = Config.instance

          if config.configured
            logger_type = config.logger_type
            @configured = true
          end

          require "mcollective/logger/#{logger_type.downcase}_logger"

          logger_class = MCollective::Logger.const_get("#{logger_type.capitalize}_logger")

          set_logger(logger_class.new)
        else
          set_logger(logger)
          @configured = true
        end

        @logger.start
      rescue Exception => e
        @configured = false
        STDERR.puts "Could not start logger: #{e.class} #{e}"
      end

      # figures out the filename that called us
      def from
        path, line, method = execution_stack[3].split(/:(\d+)/)
        "%s:%s%s" % [File.basename(path), line, method]
      end

      # this method is here to facilitate testing and from
      def execution_stack
        caller
      end
    end
  end
end
