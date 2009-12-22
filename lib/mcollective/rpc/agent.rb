module MCollective
    module RPC
        class Agent
            attr_accessor :timeout, :meta

            def initialize
                @timeout = 10
                @log = Log.instance
                @config = Config.instance

                @meta = {:license => "Unknown",
                         :author => "Unknown",
                         :url => "Unknown"}

            end
                
            def handlemsg(msg, connection)
                request = RPC.request(msg)
                reply = RPC.reply

                begin
                    if respond_to?("#{request.action}_action")
                        send("#{request.action}_action", request, reply)
                    else
                        raise UnknownRPCAction, "Unknown action: #{request.action}"
                    end
                rescue UnknownRPCAction => e
                    reply.fail e.to_s, 2

                rescue MissingRPCData => e
                    reply.fail e.to_s, 3

                rescue InvalidRPCData => e
                    reply.fail e.to_s, 4

                rescue UnknownRPCError => e
                    reply.fail e.to_s, 5

                end

                reply.to_hash
            end

            def help
                "Unconfigure MCollective::RPC::Agent"
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai
