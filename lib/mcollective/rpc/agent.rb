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
        #             matadata :name        => "Test SimpleRPC Agent",
        #                      :description => "A simple test",
        #                      :author      => "You",
        #                      :license     => "1.1",
        #                      :url         => "http://your.com/,
        #                      :timeout     => 60
        #
        #             action "hello", :description => "Hello action" do
        #                 reply[:msg] = "Hello #{request[:name]}"
        #             end
        #
        #             input "name", "hello",
        #                :prompt      => "Name",
        #                :description => "The name of the user",
        #                :type        => :string,
        #                :validation  => '/./',
        #                :maxlength   => 50
        #          end
        #       end
        #    end
        #
        # The mata data, input definitions and descriptions are there to help web UI's 
        # auto generate user interfaces for your client as well as to provide automagical
        # validation of inputs etc.
        #
        # We also currently have the validation code in here, this will be moved to plugins soon.
        class Agent
            attr_accessor :meta, :reply, :request
            attr_reader :logger, :config, :timeout

            # introspection variables
            @@actions = {}
            @@meta = {}

            def initialize
                @timeout = @@meta[:timeout] || 10
                @logger = Log.instance
                @config = Config.instance
                @meta = {}

                # if we're using the new meta data, use that for the timeout
                @meta[:timeout] = @@meta[:timeout] if @@meta.include?(:timeout)

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
                    authorization_hook(msg) if respond_to?("authorization_hook")

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

            # Generates help using the template based on the data
            # created with metadata and input
            def self.help(template)
                template = IO.readlines(template).join
                meta = @@meta
                actions = @@actions

                erb = ERB.new(template, 0, '%')
                erb.result(binding)
            end

            # Compatibility layer for help as currently implimented in the
            # normal non SimpleRPC agent, it uses our introspection data
            # to auto generate help
            def help
                self.help("#{@config[:configdir]}/rpc-help.erb")
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

            # Returns the meta data for an agent
            def self.meta
                @@meta
            end

            private
            # Registers meta data for the introspection hash
            def self.metadata(meta)
                [:name, :description, :author, :license, :version, :url, :timeout].each do |arg|
                    raise "Metadata needs a :#{arg}" unless meta.include?(arg)
                end

                @@meta = meta
            end

            # Creates a new action wit the block passed and sets some defaults
            #
            # action(:description => "Restarts a Service") do
            #    # logic here to restart service
            # end
            def self.action(name, input, &block)
                raise "Action needs a :description" unless input.include?(:description)

                unless @@actions.include?(name)
                    @@actions[name] = {}
                    @@actions[name][:action] = name
                    @@actions[name][:input] = {}
                    @@actions[name][:description] = input[:description]
                end

                # If a block was passed use it to create the action 
                # but this is optional and a user can just use 
                # def to create the method later on still
                self.module_eval { define_method("#{name}_action", &block) } if block_given?
            end

            # Registers an input argument for a given action
            #
            # input "foo", "action",
            #       :prompt => "Service Action",
            #       :description => "The action to perform",
            #       :type => :list,
            #       :list => ["start", "stop", "restart", "status"]
            def self.input(argument, action, properties, &block)
                [:prompt, :description, :type].each do |arg|
                    raise "Input needs a :#{arg}" unless properties.include?(arg)
                end
        
                # in case a user is making the action using a traditional 
                # def we will just create an empty description with no block
                unless @@actions.include?(action)
                    action action, :description => ""
                end

                @@actions[action][:input][argument] = {:prompt => properties[:prompt],
                                                       :description => properties[:description],
                                                       :type => properties[:type]}
        
                case properties[:type]
                    when :string
                        raise "Input type :string needs a :validation" unless properties.include?(:validation)
                        raise "String inputs need a :maxlength" unless properties.include?(:validation)
        
                        @@actions[action][:input][argument][:validation] = properties[:validation]
                        @@actions[action][:input][argument][:maxlength] = properties[:maxlength]
        
                    when :list
                        raise "Input type :list needs a :list argument" unless properties.include?(:list)
        
                        @@actions[action][:input][argument][:list] = properties[:list]
                end
            end

            # Helper that creates a method on the class that will call your authorization
            # plugin.  If your plugin raises an exception that will abort the request
            def self.authorized_by(plugin)
                pluginname = "MCollective::Util::#{plugin.to_s.capitalize}"
                PluginManager.loadclass(pluginname)

                class_eval("
                    def authorization_hook(msg)
                        #{pluginname}.authorize(msg)
                    end
                ")
            end

            # Validates a data member, if validation is a regex then it will try to match it
            # else it supports testing object types only:
            #
            # validate :msg, String
            # validate :msg, /^[\w\s]+$/
            #
            # There are also some special helper validators:
            #
            # validate :command, :shellsafe
            # validate :command, :ipv6address
            # validate :command, :ipv4address
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
            #
            # Agents can disable auditing by just overriding this method with a noop one
            # this might be useful for agents that gets a lot of requests or simply if you
            # do not care for the auditing in a specific agent.
            def audit_request(msg, connection)
                PluginManager["rpcaudit_plugin"].audit_request(msg, connection) if @config.rpcaudit
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai
