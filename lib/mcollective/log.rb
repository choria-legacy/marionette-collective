module MCollective
  # A simple class that allows logging at various levels.
  class Log
    class << self
      @logger = nil

      VALID_LEVELS = [:error, :fatal, :debug, :warn, :info]

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

      def config_and_check_level(level)
        configure unless @configured
        check_level(level)
        @logger.should_log?(level)
      end

      def check_level(level)
        raise "Unknown log level" unless valid_level?(level)
      end

      def valid_level?(level)
        VALID_LEVELS.include?(level)
      end

      def message_for(msgid, args={})
        "%s: %s" % [msgid, Util.t(msgid, args)]
      end

      def logexception(msgid, level, e, backtrace=false, args={})
        return false unless config_and_check_level(level)

        origin = File.basename(e.backtrace[1])

        if e.is_a?(CodedError)
          msg = "%s: %s" % [e.code, e.to_s]
        else
          error_string = "%s: %s" % [e.class, e.to_s]
          msg = message_for(msgid, args.merge(:error => error_string))
        end

        log(level, msg, origin)

        if backtrace
          e.backtrace.each do |line|
            log(level, "%s:          %s" % [msgid, line], origin)
          end
        end
      end

      # Logs a message at a certain level, the message must be
      # a token that will be looked up from the i18n localization
      # database
      #
      # Messages can interprolate strings from the args hash, a
      # message with "foo %{bar}" in the localization database
      # will use args[:bar] for the value there, the interprolation
      # is handled by the i18n library itself
      def logmsg(msgid, default, level, args={})
        return false unless config_and_check_level(level)

        msg = message_for(msgid, {:default => default}.merge(args))

        log(level, msg)
      end

      # logs a message at a certain level
      def log(level, msg, origin=nil)
        return unless config_and_check_level(level)

        origin = from unless origin

        if @logger
          @logger.log(level, origin, msg)
        else
          t = Time.new.strftime("%H:%M:%S")

          STDERR.puts "#{t}: #{level}: #{origin}: #{msg}"
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

          require "mcollective/logger/%s_logger" % logger_type.downcase

          logger_class = MCollective::Logger.const_get("%s_logger" % logger_type.capitalize)

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

      def unconfigure
        @configured = false
        set_logger(nil)
      end

      # figures out the filename that called us
      def from
        from = File.basename(caller[2])
      end
    end
  end
end
