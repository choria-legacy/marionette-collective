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
        autoload :Progress, "mcollective/rpc/progress"
        autoload :Stats, "mcollective/rpc/stats"
        autoload :DDL, "mcollective/rpc/ddl"
        autoload :Result, "mcollective/rpc/result"
        autoload :Helpers, "mcollective/rpc/helpers"

        # Creates a standard options hash, pass in a block to add extra headings etc
        # see Optionparser
        def rpcoptions
            oparser = MCollective::Optionparser.new({:verbose => false, :progress_bar => true}, "filter")

            options = oparser.parse do |parser, options|
                if block_given?
                    yield(parser, options)
                end

                add_simplerpc_options(parser, options)
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

            begin
                stats = @@stats
            rescue
                puts("no stats to display")
                return
            end

            puts
            puts stats.report(caption, verbose)
        end

        # Prints the result of an RPC call.
        #
        # In the default quiet mode - no flattening or verbose - only results
        # that produce an error will be printed
        #
        # To get details of each result run with the -v command line option.
        def printrpc(result, flags = {})
            verbose = @options[:verbose] rescue verbose = false
            verbose = flags[:verbose] || verbose
            flatten = flags[:flatten] || false

            puts
            puts rpcresults(result, {:verbose => verbose, :flatten => flatten})
        end

        # Returns a blob of text representing the results in a standard way
        #
        # It tries hard to do sane things so you often
        # should not need to write your own display functions
        #
        # If the agent you are getting results for has a DDL
        # it will use the hints in there to do the right thing specifically
        # it will look at the values of display in the DDL to choose
        # when to show results
        #
        # If you do not have a DDL you can pass these flags:
        #
        #    printrpc exim.mailq, :flatten => true
        #    printrpc exim.mailq, :verbose => true
        #
        # If you've asked it to flatten the result it will not print sender
        # hostnames, it will just print the result as if it's one huge result,
        # handy for things like showing a combined mailq.
        def rpcresults(result, flags = {})
            flags = {:verbose => false, :flatten => false}.merge(flags)

            result_text = ""

            # if running in verbose mode, just use the old style print
            # no need for all the DDL helpers obfuscating the result
            if flags[:verbose]
                result_text = old_rpcresults(result, flags)
            else
                result.each do |r|
                    begin
                        ddl = DDL.new(r.agent).action_interface(r.action.to_s)

                        sender = r[:sender]
                        status = r[:statuscode]
                        message = r[:statusmsg]
                        display = ddl[:display]
                        result = r[:data]

                        # appand the results only according to what the DDL says
                        case display
                            when :ok
                                if status == 0
                                    result_text << text_for_result(sender, status, message, result, ddl)
                                end

                            when :failed
                                if status > 0
                                    result_text << text_for_result(sender, status, message, result, ddl)
                                end

                            when :always
                                result_text << text_for_result(sender, status, message, result, ddl)

                            when :flatten
                                result_text << text_for_flattened_result(status, result)

                        end
                    rescue Exception => e
                        # no DDL so just do the old style print unchanged for
                        # backward compat
                        result_text = old_rpcresults(result, flags)
                    end
                end
            end

            result_text
        end

        # Return text representing a result
        def text_for_result(sender, status, msg, result, ddl)
            statusses = ["",
                         Helpers.colorize(:red, "Request Aborted"),
                         Helpers.colorize(:yellow, "Unknown Action"),
                         Helpers.colorize(:yellow, "Missing Request Data"),
                         Helpers.colorize(:yellow, "Invalid Request Data"),
                         Helpers.colorize(:red, "Unknown Request Status")]

            result_text = "%-40s %s\n" % [sender, statusses[status]]
            result_text << "   %s\n" % [Util.colorize(:yellow, msg)] unless msg == "OK"

            # only print good data, ignore data that results from failure
            if [0, 1].include?(status)
                if result.is_a?(Hash)
                    # figure out the lengths of the display as strings, we'll use
                    # it later to correctly justify the output
                    lengths = result.keys.map{|k| ddl[:output][k][:display_as].size}

                    result.keys.each do |k|
                        # get all the output fields nicely lined up with a
                        # 3 space front padding
                        display_as = ddl[:output][k][:display_as]
                        display_length = display_as.size
                        padding = lengths.max - display_length + 3
                        result_text << " " * padding

                        result_text << "#{display_as}:"

                        if result[k].is_a?(String) || result[k].is_a?(Numeric)
                            result_text << " #{result[k]}\n"
                        else
                            result_text << "\n\t" + result[k].pretty_inspect.split("\n").join("\n\t") + "\n"
                        end
                    end
                else
                    result_text << "\n\t" + result.pretty_inspect.split("\n").join("\n\t")
                end
            end

            result_text << "\n"
            result_text
        end

        # Returns text representing a flattened result of only good data
        def text_for_flattened_result(status, result)
            result_text = ""

            if status <= 1
                unless result.is_a?(String)
                    result_text << result.pretty_inspect
                else
                    result_text << result
                end
            end
        end

        # Backward compatible display block for results without a DDL
        def old_rpcresults(result, flags = {})
            result_text = ""

            if flags[:flatten]
                result.each do |r|
                    if r[:statuscode] <= 1
                        data = r[:data]

                        unless data.is_a?(String)
                            result_text << data.pretty_inspect
                        else
                            result_text << data
                        end
                    else
                        result_text << r.pretty_inspect
                    end
                end

                result_text << ""
            else
                result.each do |r|

                    if flags[:verbose]
                        result_text << "%-40s: %s\n" % [r[:sender], r[:statusmsg]]

                        if r[:statuscode] <= 1
                            r[:data].pretty_inspect.split("\n").each {|m| result_text += "    #{m}"}
                            result_text += "\n"
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
                            result_text << "    #{r[:statusmsg]}"
                        end
                    else
                        unless r[:statuscode] == 0
                            result_text << "%-40s %s\n" % [r[:sender], Helpers.colorize(:red, r[:statusmsg])]
                        end
                    end
                end
            end

            result_text << ""
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

        # Add SimpleRPC common options
        def add_simplerpc_options(parser, options)
            parser.separator ""

            # add SimpleRPC specific options to all clients that use our library
            parser.on('--np', '--no-progress', 'Do not show the progress bar') do |v|
                options[:progress_bar] = false
            end
        end

    end
end
# vi:tabstop=4:expandtab:ai
