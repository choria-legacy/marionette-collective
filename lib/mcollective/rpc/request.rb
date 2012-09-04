module MCollective
  module RPC
    # Simple class to manage compliant requests for MCollective::RPC agents
    class Request
      attr_accessor :time, :action, :data, :sender, :agent, :uniqid, :caller, :ddl

      def initialize(msg, ddl)
        @time = msg[:msgtime]
        @action = msg[:body][:action]
        @data = msg[:body][:data]
        @sender = msg[:senderid]
        @agent = msg[:body][:agent]
        @uniqid = msg[:requestid]
        @caller = msg[:callerid] || "unknown"
        @ddl = ddl
      end

      # If data is a hash, quick helper to get access to it's include? method
      # else returns false
      def include?(key)
        return false unless @data.is_a?(Hash)
        return @data.include?(key)
      end

      # If no :process_results is specified always respond else respond
      # based on the supplied property
      def should_respond?
        return @data[:process_results] if @data.include?(:process_results)

        return true
      end

      # If data is a hash, gives easy access to its members, else returns nil
      def [](key)
        return nil unless @data.is_a?(Hash)
        return @data[key]
      end

      def fetch(key, default)
        return nil unless @data.is_a?(Hash)
        return @data.fetch(key, default)
      end

      def to_hash
        return {:agent => @agent,
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
