module MCollective
  module Logger
    # A base class for logging providers.
    #
    # Logging providers should provide the following:
    #
    #    * start - all you need to do to setup your logging
    #    * set_logging_level - set your logging to :info, :warn, etc
    #    * valid_levels - a hash of maps from :info to your internal level name
    #    * log - what needs to be done to log a specific message
    class Base
      attr_reader :active_level

      def initialize
        @known_levels = [:debug, :info, :warn, :error, :fatal]

        # Sanity check the class that impliments the logging
        @known_levels.each do |lvl|
          raise "Logger class did not specify a map for #{lvl}" unless valid_levels.include?(lvl)
        end
      end

      # Figures out the next level and sets it
      def cycle_level
        lvl = get_next_level
        set_level(lvl)

        log(lvl, "", "Logging level is now #{lvl.to_s.upcase}")
      end

      # Sets a new level and record it in @active_level
      def set_level(level)
        set_logging_level(level)
        @active_level = level.to_sym
      end

      def start
        raise "The logging class did not supply a start method"
      end

      def log(level, from, msg)
        raise "The logging class did not supply a log method"
      end

      def reopen
        # reopen may not make sense to all Loggers, but we expect it of the API
      end

      private
      def map_level(level)
        raise "Logger class do not know how to handle #{level} messages" unless valid_levels.include?(level.to_sym)

        valid_levels[level.to_sym]
      end

      # Gets the next level in the list, cycles down to the firt once it reaches the end
      def get_next_level
        # if all else fails, always go to debug mode
        nextlvl = :debug

        if @known_levels.index(@active_level) == (@known_levels.size - 1)
          nextlvl = @known_levels.first
        else
          idx = @known_levels.index(@active_level) + 1
          nextlvl = @known_levels[idx]
        end

        nextlvl
      end

      # Abstract methods to ensure the logging implimentations supply what they should
      def valid_levels
        raise "The logging class did not supply a valid_levels method"
      end
    end
  end
end
