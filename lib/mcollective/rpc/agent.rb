module MCollective
    module RPC
        # A wrapper around the traditional agent, it takes care of a lot of the tedious setup
        # you would do for each agent allowing you to just create methods following a naming
        # standard leaving the heavy lifting up to this clas.
        #
        # See http://marionette-collective.org/simplerpc/agents.html
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
        #             action "hello" do
        #                 reply[:msg] = "Hello #{request[:name]}"
        #             end
        #
        #             action "foo" do
        #                 implemented_by "/some/script.sh"
        #             end
        #          end
        #       end
        #    end
        #
        # If you wish to implement the logic for an action using an external script use the
        # implemented_by method that will cause your script to be run with 2 arguments.
        #
        # The first argument is a file containing JSON with the request and the 2nd argument
        # is where the script should save its output as a JSON hash.
        #
        # We also currently have the validation code in here, this will be moved to plugins soon.
        class Agent
            attr_accessor :meta, :reply, :request
            attr_reader :logger, :config, :timeout, :ddl

            def initialize
                # Default meta data unset
                @meta = {:timeout     => 10,
                         :name        => "Unknown",
                         :description => "Unknown",
                         :author      => "Unknown",
                         :license     => "Unknown",
                         :version     => "Unknown",
                         :url         => "Unknown"}

                @timeout = meta[:timeout] || 10
                @logger = Log.instance
                @config = Config.instance
                @agent_name = self.class.to_s.split("::").last.downcase

                # Loads the DDL so we can later use it for validation
                # and help generation
                begin
                    @ddl = DDL.new(@agent_name)
                rescue Exception => e
                    Log.debug("Failed to load DDL for agent: #{e.class}: #{e}")
                    @ddl = nil
                end

                # if we have a global authorization provider enable it
                # plugins can still override it per plugin
                self.class.authorized_by(@config.rpcauthprovider) if @config.rpcauthorization

                startup_hook
            end

            def handlemsg(msg, connection)
                @request = RPC.request(msg)
                @reply = RPC.reply

                begin
                    # Calls the authorization plugin if any is defined
                    # if this raises an exception we wil just skip processing this
                    # message
                    authorization_hook(@request) if respond_to?("authorization_hook")


                    # Audits the request, currently continues processing the message
                    # we should make this a configurable so that an audit failure means
                    # a message wont be processed by this node depending on config
                    audit_request(@request, connection)

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

                rescue Exception => e
                    @reply.fail e.to_s, 5

                end

                after_processing_hook

                if @request.should_respond?
                    return @reply.to_hash
                else
                    Log.debug("Client did not request a response, surpressing reply")
                    return nil
                end
            end

            # By default RPC Agents support a toggle in the configuration that
            # can enable and disable them based on the agent name
            #
            # Example an agent called Foo can have:
            #
            # plugin.foo.activate_agent = false
            #
            # and this will prevent the agent from loading on this particular
            # machine.
            #
            # Agents can use the activate_when helper to override this for example:
            #
            # activate_when do
            #    File.exist?("/usr/bin/puppet")
            # end
            def self.activate?
                agent_name = self.to_s.split("::").last.downcase

                Log.debug("Starting default activation checks for #{agent_name}")

                should_activate = Config.instance.pluginconf["#{agent_name}.activate_agent"]

                if should_activate
                    Log.debug("Found plugin config #{agent_name}.activate_agent with value #{should_activate}")
                    unless should_activate =~ /^1|y|true$/
                        return false
                    end
                end

                return true
            end

            # Generates help using the template based on the data
            # created with metadata and input
            def self.help(template)
                if @ddl
                    @ddl.help(template)
                else
                    "No DDL defined"
                end
            end

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


            private
            # Runs a command via the MC::Shell wrapper, options are as per MC::Shell
            #
            # The simplest use is:
            #
            #   out = ""
            #   err = ""
            #   status = run("echo 1", :stdout => out, :stderr => err)
            #
            #   reply[:out] = out
            #   reply[:error] = err
            #   reply[:exitstatus] = status
            #
            # This can be simplified as:
            #
            #   reply[:exitstatus] = run("echo 1", :stdout => :out, :stderr => :error)
            #
            # You can set a command specific environment and cwd:
            #
            #   run("echo 1", :cwd => "/tmp", :environment => {"FOO" => "BAR"})
            #
            # This will run 'echo 1' from /tmp with FOO=BAR in addition to a setting forcing
            # LC_ALL = C.  To prevent LC_ALL from being set either set it specifically or:
            #
            #   run("echo 1", :cwd => "/tmp", :environment => nil)
            #
            # Exceptions here will be handled by the usual agent exception handler or any
            # specific one you create, if you dont it will just fall through and be sent
            # to the client
            def run(command, options={})
                shellopts = {}

                # force stderr and stdout to be strings as the library
                # will append data to them if given using the << method.
                #
                # if the data pased to :stderr or :stdin is a Symbol
                # add that into the reply hash with that Symbol
                [:stderr, :stdout].each do |k|
                    if options.include?(k)
                        if options[k].is_a?(Symbol)
                            reply[ options[k] ] = ""
                            shellopts[k] = reply[ options[k] ]
                        else
                            if options[k].respond_to?("<<")
                                shellopts[k] = options[k]
                            else
                                reply.fail! "#{k} should support << while calling run(#{command})"
                            end
                        end
                    end
                end

                [:stdin, :cwd, :environment].each do |k|
                    if options.include?(k)
                        shellopts[k] = options[k]
                    end
                end

                shell = Shell.new(command, shellopts)

                shell.runcommand

                if options[:chomp]
                    shellopts[:stdout].chomp! if shellopts[:stdout].is_a?(String)
                    shellopts[:stderr].chomp! if shellopts[:stderr].is_a?(String)
                end

                shell.status.exitstatus
            end

            # Registers meta data for the introspection hash
            def self.metadata(data)
                [:name, :description, :author, :license, :version, :url, :timeout].each do |arg|
                    raise "Metadata needs a :#{arg}" unless data.include?(arg)
                end

                # Our old style agents were able to do all sorts of things to the meta
                # data during startup_hook etc, don't really want that but also want
                # backward compat.
                #
                # Here if you're using the new metadata way this replaces the getter
                # with one that always return the same data, setter will still work but
                # wont actually do anything of note.
                define_method("meta") {
                    data
                }
            end

            # Creates the needed activate? class in a manner similar to the other
            # helpers like action, authorized_by etc
            #
            # activate_when do
            #    File.exist?("/usr/bin/puppet")
            # end
            def self.activate_when(&block)
                (class << self; self; end).instance_eval do
                    define_method("activate?", &block)
                end
            end

            # Creates a new action with the block passed and sets some defaults
            #
            # action "status" do
            #    # logic here to restart service
            # end
            def self.action(name, &block)
                raise "Need to pass a body for the action" unless block_given?

                self.module_eval { define_method("#{name}_action", &block) }
            end

            # Helper that creates a method on the class that will call your authorization
            # plugin.  If your plugin raises an exception that will abort the request
            def self.authorized_by(plugin)
                plugin = plugin.to_s.capitalize

                # turns foo_bar into FooBar
                plugin = plugin.to_s.split("_").map {|v| v.capitalize}.join
                pluginname = "MCollective::Util::#{plugin}"

                PluginManager.loadclass(pluginname) unless MCollective::Util.constants.include?(plugin)

                class_eval("
                    def authorization_hook(request)
                        #{pluginname}.authorize(request)
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
                raise MissingRPCData, "please supply a #{key} argument" unless @request.include?(key)

                if validation.is_a?(Regexp)
                    raise InvalidRPCData, "#{key} should match #{validation}" unless @request[key].match(validation)

                elsif validation.is_a?(Symbol)
                    case validation
                        when :shellsafe
                            raise InvalidRPCData, "#{key} should be a String" unless @request[key].is_a?(String)

                            ['`', '$', ';', '|', '&&', '>', '<'].each do |chr|
                                raise InvalidRPCData, "#{key} should not have #{chr} in it" if @request[key].match(Regexp.escape(chr))
                            end

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

                        when :boolean
                            raise InvalidRPCData, "#{key} should be boolean" unless [TrueClass, FalseClass].include?(@request[key].class)
                    end
                else
                    raise InvalidRPCData, "#{key} should be a #{validation}" unless  @request[key].is_a?(validation)
                end
            end

            # convenience wrapper around Util#shellescape
            def shellescape(str)
                Util.shellescape(str)
            end

            # handles external actions
            def implemented_by(command, type=:json)
                runner = ActionRunner.new(command, request, type)

                res = runner.run

                reply.fail! "Did not receive data from #{command}" unless res.include?(:data)
                reply.fail! "Reply data from #{command} is not a Hash" unless res[:data].is_a?(Hash)

                reply.data.merge!(res[:data])

                if res[:exitstatus] > 0
                    reply.fail "Failed to run #{command}: #{res[:stderr]}", res[:exitstatus]
                end
            rescue Exception => e
                Log.warn("Unhandled #{e.class} exception during #{request.agent}##{request.action}: #{e}")
                reply.fail! "Unexpected failure calling #{command}: #{e.class}: #{e}"
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
            rescue Exception => e
                Log.warn("Audit failed - #{e} - continuing to process message")
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai
