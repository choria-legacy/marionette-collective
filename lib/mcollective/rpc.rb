require 'pp'

module MCollective
  # Toolset to create a standard interface of client and agent using
  # an RPC metaphor, standard compliant agents will make it easier
  # to create generic clients like web interfaces etc
  module RPC
    require "mcollective/rpc/actionrunner"
    require "mcollective/rpc/agent"
    require "mcollective/rpc/audit"
    require "mcollective/rpc/client"
    require "mcollective/rpc/helpers"
    require "mcollective/rpc/progress"
    require "mcollective/rpc/reply"
    require "mcollective/rpc/request"
    require "mcollective/rpc/result"
    require "mcollective/rpc/stats"

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
      configfile = flags[:configfile] || Util.config_file_for_user
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
    # You can pass flags into it:
    #
    #   printrpcstats :caption => "Foo", :summarize => true
    #
    # This will use "Foo" as the caption to the stats in verbose
    # mode and print out any aggregate summary information if present
    def printrpcstats(flags={})
      return unless @options[:output_format] == :console

      flags = {:summarize => false, :caption => "rpc stats"}.merge(flags)

      verbose = @options[:verbose] rescue verbose = false

      begin
        stats = @@stats
      rescue
        puts("no stats to display")
        return
      end

      puts stats.report(flags[:caption], flags[:summarize], verbose)
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
      forced_mode = @options[:force_display_mode] || false

      result_text =  Helpers.rpcresults(result, {:verbose => verbose, :flatten => flatten, :format => format, :force_display_mode => forced_mode})

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

    def self.const_missing(const_name)
      super unless const_name == :DDL

      Log.warn("MCollective::RPC::DDL is deprecatd, please use MCollective::DDL instead")
      MCollective::DDL
    end
  end
end
