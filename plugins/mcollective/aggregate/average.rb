module MCollective
  class Aggregate
    class Average<Base
      # Before function is run processing
      def startup_hook
        @result[:value] = 0
        @result[:type] = :numeric

        @count = 0

        # Set default aggregate_function if it is undefined
        @aggregate_format = "Average of #{@result[:output]}: %f" unless @aggregate_format
      end

      # Determines the average of a set of numerical values
      def process_result(value, reply)
        @result[:value] += value
        @count += 1
      end

      # Stops execution of the function and returns a ResultObject
      def summarize
        @result[:value] /= @count

        result_class(:numeric).new(@result, @aggregate_format, @action)
      end
    end
  end
end
