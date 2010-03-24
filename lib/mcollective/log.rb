module MCollective
    # A simple singleton class that allows logging at various levels.
    class Log
        include Singleton

        @logger = nil

        def initialize
            config = Config.instance
            raise ("Configuration has not been loaded, can't start logger") unless config.configured

            @logger = Logger.new(config.logfile, config.keeplogs, config.max_log_size)
            @logger.formatter = Logger::Formatter.new

            case config.loglevel
                when "info"
                    @logger.level = Logger::INFO
                when "warn"
                    @logger.level = Logger::WARN
                when "debug"
                    @logger.level = Logger::DEBUG
                when "fatal"
                    @logger.level = Logger::FATAL
                when "error"
                    @logger.level = Logger::ERROR
                else
                    @logger.level = Logger::INFO
                    log(Logger::ERROR, "Invalid log level #{config.loglevel}, defaulting to info")
            end
        end

        # logs at level INFO
        def info(msg)
            log(Logger::INFO, msg)
        end

        # logs at level WARN
        def warn(msg)
            log(Logger::WARN, msg)
        end

        # logs at level DEBUG
        def debug(msg)
            log(Logger::DEBUG, msg)
        end

        # logs at level FATAL
        def fatal(msg)
            log(Logger::FATAL, msg)
        end

        # logs at level ERROR
        def error(msg)
            log(Logger::ERROR, msg)
        end

        private
        # do some fancy logging with caller information etc
        def log(severity, msg)
            begin
                from = File.basename(caller[1])
                @logger.add(severity) { "#{$$} #{from}: #{msg}" }
            rescue Exception => e
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai:filetype=ruby
