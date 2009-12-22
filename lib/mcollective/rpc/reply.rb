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
