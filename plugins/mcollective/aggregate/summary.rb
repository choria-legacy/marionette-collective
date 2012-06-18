module MCollective
  class Aggregate
    class Summary<Base
      # Before function is run processing
      def startup_hook
        @result[:value] = {}
        @result[:type] = :collection

        # set default aggregate_format if it is undefined
        @aggregate_format = "%s : %s" unless @aggregate_format
      end

      # Increments the value field if value has been seen before
      # Else create a new value field
      def process_result(value, reply)
        unless value.nil?
          if value.is_a? Array
            value.map{|val| add_value(val)}
          else
            add_value(value)
          end
        end
      end

      def add_value(value)
        if @result[:value].keys.include?(value)
          @result[:value][value] += 1
        else
          @result[:value][value] = 1
        end
      end
    end
  end
end
