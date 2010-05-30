module MCollective
    module RPC 
        # Class to wrap all the stats and to keep track of some timings
        class Stats
            attr_reader :noresponsefrom, :starttime, :discoverytime, :blocktime, :responses, :totaltime
            attr_reader :discovered, :discovered_nodes, :okcount, :failcount, :noresponsefrom, :responsesfrom

            def initialize
                reset
            end

            # Resets stats, if discovery time is set we keep it as it was
            def reset
                @noresponsefrom = []
                @responsesfrom = []
                @responses = 0
                @starttime = Time.now.to_f
                @discoverytime = 0 unless @discoverytime
                @blocktime = 0
                @totaltime = 0
                @discovered = 0
                @discovered_nodes = []
                @okcount = 0
                @failcount = 0
                @noresponsefrom = []
            end
        end

        # returns a hash of our stats
        def to_hash
            {:noresponsefrom   => @noresponsefrom,
             :starttime        => @starttime,
             :discoverytime    => @discoverytime,
             :blocktime        => @blocktime,
             :responses        => @responses,
             :totaltime        => @totaltime,
             :discovered       => @discovered,
             :discovered_nodes => @discovered_nodes,
             :noresponsefrom   => @noresponsefrom,
             :okcount          => @okcount,
             :failcount        => @failcount}
        end

        # Fake hash access to keep things backward compatible
        def [](key)
            to_hash[key]
        end

        # increment the count of ok hosts
        def ok 
            @okcount += 1
        end

        # increment the count of failed hosts
        def fail
            @failcount += 1
        end
        # Re-initializes the object with stats from the basic client
        def client_stats=(stats)
            @noresponsefrom = stats[:noresponsefrom]
            @responses = stats[:responses]
            @starttime = stats[:starttime]
            @blocktime = stats[:blocktime]
            @totaltime = stats[:totaltime]
            @discoverytime = stats[:discoverytime] if @discoverytime == 0
        end

        # Utility to time discovery from :start to :end
        def time_discovery(action)
            if action == :start
                @discovery_start = Time.now.to_f
            elsif action == :end
                @discoverytime = Time.now.to_f - @discovery_start
            else
                raise("Uknown discovery action #{action}")
            end
        end

        # helper to time block execution time
        def time_block_execution(action)
            if action == :start
                @block_start = Time.now.to_f
            elsif action == :end
                @blocktime += @block_start - Time.now.to_f
            else
                raise("Uknown block action #{action}")
            end
        end

        # Update discovered and discovered_nodes based on 
        # discovery results
        def discovered_agents(agents)
            @discovered_nodes = agents
            @discovered = agents.size
        end

        # Helper to calculate total time etc
        def finish_request
            @totaltime = @blocktime + @discoverytime

            # figures out who we had no responses from
            dhosts = @discovered_nodes.clone
            @responsesfrom.each {|r| dhosts.delete(r)}
            @noresponsefrom = dhosts
        end

        # Helper to keep track of who we received responses from
        def node_responded(node)
            @responsesfrom << node
        end

        # Returns a blob of text representing the request status based on the 
        # stats contained in this class
        def report(caption = "rpc stats", verbose = false)
            result_text = []

            if verbose
                result_text << "---- #{caption} ----"

                if @discovered
                    result_text << "           Nodes: #{@discovered} / #{@responses}"
                else
                    result_text << "           Nodes: #{@responses}"
                end

                result_text << "     Pass / Fail: %d / %d" % [@okcount, @failcount]
                result_text << "      Start Time: %s"      % [Time.at(@starttime)]
                result_text << "  Discovery Time: %.2fms"  % [@discoverytime * 1000]
                result_text << "      Agent Time: %.2fms"  % [@blocktime * 1000]
                result_text << "      Total Time: %.2fms"  % [@totaltime * 1000]
            else
                if @discovered
                    result_text << "Finished processing %d / %d hosts in %.2f ms" % [@responses, @discovered, @blocktime * 1000]
                else
                    result_text << "Finished processing %d hosts in %.2f ms" % [@responses, @blocktime * 1000]
                end
            end

            if no_response_report != ""
                result_text << "" << no_response_report
            end

            result_text.join("\n")
        end

        # Returns a blob of text indicating what nodes did not respond
        def no_response_report
            result_text = []

            if @noresponsefrom.size > 0
                result_text << "\nNo response from:\n"
    
                @noresponsefrom.each_with_index do |c,i|
                    result_text << "" if i % 4 == 0
                    result_text << "%30s" % [c]
                end

                result_text << ""
            end

            result_text.join("\n")
        end
    end
end

# vi:tabstop=4:expandtab:ai
