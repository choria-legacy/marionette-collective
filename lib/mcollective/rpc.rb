require 'pp'

module MCollective
    # Toolset to create a standard interface of client and agent using
    # an RPC metaphor, standard compliant agents will make it easier
    # to create generic clients like web interfaces etc
    module RPC
        autoload :Client, "mcollective/rpc/client"
        autoload :Agent, "mcollective/rpc/agent"
        autoload :Reply, "mcollective/rpc/reply"
        autoload :Request, "mcollective/rpc/request"
        autoload :Audit, "mcollective/rpc/audit"
        
        # Creates a standard options hash, pass in a block to add extra headings etc
        # see Optionparser
        def rpcoptions
            oparser = MCollective::Optionparser.new({:verbose => false}, "filter")
                    
            options = oparser.parse do |parser, options|
                if block_given?
                    yield(parser, options) 
                end 
            end

            return options
        end

        # Wrapper to create clients, supposed to be used as 
        # a mixin:
        #
        # include MCollective::RPC
        #
        # exim = rpcclient("exim")
        # printrpc exim.mailq
        #
        # or
        #
        # rpcclient("exim") do |exim|
        #    printrpc exim.mailq
        # end
        #
        # It will take a few flags:
        #    :configfile => "etc/client.cfg"
        #    :options => options
        #
        # Options would be a build up options hash from the Optionparser
        # you can use the rpcoptions helper to create this 
        def rpcclient(agent, flags = {})
            configfile = flags[:configfile] || "/etc/mcollective/client.cfg"
            options = flags[:options] || nil

            begin
                if options
                    rpc = Client.new(agent, :configfile => options[:config], :options => options)
                    @options = rpc.options
                else
                    rpc = Client.new(agent, :configfile => configfile)
                    @options = rpc.options
                end
            rescue Exception => e
                puts("Could not create RPC client: #{e}")
                exit!
            end

            if block_given?
                yield(rpc)
            else
                return rpc
            end
        end

        # means for other classes to drop stats into this module
        # its a bit hacky but needed so that the mixin methods like
        # printrpcstats can easily get access to it without 
        # users having to pass it around in params.
        def self.stats(stats)
            @@stats = stats
        end

        # means for other classes to drop discovered hosts into this module
        # its a bit hacky but needed so that the mixin methods like
        # printrpcstats can easily get access to it without 
        # users having to pass it around in params.
        def self.discovered(discovered)
            @@discovered = discovered
        end

        # Prints stats, requires stats to be saved from elsewhere
        # using the MCollective::RPC.stats method.
        #
        # If you've passed -v on the command line a detailed stat block
        # will be printed, else just a one liner.
        #
        # You can pass flags into it, at the moment only one flag is 
        # supported:
        #
        # printrpcstats :caption => "Foo"
        #
        # This will use "Foo" as the caption to the stats in verbose
        # mode
        def printrpcstats(flags={})
            verbose = @options[:verbose] rescue verbose = false
            caption = flags[:caption] || "rpc stats"

            STDOUT.sync = true
            STDERR.sync = true

            begin
                stats = @@stats
            rescue
                puts("no stats to display")
                return
            end

            puts

            if verbose
                puts("---- #{caption} ----")

                if stats[:discovered]
                    puts("           Nodes: #{stats[:discovered]} / #{stats[:responses]}")
                else
                    puts("           Nodes: #{stats[:responses]}")
                end

                printf("     Pass / Fail: %d / %d\n", stats[:okcount], stats[:failcount])
                printf("      Start Time: %s\n", Time.at(stats[:starttime]))
                printf("  Discovery Time: %.2fms\n", stats[:discoverytime] * 1000)
                printf("      Agent Time: %.2fms\n", stats[:blocktime] * 1000)
                printf("      Total Time: %.2fms\n", stats[:totaltime] * 1000)
    
            else
                if stats[:discovered]
                    printf("Finished processing %d / %d hosts in %.2f ms\n\n", stats[:responses], stats[:discovered], stats[:blocktime] * 1000)
                else
                    printf("Finished processing %d hosts in %.2f ms\n\n", stats[:responses], stats[:blocktime] * 1000)
                end
            end

            if stats[:noresponsefrom].size > 0
                puts("\nNo response from:\n")
    
                stats[:noresponsefrom].each_with_index do |c,i|
                    puts if i % 4 == 0
                    printf("%30s", c)
                end

                puts
            end
        end

        # Prints the result of an RPC call.
        #
        # It tries hard to do sane things so you often
        # should not need to write your own display functions
        #
        # Takes flags:
        #    printrpc exim.mailq, :flatten => true
        #    printrpc exim.mailq, :verbose => true
        #
        # If you've asked it to flatten the result it will not print sender 
        # hostnames, it will just print the result as if it's one huge result, 
        # handy for things like showing a combined mailq.
        #
        # In the default quiet mode - no flattening or verbose - only results
        # that produce an error will be printed
        #
        # To get details of each result run with the -v command line option.
        def printrpc(result, flags = {})
            verbose = @options[:verbose] rescue verbose = false

            verbose = flags[:verbose] || verbose
            flatten = flags[:flatten] || false

            if flatten
                result.each_with_index do |r, count|
                    puts if count == 0

                    if r[:statuscode] <= 1
                        data = r[:data]

                        unless data.is_a?(String)
                            pp data
                        else
                            puts data
                        end
                    else
                        pp r
                    end
                end
                
                puts
            else
                result.each_with_index do |r, count|
                    puts if count == 0

                    if verbose
                        printf("%-40s: %s\n", r[:sender], r[:statusmsg])

                        if r[:statuscode] <= 1
                            r[:data].pretty_inspect.split("\n").each {|m| puts("    #{m}")}
                            puts "\n"
                        elsif r[:statuscode] == 2
                            # dont print anything, no useful data to display
                            # past what was already shown
                        elsif r[:statuscode] == 3
                            # dont print anything, no useful data to display
                            # past what was already shown
                        elsif r[:statuscode] == 4
                            # dont print anything, no useful data to display
                            # past what was already shown
                        else
                            puts("    #{r[:statusmsg]}")
                            puts "\n"
                        end
                    else
                        unless r[:statuscode] == 0
                            printf("%-40s %s\n", r[:sender], r[:statusmsg])
                        end
                    end

                    STDOUT.flush
                end
            end
            puts
        end

        # Wrapper for MCollective::Util.empty_filter? to make clients less fugly
        # to write - ticket #18
        def empty_filter?(options)
            if options.include?(:filter)
                Util.empty_filter?(options[:filter])
            else
                Util.empty_filter?(options)
            end
        end

        # Factory for RPC::Request messages, only really here to make agents
        # a bit easier to understand
        def self.request(msg)
            RPC::Request.new(msg)
        end

        # Factory for RPC::Reply messages, only really here to make agents
        # a bit easier to understand
        def self.reply
            RPC::Reply.new
        end
    end
end
# vi:tabstop=4:expandtab:ai
