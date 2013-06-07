module MCollective
  module RPC
    # Simple class to manage compliant replies to MCollective::RPC
    class Reply
      attr_accessor :statuscode, :statusmsg, :data

      def initialize(action, ddl)
        @data = {}
        @statuscode = 0
        @statusmsg = "OK"
        @ddl = ddl
        @action = action

        begin
          initialize_data
        rescue Exception => e
          Log.warn("Could not pre-populate reply data from the DDL: %s: %s" % [e.class, e.to_s ])
        end
      end

      def initialize_data
        unless @ddl.actions.include?(@action)
          raise "No action '%s' defined for agent '%s' in the DDL" % [@action, @ddl.pluginname]
        end

        interface = @ddl.action_interface(@action)

        interface[:output].keys.each do |output|
          # must deep clone this data to avoid accidental updates of the DDL in cases where the
          # default is for example a string and someone does << on it
          @data[output] = Marshal.load(Marshal.dump(interface[:output][output].fetch(:default, nil)))
        end
      end

      # Helper to fill in statusmsg and code on failure
      def fail(msg, code=1)
        @statusmsg = msg
        @statuscode = code
      end

      # Helper that fills in statusmsg and code but also raises an appropriate error
      def fail!(msg, code=1)
        @statusmsg = msg
        @statuscode = code

        case code
          when 1
            raise RPCAborted, msg

          when 2
            raise UnknownRPCAction, msg

          when 3
            raise MissingRPCData, msg

          when 4
            raise InvalidRPCData, msg

          else
            raise UnknownRPCError, msg
        end
      end

      # Write to the data hash
      def []=(key, val)
        @data[key] = val
      end

      # Read from the data hash
      def [](key)
        @data[key]
      end

      def fetch(key, default)
        @data.fetch(key, default)
      end

      # Returns a compliant Hash of the reply that should be sent
      # over the middleware
      def to_hash
        return {:statuscode => @statuscode,
                :statusmsg => @statusmsg,
                :data => @data}
      end
    end
  end
end
