module MCollective
    module RPC 
        # The main component of the Simple RPC client system, this wraps around MCollective::Client
        # and just brings in a lot of convention and standard approached.
        class Client
            attr_accessor :discovery_timeout, :timeout, :verbose, :filter, :config, :progress
            attr_reader :stats, :client

            # Creates a stub for a remote agent, you can pass in an options array in the flags
            # which will then be used else it will just create a default options array with
            # filtering enabled based on the standard command line use.
            #
            #   rpc = RPC::Client.new("rpctest", :configfile => "client.cfg", :options => options)
            #
            # You typically would not call this directly you'd use MCollective::RPC#rpcclient instead
            # which is a wrapper around this that can be used as a Mixin
            def initialize(agent, flags = {})
                if flags.include?(:options)
                    options = flags[:options]
                else
                    oparser = MCollective::Optionparser.new({:verbose => false}, "filter")
                    
                    options = oparser.parse do |parser, options|
                        if block_given?
                            yield(parser, options) 
                        end 
                    end
                end

                @agent = agent
                @discovery_timeout = options[:disctimeout]
                @timeout = options[:timeout]
                @verbose = options[:verbose]
                @filter = options[:filter]
                @filter["agent"] = agent
                @config = options[:config]
                @discovered_agents = nil
                @progress = true

                @client = client = MCollective::Client.new(@config)
                @client.options = options

                STDERR.sync = true
                STDOUT.sync = true
            end

            # Magic handler to invoke remote methods
            #
            # Once the stub is created using the constructor or the RPC#rpcclient helper you can 
            # call remote actions easily:
            #
            #   ret = rpc.echo(:msg => "hello world")
            #
            # This will call the 'echo' action of the 'rpctest' agent and return the result as an array,
            # the array will be a simplified result set from the usual full MCollective::Client#req with
            # additional error codes and error text:
            #
            # {
            #   :sender => "remote.box.com",
            #   :statuscode => 0,
            #   :statusmsg => "OK",
            #   :data => "hello world"
            # }
            #
            # If :statuscode is 0 then everything went find, if it's 1 then you supplied the correct arguments etc
            # but the request could not be completed, you'll find a human parsable reason in :statusmsg then.
            #  
            # Codes 2 to 5 maps directly to UnknownRPCAction, MissingRPCData, InvalidRPCData and UnknownRPCError
            # see below for a description of those, in each case :statusmsg would be the reason for failure.
            #
            # To get access to the full result of the MCollective::Client#req calls you can pass in a block:
            #
            #   rpc.echo(:msg => "hello world") do |resp|
            #      pp resp
            #   end
            #
            # In this case resp will the result from MCollective::Client#req.  Instead of returning simple 
            # text and codes as above you'll also need to handle the following exceptions:
            #
            # UnknownRPCAction - There is no matching action on the agent
            # MissingRPCData - You did not supply all the needed parameters for the action
            # InvalidRPCData - The data you did supply did not pass validation
            # UnknownRPCError - Some other error prevented the agent from running
            #
            # During calls a progress indicator will be shown of how many results we've received against
            # how many nodes were discovered, you can disable this by setting progress to false:
            #
            #   rpc.progress = false
            def method_missing(method_name, *args)
                req = {:agent  => @agent,
                       :action => method_name.to_s,
                       :data   => args[0]}

                twirl = ['|', '/', '-', "\\", '|', '/', '-', "\\"]
                twirldex = 0

                result = []
                respcount = 0

                @client.req(req, @agent, options, discover.size) do |resp|
                    respcount += 1

                    if block_given?
                        if resp[:body][:statuscode] == 0 || resp[:body][:statuscode] == 1
                            yield(resp)
                        else
                            case resp[:body][:statuscode]
                                when 2
                                    raise UnknownRPCAction, resp[:body][:statusmsg]
                                when 3
                                    raise MissingRPCData, resp[:body][:statusmsg]
                                when 4
                                    raise InvalidRPCData, resp[:body][:statusmsg]
                                when 5
                                    raise UnknownRPCError, resp[:body][:statusmsg]
                            end
                        end
                    else
                        if @progress
                            STDERR.print("\r #{twirl[twirldex]} [ #{respcount} / #{discover.size} ]")
                            twirldex == 7 ? twirldex = 0 : twirldex += 1
                        end

                        if resp[:body][:statuscode] == 0 || resp[:body][:statuscode] == 1
                            result << {:sender => resp[:senderid], :statuscode => resp[:body][:statuscode], 
                                       :statusmsg => resp[:body][:statusmsg], :data => resp[:body][:data]}
                        else
                            result << {:sender => resp[:senderid], :statuscode => resp[:body][:statuscode], 
                                       :statusmsg => resp[:body][:statusmsg], :data => nil}
                        end
                    end
                end

                RPC.stats @client.stats

                if @progress
                    STDERR.print("\r                                        \r")
                end

                if block_given?
                    return @client.stats
                else
                    return [result].flatten
                end
            end

            # Sets the class filter
            def class_filter(klass)
                @filter["puppet_class"] = klass
            end

            # Sets the fact filter
            def fact_filter(fact, value)
                @filter["fact"] = {:fact => fact, :value => value}
            end

            # Sets the agent filter
            def agent_filter(agent)
                @filter["agent"] = agent
            end

            # Sets the identity filter
            def identity_filter(identity)
                @filter["identity"] = identity
            end

            # Resets various internal parts of the class, most importantly it clears
            # out the cached discovery
            def reset
                @discovered_agents = nil
                @stats = nil
            end

            # Does discovery based on the filters set, i a discovery was
            # previously done return that else do a new discovery.
            #
            # Will show a message indicating its doing discovery if running
            # verbose or if the :verbose flag is passed in.
            #
            # Use reset to force a new discovery
            def discover(flags={})
                verbose = flags[:verbose] rescue verbose = @verbose

                if @discovered_agents == nil
                    STDERR.print("Determining the amount of hosts matching filter for #{discovery_timeout} seconds .... ") if verbose
                    @discovered_agents = @client.discover(@filter, @discovery_timeout)
                    STDERR.puts(@discovered_agents.size) if verbose
                end

                RPC.discovered  @discovered_agents

                @discovered_agents
            end

            # Provides a normal options hash like you would get from 
            # Optionparser
            def options
                {:disctimeout => @discovery_timeout,
                 :timeout => @timeout,
                 :verbose => @verbose,
                 :filter => @filter,
                 :config => @config}
            end
        end
    end
end
# vi:tabstop=4:expandtab:ai
