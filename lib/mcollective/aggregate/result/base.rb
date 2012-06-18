module MCollective
  class Aggregate
    module Result
      class Base
        attr_accessor :result, :aggregate_format, :action

        def initialize(result, aggregate_format, action)
          raise "No aggregate_format defined in ddl or aggregate function" unless aggregate_format

          @result = result
          @aggregate_format = aggregate_format
          @action = action
        end

        def to_s
          raise "'to_s' method not implemented for result class '#{self.class}'"
        end

        def result_type
          @result[:type]
        end
      end
    end
  end
end
