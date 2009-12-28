module MCollective
    class MsgDoesNotMatchRequestID < RuntimeError; end

    # Helpers for writing clients that can talk to agents, do discovery and so forth
    class Client
        attr_accessor :options, :stats

	    def initialize(configfile)
            @config = Config.instance
            @config.loadconfig(configfile)
            @log = Log.instance
            @connection = PluginManager["connector_plugin"]
            @security = PluginManager["security_plugin"]

            @options = nil

            @subscriptions = {}

            @connection.connect
        end

        # Sends a request and returns the generated request id, doesn't wait for 
        # responses and doesn't execute any passed in code blocks for responses
        def sendreq(msg, agent, filter = {})
            target = Util.make_target(agent, :command)

            reqid = Digest::MD5.hexdigest("#{@config.identity}-#{Time.now.to_f.to_s}-#{target}")

            req = @security.encoderequest(@config.identity, target, msg, reqid, filter)
    
            @log.debug("Sending request #{reqid} to #{target}")

            unless @subscriptions.include?(agent)
                topic = Util.make_target(agent, :reply)
                @log.debug("Subscribing to #{topic}")

                @connection.subscribe(topic)
                @subscriptions[agent] = 1
            end

            @connection.send(target, req)

            reqid
        end
    
        # Blocking call that waits for ever for a message to arrive.
        #
        # If you give it a requestid this means you've previously send a request
        # with that ID and now you just want replies that matches that id, in that
        # case the current connection will just ignore all messages not directed at it
        # and keep waiting for more till it finds a matching message.
        def receive(requestid = nil)
            msg = nil

            begin
                msg = @connection.receive

                msg = @security.decodemsg(msg)

                raise(MsgDoesNotMatchRequestID, "Message reqid #{requestid} does not match our reqid #{msg[:requestid]}") if msg[:requestid] != requestid
            rescue MsgDoesNotMatchRequestID => e
                @log.debug("Ignoring a message for some other client")
                retry
            end

            msg
        end

        # Performs a discovery of nodes matching the filter passed
        # returns an array of nodes
        def discover(filter, timeout)
            begin
                reqid = sendreq("ping", "discovery", filter)
                @log.debug("Waiting #{timeout} seconds for discovery replies to request #{reqid}")

                hosts = []
                Timeout.timeout(timeout) do
                    loop do
                        msg = receive(reqid)
                        @log.debug("Got discovery reply from #{msg[:senderid]}")
                        hosts << msg[:senderid]
                    end
                end
            rescue Timeout::Error => e
                hosts.sort
            rescue Exception => e
                raise
            end
        end

        # Send a request, performs the passed block for each response
        # 
        # times = req("status", "mcollectived", options, client) {|resp|
        #   pp resp
        # }
        #
        # It returns a hash of times and timeouts for discovery and total run is taken from the options
        # hash which in turn is generally built using MCollective::Optionparser
        def req(body, agent, options=false, waitfor=0)
            stat = {:starttime => Time.now.to_f, :discoverytime => 0, :blocktime => 0, :totaltime => 0}

            options = @options unless options

            STDOUT.sync = true

            reqid = sendreq(body, agent, options[:filter])

            hosts_responded = 0

            begin
                Timeout.timeout(options[:timeout]) do
                    loop do
                        resp = receive(reqid)
    
                        hosts_responded += 1

                        yield(resp)

                        break if (waitfor != 0 && hosts_responded >= waitfor)
                    end
                end
            rescue Interrupt => e
            rescue Timeout::Error => e
            end

            stat[:totaltime] = Time.now.to_f - stat[:starttime]
            stat[:blocktime] = stat[:totaltime] - stat[:discoverytime]
            stat[:responses] = hosts_responded
            stat[:noresponsefrom] = []

            @stats = stat
            return stat
        end

        # Performs a discovery and then send a request, performs the passed block for each response
        # 
        #    times = discovered_req("status", "mcollectived", options, client) {|resp|
        #       pp resp
        #    }
        #
        # It returns a hash of times and timeouts for discovery and total run is taken from the options
        # hash which in turn is generally built using MCollective::Optionparser
        def discovered_req(body, agent, options=false)
            stat = {:starttime => Time.now.to_f, :discoverytime => 0, :blocktime => 0, :totaltime => 0}

            options = @options unless options

            STDOUT.sync = true

            print("Determining the amount of hosts matching filter for #{options[:disctimeout]} seconds .... ")

            discovered_hosts = discover(options[:filter], options[:disctimeout])
            discovered = discovered_hosts.size
            hosts_responded = []
            hosts_not_responded = discovered_hosts

            stat[:discoverytime] = Time.now.to_f - stat[:starttime]

            puts("#{discovered}\n\n")

            raise("No matching clients found") if discovered == 0

            reqid = sendreq(body, agent, options[:filter])

            begin
                Timeout.timeout(options[:timeout]) do
                    (1..discovered).each do |c|
                        resp = receive(reqid)
    
                        hosts_responded << resp[:senderid]
                        hosts_not_responded.delete(resp[:senderid]) if hosts_not_responded.include?(resp[:senderid])

                        yield(resp)
                    end
                end
            rescue Interrupt => e
            rescue Timeout::Error => e
            end

            stat[:totaltime] = Time.now.to_f - stat[:starttime]
            stat[:blocktime] = stat[:totaltime] - stat[:discoverytime]
            stat[:responses] = hosts_responded.size
            stat[:responsesfrom] = hosts_responded
            stat[:noresponsefrom] = hosts_not_responded
            stat[:discovered] = discovered

            @stats = stat
            return stat
        end

        # Prints out the stats returns from req and discovered_req in a nice way
        def display_stats(stats, options=false, caption="stomp call summary")
            options = @options unless options

            if options[:verbose]
                puts("\n---- #{caption} ----")

                if stats[:discovered]
                    puts("           Nodes: #{stats[:discovered]} / #{stats[:responses]}")
                else
                    puts("           Nodes: #{stats[:responses]}")
                end

                printf("      Start Time: %s\n", Time.at(stats[:starttime]))
                printf("  Discovery Time: %.2fms\n", stats[:discoverytime] * 1000)
                printf("      Agent Time: %.2fms\n", stats[:blocktime] * 1000)
                printf("      Total Time: %.2fms\n", stats[:totaltime] * 1000)
    
            else
                if stats[:discovered]
                    printf("\nFinished processing %d / %d hosts in %.2f ms\n\n", stats[:responses], stats[:discovered], stats[:blocktime] * 1000)
                else
                    printf("\nFinished processing %d hosts in %.2f ms\n\n", stats[:responses], stats[:blocktime] * 1000)
                end
            end

            if stats[:noresponsefrom].size > 0
                puts("\nNo response from:\n")
    
                stats[:noresponsefrom].each do |c|
                    puts if c % 4 == 1
                    printf("%30s", c)
                end

                puts
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai
