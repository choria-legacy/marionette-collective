module MCollective
    module RPC 
        class Client
            attr_accessor :discovery_timeout, :timeout, :verbose, :filter, :config
            attr_reader :stats, :client

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

                @client = client = MCollective::Client.new(@config)
                @client.options = options

                STDERR.sync = true
                STDOUT.sync = true
            end

            # Magic handler to invoke remote methods
            def method_missing(method_name, *args)
                req = {:agent  => @agent,
                       :action => method_name.to_s,
                       :data   => args[0]}

                result = []
                @client.req(req, @agent, options, discover.size) do |resp|
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
                        if resp[:body][:statuscode] == 0 || resp[:body][:statuscode] == 1
                            result << {:sender => resp[:senderid], :statuscode => resp[:body][:statuscode], 
                                       :statusmsg => resp[:body][:statusmsg], :data => resp[:body][:data]}
                        else
                            result << {:sender => resp[:senderid], :statuscode => resp[:body][:statuscode], 
                                       :statusmsg => resp[:body][:statusmsg], :data => nil}
                        end
                    end
                end

                RPC.stats  @client.stats

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
            # Use reset to force a new discovery
            def discover
                if @discovered_agents == nil
                    STDERR.print("Determining the amount of hosts matching filter for #{discovery_timeout} seconds .... ") if @verbose
                    @discovered_agents = @client.discover(@filter, @discovery_timeout)
                    STDERR.puts(@discovered_agents.size) if @verbose
                end

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
