module MCollective
  class Aggregate
    class Sum<Base
      def startup_hook
        @result[:value] = 0
        @result[:type] = :numeric

        # Set default aggregate_function if it is undefined
        @aggregate_format = "Sum of #{@result[:output]}: %f" unless @aggregate_format
      end

      # Determines the average of a set of numerical values
      def process_result(value, reply)
        @result[:value] += value
      end
    end
  end
end
