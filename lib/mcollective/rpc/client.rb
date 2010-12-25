module MCollective
    module RPC
        # The main component of the Simple RPC client system, this wraps around MCollective::Client
        # and just brings in a lot of convention and standard approached.
        class Client
            attr_accessor :discovery_timeout, :timeout, :verbose, :filter, :config, :progress
            attr_reader :client, :stats, :ddl, :agent, :limit_targets

            @@initial_options = nil

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

                elsif @@initial_options
                    options = Marshal.load(@@initial_options)

                else
                    oparser = MCollective::Optionparser.new({:verbose => false, :progress_bar => true, :mcollective_limit_targets => false}, "filter")

                    options = oparser.parse do |parser, options|
                        if block_given?
                            yield(parser, options)
                        end

                        Helpers.add_simplerpc_options(parser, options)
                    end

                    @@initial_options = Marshal.dump(options)
                end

                @stats = Stats.new
                @agent = agent
                @discovery_timeout = options[:disctimeout]
                @timeout = options[:timeout]
                @verbose = options[:verbose]
                @filter = options[:filter]
                @config = options[:config]
                @discovered_agents = nil
                @progress = options[:progress_bar]
                @limit_targets = options[:mcollective_limit_targets]

                agent_filter agent

                @client = client = MCollective::Client.new(@config)
                @client.options = options

                # if we can find a DDL for the service override
                # the timeout of the client so we always magically
                # wait appropriate amounts of time.
                #
                # We add the discovery timeout to the ddl supplied
                # timeout as the discovery timeout tends to be tuned
                # for local network conditions and fact source speed
                # which would other wise not be accounted for and
                # some results might get missed.
                #
                # We do this only if the timeout is the default 5
                # seconds, so that users cli overrides will still
                # get applied
                begin
                    @ddl = DDL.new(agent)
                    @timeout = @ddl.meta[:timeout] + @discovery_timeout if @timeout == 5
                rescue Exception => e
                    Log.instance.debug("Could not find DDL: #{e}")
                    @ddl = nil
                end

                STDERR.sync = true
                STDOUT.sync = true
            end

            # Disconnects cleanly from the middleware
            def disconnect
                @client.disconnect
            end

            # Returns help for an agent if a DDL was found
            def help(template)
                if @ddl
                    @ddl.help(template)
                else
                    return "Can't find DDL for agent '#{@agent}'"
                end
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
                callerid = PluginManager["security_plugin"].callerid

                {:agent  => @agent,
                 :action => action,
                 :caller => callerid,
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
            def method_missing(method_name, *args, &block)
                # set args to an empty hash if nothings given
                args = args[0]
                args = {} if args.nil?

                action = method_name.to_s

                @stats.reset

                @ddl.validate_request(action, args) if @ddl

                # Handle single target requests by doing discovery and picking
                # a random node.  Then do a custom request specifying a filter
                # that will only match the one node.
                if @limit_targets
                    target_nodes = pick_nodes_from_discovered(@limit_targets)
                    Log.instance.debug("Picked #{target_nodes.join(',')} as limited target(s)")

                    custom_request(action, args, target_nodes, {"identity" => /^(#{target_nodes.join('|')})$/}, &block)
                else
                    # Normal agent requests as per client.action(args)
                    call_agent(action, args, options, &block)
                end
            end

            # Constructs custom requests with custom filters and discovery data
            # the idea is that this would be used in web applications where you
            # might be using a cached copy of data provided by a registration agent
            # to figure out on your own what nodes will be responding and what your
            # filter would be.
            #
            # This will help you essentially short circuit the traditional cycle of:
            #
            # mc discover / call / wait for discovered nodes
            #
            # by doing discovery however you like, contructing a filter and a list of
            # nodes you expect responses from.
            #
            # Other than that it will work exactly like a normal call, blocks will behave
            # the same way, stats will be handled the same way etcetc
            #
            # If you just wanted to contact one machine for example with a client that
            # already has other filter options setup you can do:
            #
            # puppet.custom_request("runonce", {}, {:identity => "your.box.com"},
            #                       ["your.box.com"])
            #
            # This will do runonce action on just 'your.box.com', no discovery will be
            # done and after receiving just one response it will stop waiting for responses
            def custom_request(action, args, expected_agents, filter = {}, &block)
                @ddl.validate_request(action, args) if @ddl

                @stats.reset

                custom_filter = Util.empty_filter
                custom_options = options.clone

                # merge the supplied filter with the standard empty one
                # we could just use the merge method but I want to be sure
                # we dont merge in stuff that isnt actually valid
                ["identity", "fact", "agent", "cf_class"].each do |ftype|
                    if filter.include?(ftype)
                        custom_filter[ftype] = [filter[ftype], custom_filter[ftype]].flatten
                    end
                end

                # ensure that all filters at least restrict the call to the agent we're a proxy for
                custom_filter["agent"] << @agent unless custom_filter["agent"].include?(@agent)
                custom_options[:filter] = custom_filter

                # Fake out the stats discovery would have put there
                @stats.discovered_agents([expected_agents].flatten)

                # Handle fire and forget requests
                if args.include?(:process_results) && args[:process_results] == false
                    @filter = custom_filter
                    return fire_and_forget_request(action, args)
                end

                # Now do a call pretty much exactly like in method_missing except with our own
                # options and discovery magic
                if block_given?
                    call_agent(action, args, custom_options, [expected_agents].flatten) do |r|
                        block.call(r)
                    end
                else
                    call_agent(action, args, custom_options, [expected_agents].flatten)
                end
            end

            # Sets the class filter
            def class_filter(klass)
                @filter["cf_class"] << klass
                @filter["cf_class"].compact!
                reset
            end

            # Sets the fact filter
            def fact_filter(fact, value)
                @filter["fact"] << {:fact => fact, :value => value}
                @filter["fact"].compact!
                reset
            end

            # Sets the agent filter
            def agent_filter(agent)
                @filter["agent"] << agent
                @filter["agent"].compact!
                reset
            end

            # Sets the identity filter
            def identity_filter(identity)
                @filter["identity"] << identity
                @filter["identity"].compact!
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
                agent_filter @agent
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

                if @discovered_agents == nil
                    @stats.time_discovery :start

                    STDERR.print("Determining the amount of hosts matching filter for #{discovery_timeout} seconds .... ") if verbose
                    @discovered_agents = @client.discover(@filter, @discovery_timeout)
                    STDERR.puts(@discovered_agents.size) if verbose

                    @stats.time_discovery :end

                end

                @stats.discovered_agents(@discovered_agents)
                RPC.discovered(@discovered_agents)

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

            # Sets and sanity checks the limit_targets variable
            # used to restrict how many nodes we'll target
            def limit_targets=(limit)
                if limit.is_a?(String)
                    raise "Invalid limit specified: #{limit} valid limits are /^\d+%*$/" unless limit =~ /^\d+%*$/
                    @limit_targets = limit
                elsif limit.respond_to?(:to_i)
                    limit = limit.to_i
                    limit = 1 if limit == 0
                    @limit_targets = limit
                else
                    raise "Don't know how to handle limit of type #{limit.class}"
                end
            end

            private
            # Pick a number of nodes from the discovered nodes
            #
            # The count should be a string that can be either
            # just a number or a percentage like 10%
            #
            # It will select nodes from the discovered list based
            # on the rpclimitmethod configuration option which can
            # be either :first or anything else
            #
            #   - :first would be a simple way to do a distance based
            #     selection
            #   - anything else will just pick one at random
            def pick_nodes_from_discovered(count)
                if count =~ /%$/
                    pct = (discover.size * (count.to_f / 100)).to_i
                    pct == 0 ? count = 1 : count = pct
                else
                    count = count.to_i
                end

                return discover if discover.size <= count

                result = []

                if Config.instance.rpclimitmethod == :first
                    return discover[0, count]
                else
                    count.times do
                        rnd = rand(discover.size)
                        result << discover[rnd]
                        discover.delete_at(rnd)
                    end
                end

                [result].flatten
            end

            # for requests that do not care for results just
            # return the request id and don't do any of the
            # response processing.
            #
            # We send the :process_results flag with to the
            # nodes so they can make decisions based on that.
            #
            # Should only be called via method_missing
            def fire_and_forget_request(action, args)
                @ddl.validate_request(action, args) if @ddl

                req = new_request(action.to_s, args)
                return @client.sendreq(req, @agent, @filter)
            end

            # Handles traditional calls to the remote agents with full stats
            # blocks, non blocks and everything else supported.
            #
            # Other methods of calling the nodes can reuse this code by
            # for example specifying custom options and discovery data
            def call_agent(action, args, opts, disc=:auto, &block)
                # Handle fire and forget requests and make sure
                # the :process_results value is set appropriately
                if args.include?(:process_results) && args[:process_results] == false
                    return fire_and_forget_request(action, args)
                else
                    args[:process_results] = true
                end

                # Do discovery when no specific discovery
                # array is given
                disc = discover if disc == :auto

                req = new_request(action.to_s, args)

                twirl = Progress.new

                result = []
                respcount = 0

                if disc.size > 0
                    @client.req(req, @agent, opts, disc.size) do |resp|
                        respcount += 1

                        if block_given?
                            process_results_with_block(resp, block)
                        else
                            if @progress
                                puts if respcount == 1
                                print twirl.twirl(respcount, disc.size)
                            end

                            result << process_results_without_block(resp, action)
                        end
                    end

                    @stats.client_stats = @client.stats
                else
                    print("\nNo request sent, we did not discover any nodes.")
                end

                @stats.finish_request

                RPC.stats(@stats)

                print("\n\n") if @progress

                if block_given?
                    return stats
                else
                    return [result].flatten
                end
            end

            # Handles result sets that has no block associated, sets fails and ok
            # in the stats object and return a hash of the response to send to the
            # caller
            def process_results_without_block(resp, action)
                @stats.node_responded(resp[:senderid])

                if resp[:body][:statuscode] == 0 || resp[:body][:statuscode] == 1
                    @stats.ok if resp[:body][:statuscode] == 0
                    @stats.fail if resp[:body][:statuscode] == 1

                    return Result.new(@agent, action, {:sender => resp[:senderid], :statuscode => resp[:body][:statuscode],
                                                       :statusmsg => resp[:body][:statusmsg], :data => resp[:body][:data]})
                else
                    @stats.fail

                    return Result.new(@agent, action, {:sender => resp[:senderid], :statuscode => resp[:body][:statuscode],
                                                       :statusmsg => resp[:body][:statusmsg], :data => nil})
                end
            end

            # process client requests by calling a block on each result
            # in this mode we do not do anything fancy with the result
            # objects and we raise exceptions if there are problems with
            # the data
            def process_results_with_block(resp, block)
                @stats.node_responded(resp[:senderid])

                if resp[:body][:statuscode] == 0 || resp[:body][:statuscode] == 1
                    @stats.time_block_execution :start
                    block.call(resp)
                    @stats.time_block_execution :end
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
            end
        end
    end
end
# vi:tabstop=4:expandtab:ai
