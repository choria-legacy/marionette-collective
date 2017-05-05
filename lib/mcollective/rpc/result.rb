module MCollective
  module RPC
    # Simple class to manage compliant results from MCollective::RPC agents
    #
    # Currently it just fakes Hash behaviour to the result to remain backward
    # compatible but it also knows which agent and action produced it so you
    # can associate results to a DDL
    class Result
      attr_reader :agent, :action, :results

      include Enumerable

      def initialize(agent, action, result={})
        @agent = agent
        @action = action
        @results = result

        convert_data_based_on_ddl if ddl
      end

      def ddl
        @_ddl ||= DDL.new(agent)
      rescue
        nil
      end

      def data
        @results[:data] = @results.delete("data") if @results.include?("data")

        self[:data]
      end

      # Converts keys on the supplied data to those listed as outputs
      # in the DDL.  This is to facilitate JSON based transports
      # without forcing everyone to rewrite DDLs and clients to
      # convert symbols to strings, the data will be on symbol keys
      # if the DDL has a symbol and not a string output defined
      def convert_data_based_on_ddl
        interface = ddl.action_interface(action)

        return if interface.fetch(:output, {}).empty?

        interface[:output].each do |output, properties|
          next if data.include?(output)

          if output.is_a?(Symbol) && data.include?(output.to_s)
            data[output] = data.delete(output.to_s)
          end
        end
      end

      def compatible_key(key)
        if key.is_a?(Symbol) && @results.include?(key.to_s)
          key.to_s
        else
          key
        end
      end

      def [](key)
        @results[compatible_key(key)]
      end

      def []=(key, item)
        @results[key] = item
      end

      def fetch(key, default)
        @results.fetch(compatible_key(key), default)
      end

      def each
        @results.each_pair {|k,v| yield(k,v) }
      end

      def to_json(*a)
        {:agent => @agent,
         :action => @action,
         :sender => self[:sender],
         :statuscode => self[:statuscode],
         :statusmsg => self[:statusmsg],
         :data => data}.to_json(*a)
      end

      def <=>(other)
        self[:sender] <=> other[:sender]
      end
    end
  end
end
