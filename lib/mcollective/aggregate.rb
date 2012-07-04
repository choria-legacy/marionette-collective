module MCollective
  class Aggregate
    autoload :Result, 'mcollective/aggregate/result'
    autoload :Base, 'mcollective/aggregate/base'

    attr_accessor :ddl, :functions, :action

    def initialize(ddl)
      @functions = []
      @ddl = ddl
      @action = ddl[:action]

      create_functions
    end

    # Creates instances of the Aggregate functions and stores them in the function array.
    # All aggregate call and summarize method calls operate on these function as a batch.
    def create_functions
      @ddl[:aggregate].each_with_index do |agg, i|
        contains_output?(agg[:args][0])

        output = agg[:args][0]
        arguments = agg[:args][1..(agg[:args].size)]

        @functions << load_function(agg[:function]).new(output, arguments, agg[:format], @action)
      end
    end

    # Check if the function param is defined as an output for the action in the ddl
    def contains_output?(output)
      raise "'#{@ddl[:action]}' action does not contain output '#{output}'" unless @ddl[:output].keys.include?(output)
    end

    # Call all the appropriate functions with the reply data received from RPC::Client
    def call_functions(reply)
      @functions.each do |function|
        Log.debug("Calling aggregate function #{function} for result")
        function.process_result(reply[:data][function.output_name], reply)
      end
    end

    # Finalizes the function returning a result object
    def summarize
      summary = @functions.map do |function|
        function.summarize
      end

      summary.sort{|x,y| x.result[:output] <=> y.result[:output]}
    end

    # Loads function from disk for use
    def load_function(function_name)
      function_name = function_name.to_s.capitalize

      PluginManager.loadclass("MCollective::Aggregate::#{function_name}") unless Aggregate.const_defined?(function_name)
      Aggregate.const_get(function_name)
    rescue Exception
      raise "Aggregate function file '#{function_name.downcase}.rb' cannot be loaded"
    end
  end
end
