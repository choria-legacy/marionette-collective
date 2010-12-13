module MCollective
    # A simple singleton class that allows logging at various levels.
    class Log
        include Singleton

        @logger = nil

        def initialize
            config = Config.instance
            raise ("Configuration has not been loaded, can't start logger") unless config.configured

            require "mcollective/logger/#{config.logger_type.downcase}_logger"
            @logger = eval("MCollective::Logger::#{config.logger_type.capitalize}_logger.new")

            @logger.start
        rescue Exception => e
            STDERR.puts "Could not start logger: #{e.class} #{e}"
        end

        def cycle_level
            @logger.cycle_level
        end

        # Logs at info level
        def info(msg)
            @logger.log(:info, from, msg)
        end

        # Logs at warn level
        def warn(msg)
            @logger.log(:warn, from, msg)
        end

        # Logs at debug level
        def debug(msg)
            @logger.log(:debug, from, msg)
        end

        # Logs at fatal level
        def fatal(msg)
            @logger.log(:fatal, from, msg)
        end

        # Logs at error level
        def error(msg)
            @logger.log(:error, from, msg)
        end

        private
        def from
            from = File.basename(caller[1])
        end
    end
end

# vi:tabstop=4:expandtab:ai:filetype=ruby
