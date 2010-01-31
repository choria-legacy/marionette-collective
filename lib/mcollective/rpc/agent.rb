module MCollective
    module RPC
        # A wrapper around the traditional agent, it takes care of a lot of the tedious setup
        # you would do for each agent allowing you to just create methods following a naming 
        # standard leaving the heavy lifting up to this clas.
        #
        # See http://code.google.com/p/mcollective/wiki/SimpleRPCAgents
        #
        # It only really makes sense to use this with a Simple RPC client on the other end, basic
        # usage would be:
        #
        #    module MCollective
        #       module Agent
        #          class Helloworld<RPC::Agent
        #              def echo_action
        #                  validate :msg, String
        #                  
        #                  reply.data = request[:msg]              
        #              end
        #          end
        #       end
        #    end
        #
        # We also currently have the validation code in here, this will be moved to plugins soon.
        class Agent
            attr_accessor :meta, :reply, :request
            attr_reader :logger, :config, :timeout

            @@actions = {}

            def initialize
                @timeout = 10
                @logger = Log.instance
                @config = Config.instance

                @meta = {:license => "Unknown",
                         :author => "Unknown",
                         :version => "Unknown",
                         :url => "Unknown"}

                startup_hook
            end
                
            def handlemsg(msg, connection)
                @request = RPC.request(msg)
                @reply = RPC.reply

                # Audits the request, currently continues processing the message
                # we should make this a configurable so that an audit failure means
                # a message wont be processed by this node depending on config
                begin
                    audit_request(@request, connection)
                rescue Exception => e
                    @logger.warn("Audit failed - #{e} - continuing to process message")
                end

                begin
                    before_processing_hook(msg, connection)

                    if respond_to?("#{@request.action}_action")
                        send("#{@request.action}_action")
                    else
                        raise UnknownRPCAction, "Unknown action: #{@request.action}"
                    end
                rescue RPCAborted => e
                    @reply.fail e.to_s, 1

                rescue UnknownRPCAction => e
                    @reply.fail e.to_s, 2

                rescue MissingRPCData => e
                    @reply.fail e.to_s, 3

                rescue InvalidRPCData => e
                    @reply.fail e.to_s, 4

                rescue UnknownRPCError => e
                    @reply.fail e.to_s, 5

                end

                after_processing_hook

                @reply.to_hash
            end

            def help
                "Unconfigure MCollective::RPC::Agent"
            end

            # Returns an array of actions this agent support
            def self.actions
                public_instance_methods.sort.grep(/_action$/).map do |method|
                    $1 if method =~ /(.+)_action$/
                end
            end

            # Returns the interface for a specific action
            def self.action_interface(name)
                @@actions[name] || {}
            end

            private
            # Registers an action into the introspection hash
            #
            # register_action(:name => "service")
            def self.register_action(args)
                raise "Please specify a :name for register_action" unless args.include?(:name)
        
                name = args[:name]
        
                @@actions[name] = {}
                @@actions[name][:name] = name
                @@actions[name][:input] = {}
            end

            # Registers an input argument for a given action
            #
            # register_input(:action => "foo",
            #                :name => "action",
            #                :prompt => "Service Action",
            #                :description => "The action to perform",
            #                :type => :list,
            #                :list => ["start", "stop", "restart", "status"])
            def self.register_input(input)
                raise "Input needs a :name" unless input.include?(:name)
                raise "Input needs a :prompt" unless input.include?(:prompt)
                raise "Input needs a :description" unless input.include?(:description)
                raise "Input needs a :type" unless input.include?(:type)
        
                name = input[:action]
                inputname = input[:name]
                @@actions[name][:input][inputname] = {:prompt => input[:prompt],
                                                      :description => input[:description],
                                                      :type => input[:type]}
        
                case input[:type]
                    when :string
                        raise "Input type :string needs a :validation" unless input.include?(:validation)
                        raise "String inputs need a :maxlength" unless input.include?(:validation)
        
                        @@actions[name][:input][inputname][:validation] = input[:validation]
                        @@actions[name][:input][inputname][:maxlength] = input[:maxlength]
        
                    when :list
                        raise "Input type :list needs a :list argument" unless input.include?(:list)
        
                        @@actions[name][:input][inputname][:list] = input[:list]
                end
            end

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
                        raise InvalidRPCData, "#{key} should match #{validation}" unless @request[key].match(validation)

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

            # Called at the end of the RPC::Agent standard initialize method
            # use this to adjust meta parameters, timeouts and any setup you 
            # need to do.
            #
            # This will not be called right when the daemon starts up, we use
            # lazy loading and initialization so it will only be called the first
            # time a request for this agent arrives.
            def startup_hook
            end

            # Called just after a message was received from the middleware before
            # it gets passed to the handlers.  @request and @reply will already be
            # set, the msg passed is the message as received from the normal
            # mcollective runner and the connection is the actual connector.
            def before_processing_hook(msg, connection)
            end

            # Called at the end of processing just before the response gets sent
            # to the middleware.
            #
            # This gets run outside of the main exception handling block of the agent
            # so you should handle any exceptions you could raise yourself.  The reason 
            # it is outside of the block is so you'll have access to even status codes
            # set by the exception handlers.  If you do raise an exception it will just
            # be passed onto the runner and processing will fail.
            def after_processing_hook
            end

            # Gets called right after a request was received and calls audit plugins
            def audit_request(msg, connection)
                PluginManager["rpcaudit_plugin"].audit_request(msg, connection) if @config.rpcaudit
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai
