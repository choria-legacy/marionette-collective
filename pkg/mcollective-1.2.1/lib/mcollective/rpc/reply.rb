module MCollective
    module RPC
        # Simple class to manage compliant replies to MCollective::RPC
        class Reply
            attr_accessor :statuscode, :statusmsg, :data

            def initialize
                @data = {}
                @statuscode = 0
                @statusmsg = "OK"
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
# vi:tabstop=4:expandtab:ai
