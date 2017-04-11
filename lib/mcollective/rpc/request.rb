module MCollective
  module RPC
    # Simple class to manage compliant requests for MCollective::RPC agents
    class Request
      attr_accessor :time, :action, :data, :sender, :agent, :uniqid, :caller, :ddl

      def initialize(msg, ddl)
        @time = msg[:msgtime]
        @action = msg[:body][:action] || msg[:body]["action"]
        @data = msg[:body][:data] || msg[:body]["data"]
        @sender = msg[:senderid]
        @agent = msg[:body][:agent] || msg[:body]["agent"]
        @uniqid = msg[:requestid]
        @caller = msg[:callerid] || "unknown"
        @ddl = ddl
      end

      # In a scenario where a request came from a JSON pure medium like a REST
      # service or other language client DDL::AgentDDL#validate_rpc_request will
      # check "package" against the intput :package should the input "package" not
      # also be known
      #
      # Thus once the request is built it will also have "package" and not :package
      # data, so we need to fetch the correct key out of the hash.
      def compatible_key(key)
        return key if data.include?(key)

        if ddl
          input = ddl.action_interface(action)[:input]

          # if :package is requested and the DDL also declares "package" we cant tell it to fetch
          # "package", hence the check against the input here
          return key.to_s if key.is_a?(Symbol) && !input.include?(key.to_s) && data.include?(key.to_s)
        end

        key
      end

      # If data is a hash, quick helper to get access to it's include? method
      # else returns false
      def include?(key)
        return false unless @data.is_a?(Hash)

        @data.include?(compatible_key(key))
      end

      # If no :process_results is specified always respond else respond
      # based on the supplied property
      def should_respond?
        return false unless @data.is_a?(Hash)
        return @data[:process_results] if @data.include?(:process_results)
        return @data["process_results"] if @data.include?("process_results")

        true
      end

      # If data is a hash, gives easy access to its members, else returns nil
      def [](key)
        return nil unless @data.is_a?(Hash)
        return @data[compatible_key(key)]
      end

      def fetch(key, default)
        return nil unless @data.is_a?(Hash)
        return @data.fetch(compatible_key(key), default)
      end

      def to_hash
        {:agent => @agent,
         :action => @action,
         :data => @data}
      end

      # Validate the request against the DDL
      def validate!
        @ddl.validate_rpc_request(@action, @data)
      end

      def to_json
        to_hash.merge!({:sender   => @sender,
                        :callerid => @callerid,
                        :uniqid   => @uniqid}).to_json
      end
    end
  end
end
