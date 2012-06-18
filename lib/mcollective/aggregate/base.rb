module MCollective
  class Aggregate
    class Base
      attr_accessor :name, :result, :output_name, :action, :aggregate_format, :arguments

      def initialize(output_name, arguments, aggregate_format, action)
        @name = self.class.to_s
        @output_name = output_name

        # Any additional arguments passed in the ddl after the output field will
        # be stored in the arguments array which can be used in the function
        @arguments = arguments
        @aggregate_format = aggregate_format
        @action = action
        @result = {:value => nil, :type => nil, :output => output_name}

        startup_hook
      end

      ['startup_hook', 'process_result'].each do |method|
        define_method method do
          raise RuntimeError, "'#{method}' method of function class #{@name} has not yet been implemented"
        end
      end

      # Stops execution of the function and returns a specific ResultObject,
      # aggregate functions will most likely override this but this is the simplest
      # case so we might as well default to that
      def summarize
        raise "Result type is not set while trying to summarize aggregate function results" unless @result[:type]

        result_class(@result[:type]).new(@result, @aggregate_format, @action)
      end

      def result_class(type)
        Result.const_get("#{type.to_s.capitalize}Result")
      end
    end
  end
end
