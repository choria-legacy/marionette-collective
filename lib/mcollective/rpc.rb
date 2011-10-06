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
    autoload :ActionRunner, "mcollective/rpc/actionrunner"

    # Creates a standard options hash, pass in a block to add extra headings etc
    # see Optionparser
    def rpcoptions
      oparser = MCollective::Optionparser.new({:verbose => false, :progress_bar => true}, "filter")

      options = oparser.parse do |parser, options|
        if block_given?
          yield(parser, options)
        end

        Helpers.add_simplerpc_options(parser, options)
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
    #    :exit_on_failure => true
    #
    # Options would be a build up options hash from the Optionparser
    # you can use the rpcoptions helper to create this
    #
    # :exit_on_failure is true by default, and causes the application to
    # exit if there is a failure constructing the RPC client. Set this flag
    # to false to cause an Exception to be raised instead.
    def rpcclient(agent, flags = {})
      configfile = flags[:configfile] || "/etc/mcollective/client.cfg"
      options = flags[:options] || nil

      if flags.key?(:exit_on_failure)
        exit_on_failure = flags[:exit_on_failure]
      else
        # We exit on failure by default for CLI-friendliness
        exit_on_failure = true
      end

      begin
        if options
          rpc = Client.new(agent, :configfile => options[:config], :options => options)
          @options = rpc.options
        else
          rpc = Client.new(agent, :configfile => configfile)
          @options = rpc.options
        end
      rescue Exception => e
        if exit_on_failure
          puts("Could not create RPC client: #{e}")
          exit!
        else
          raise e
        end
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
      return unless @options[:output_format] == :console

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
      format = @options[:output_format]

      result_text =  Helpers.rpcresults(result, {:verbose => verbose, :flatten => flatten, :format => format})

      if result.is_a?(Array) && format == :console
        puts "\n%s\n" % [ result_text ]
      else
        # when we get just one result to print dont pad them all with
        # blank spaces etc, just print the individual result with no
        # padding
        puts result_text unless result_text == ""
      end
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
