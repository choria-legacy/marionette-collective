module MCollective
    module RPC 
        class Client
            attr_accessor :discovery_timeout, :timeout, :verbose, :filter, :config
            attr_reader :stats, :client

            def initialize(agent, configfile="/etc/mcollective/client.cfg")
                @agent = agent

                oparser = MCollective::Optionparser.new({:config => configfile}, "filter")
                    
                options = oparser.parse do |parser, options|
                    if block_given?
                        yield(parser, options) 
                    end
                end

                @discovery_timeout = options[:disctimeout]
                @timeout = options[:timeout]
                @verbose = options[:verbose]
                @filter = options[:filter]
                @config = options[:config]

                @client = client = MCollective::Client.new(@config)
                @client.options = options

                @filter["agent"] = agent

                @discovered_agents = nil
            end

            # Magic handler to invoke remote methods
            def method_missing(method_name, *args)
                puts("Calling #{method_name}")
                pp args[0]
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
                    @discovered_agents = @client.discover(@filter, @discovery_timeout)
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
