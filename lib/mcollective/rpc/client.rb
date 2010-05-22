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
                @filter["agent"] << agent
                @config = options[:config]
                @discovered_agents = nil
                @progress = true

                @client = client = MCollective::Client.new(@config)
                @client.options = options

                STDERR.sync = true
                STDOUT.sync = true
            end

            # Creates a suitable request hash for the SimpleRPC agent.
            #
            # You'd use this if you ever wanted to take care of sending 
            # requests on your own - perhaps via Client#sendreq if you
            # didn't care for responses.
            #
            # In that case you can just do:
            #
            #   msg = your_rpc.new_request("some_action", :foo => :bar)
            #   filter = your_rpc.filter
            #
            #   your_rpc.client.sendreq(msg, msg[:agent], filter)
            #
            # This will send a SimpleRPC request to the action some_action
            # with arguments :foo = :bar, it will return immediately and 
            # you will have no indication at all if the request was receieved or not
            #
            # Clearly the use of this technique should be limited and done only
            # if your code requires such a thing
            def new_request(action, data)
                {:agent  => @agent,
                 :action => action,
                 :caller => "uid=#{Process.uid}",
                 :data   => data}
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
            #
            # This supports a 2nd mode where it will send the SimpleRPC request and never handle the 
            # responses.  It's a bit like UDP, it sends the request with the filter attached and you
            # only get back the requestid, you have no indication about results.
            #
            # You can invoke this using:
            #
            #   puts rpc.echo(:process_results => false)
            #
            # This will output just the request id.
            def method_missing(method_name, *args)
                req = new_request(method_name.to_s, args[0])

                # for requests that do not care for results just 
                # return the request id and don't do any of the
                # response processing.
                #
                # We send the :process_results flag with to the 
                # nodes so they can make decisions based on that.
                if args[0].include?(:process_results)
                    if req[:data][:process_results] == false
                        return @client.sendreq(req, @agent, @filter) 
                    end
                else
                    args[0][:process_results] = true
                end

                twirl = ['|', '/', '-', "\\", '|', '/', '-', "\\"]
                twirldex = 0

                result = []
                respcount = 0
                respfrom = []
                okcount = 0
                failcount = 0

                @stats = {:starttime => Time.now.to_f, :discoverytime => 0, :blocktime => 0, :totaltime => 0}

                if discover.size > 0
                    @client.req(req, @agent, options, discover.size) do |resp|
                        respcount += 1
                        respfrom << resp[:senderid]
    
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
                                puts if respcount == 1
    
                                dashes = ((respcount.to_f / discover.size) * 60).round
    
                                if respcount == discover.size
                                    STDERR.print("\r * [ ")
                                else
                                    STDERR.print("\r #{twirl[twirldex]} [ ")
                                end
    
                                dashes.times { STDERR.print("=") }
                                STDERR.print(">")
                                (60 - dashes).times { STDERR.print(" ") }
                                STDERR.print(" ] #{respcount} / #{discover.size}")
    
                                twirldex == 7 ? twirldex = 0 : twirldex += 1
                            end
    
                            if resp[:body][:statuscode] == 0 || resp[:body][:statuscode] == 1
                                okcount += 1 if resp[:body][:statuscode] == 0
                                failcount += 1 if resp[:body][:statuscode] == 1
    
                                result << {:sender => resp[:senderid], :statuscode => resp[:body][:statuscode], 
                                           :statusmsg => resp[:body][:statusmsg], :data => resp[:body][:data]}
                            else
                                failcount += 1
    
                                result << {:sender => resp[:senderid], :statuscode => resp[:body][:statuscode], 
                                           :statusmsg => resp[:body][:statusmsg], :data => nil}
                            end
                        end
                    end
    
                    @stats = @client.stats
                else
                    print("\nNo request sent, we did not discovered any nodes.")
                end

                # Fiddle the stats to be relevant to how we use the client
                @stats[:discoverytime] = @discovery_time
                @stats[:discovered] = @discovered_agents.size
                @stats[:discovered_nodes] = @discovered_agents
                @stats[:okcount] = okcount
                @stats[:failcount] = failcount
                @stats[:totaltime] = @stats[:blocktime] + @stats[:discoverytime]

                # Figure out the list of hosts we have not had responses from
                dhosts = @discovered_agents.clone
                respfrom.each {|r| dhosts.delete(r)}
                @stats[:noresponsefrom] = dhosts

                RPC.stats stats

                print("\n\n") if @progress

                if block_given?
                    return @stats
                else
                    return [result].flatten
                end
            end

            # Sets the class filter
            def class_filter(klass)
                @filter["cf_class"] << klass
                reset
            end

            # Sets the fact filter
            def fact_filter(fact, value)
                @filter["fact"] << {:fact => fact, :value => value}
                reset
            end

            # Sets the agent filter
            def agent_filter(agent)
                @filter["agent"] << agent
                reset
            end

            # Sets the identity filter
            def identity_filter(identity)
                @filter["identity"] << identity
                reset
            end

            # Resets various internal parts of the class, most importantly it clears
            # out the cached discovery
            def reset
                @discovered_agents = nil
            end

            # Reet the filter to an empty one
            def reset_filter
                @filter = Util.empty_filter
                @filter["agent"] << @agent

                reset
            end

            # Does discovery based on the filters set, i a discovery was
            # previously done return that else do a new discovery.
            #
            # Will show a message indicating its doing discovery if running
            # verbose or if the :verbose flag is passed in.
            #
            # Use reset to force a new discovery
            def discover(flags={})
                flags.include?(:verbose) ? verbose = flags[:verbose] : verbose = @verbose

                starttime = Time.now.to_f

                if @discovered_agents == nil
                    STDERR.print("Determining the amount of hosts matching filter for #{discovery_timeout} seconds .... ") if verbose
                    @discovered_agents = @client.discover(@filter, @discovery_timeout)
                    STDERR.puts(@discovered_agents.size) if verbose

                    @discovery_time = Time.now.to_f - starttime
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
