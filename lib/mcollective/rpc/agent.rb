module MCollective
    module RPC
        class Agent
            attr_accessor :timeout, :meta

            def initialize
                @timeout = 10
                @logger = Log.instance
                @config = Config.instance

                @meta = {:license => "Unknown",
                         :author => "Unknown",
                         :url => "Unknown"}

            end
                
            def handlemsg(msg, connection)
                @request = RPC.request(msg)
                @reply = RPC.reply

                begin
                    if respond_to?("#{@request.action}_action")
                        send("#{@request.action}_action")
                    else
                        raise UnknownRPCAction, "Unknown action: #{@request.action}"
                    end
                rescue UnknownRPCAction => e
                    @reply.fail e.to_s, 2

                rescue MissingRPCData => e
                    @reply.fail e.to_s, 3

                rescue InvalidRPCData => e
                    @reply.fail e.to_s, 4

                rescue UnknownRPCError => e
                    @reply.fail e.to_s, 5

                end

                @reply.to_hash
            end

            def help
                "Unconfigure MCollective::RPC::Agent"
            end

            private
            # Validates a data member, if validation is a regex then it will try to match it
            # else it supports testing object types only:
            #
            # validate :msg, String
            # validate :msg, /^[\w\s]+$/
            #
            # It will raise appropriate exceptions that the RPC system understand
            #
            # TODO: this should be plugins, 1 per validatin method so users can add their own
            #       at the moment i have it here just to proof the point really
            def validate(key, validation)
                raise MissingRPCData, "please supply a #{key}" unless @request.include?(key)

                begin
                    if validation.is_a?(Regexp)
                        raise InvalidRPCData, "#{key} should match #{regex}" unless @request[key].match(validation)

                    elsif validation.is_a?(Symbol)
                        case validation
                            when :shellsafe
                                raise InvalidRPCData, "#{key} should be a String" unless @request[key].is_a?(String)
                                raise InvalidRPCData, "#{key} should not have > in it" if @request[key].match(/>/) 
                                raise InvalidRPCData, "#{key} should not have < in it" if @request[key].match(/</) 
                                raise InvalidRPCData, "#{key} should not have \` in it" if @request[key].match(/\`/) 
                                raise InvalidRPCData, "#{key} should not have | in it" if @request[key].match(/\|/) 


                            when :ipv6address
                                begin
                                    require 'ipaddr'
                                    ip = IPAddr.new(@request[key])
                                    raise InvalidRPCData, "#{key} should be an ipv6 address" unless ip.ipv6?
                                rescue
                                    raise InvalidRPCData, "#{key} should be an ipv6 address"
                                end

                            when :ipv4address
                                begin
                                    require 'ipaddr'
                                    ip = IPAddr.new(@request[key])
                                    raise InvalidRPCData, "#{key} should be an ipv4 address" unless ip.ipv4?
                                rescue
                                    raise InvalidRPCData, "#{key} should be an ipv4 address"
                                end

                        end
                    else
                        raise InvalidRPCData, "#{key} should be a #{validation}" unless  @request.data[key].is_a?(validation)
                    end
                rescue Exception => e
                    raise UnknownRPCError, "Failed to validate #{key}: #{e}"
                end
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai
