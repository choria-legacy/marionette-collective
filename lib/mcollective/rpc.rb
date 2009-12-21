require 'pp'

module MCollective
    # Toolset to create a standard interface of client and agent using
    # an RPC metaphor, standard compliant agents will make it easier
    # to create generic clients like web interfaces etc
    module RPC
        autoload :Client, "mcollective/rpc/client"
        
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
                    rpc = Client.new(agent, :configfile => configfile, :options => options)
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
        # printrpcstats can easily get access to stats without 
        # users having to pass it around in params.
        def self.stats(stats)
            @@stats = stats
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

            begin
                stats = @@stats
            rescue
                puts("no stats to display")
                return
            end

            if verbose
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
                    printf("%-30s", c)
                end
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
        # If you're not flattening the result and not running in verbose it will 
        # just print a "." for each OK result received, it will only print details
        # of the result if the agent said something was not OK.
        #
        # To get details of each result run with the -v command line option.
        def printrpc(result, flags = {})
            verbose = @options[:verbose] rescue verbose = false

            verbose = flags[:verbose] || verbose
            flatten = flags[:flatten] || false

            if flatten
                result.each_with_index do |r, count|
                    puts if count == 0

                    if r[:statuscode] == 0
                        puts r[:data][:message]
                    else
                        puts r[:statusmsg]
                    end
                end
                
                puts
            else
                result.each_with_index do |r, count|
                    puts if count == 0

                    if verbose
                        puts(r[:sender])

                        if r[:statuscode] == 0
                            msg = r[:data][:message]

                            if msg.is_a?(Array)
                                msg.each {|m| puts("     #{m}")}

                            elsif msg.is_a?(String)
                                r[:data][:message].split("\n").each {|m| puts("     #{m}")}

                            else
                                msg.pretty_inspect.split("\n").each {|m| puts("    #{m}")}

                            end
                        else
                            puts("    #{r[:statusmsg]}")
                        end
                    else
                        if r[:statuscode] == 0
                            puts(".")
                        else
                            puts if count > 0
                            puts("#{r[:sender]}: #{r[:statusmsg]}")
                        end

                    end

                    puts
                end
            end
        end
    end
end
# vi:tabstop=4:expandtab:ai
