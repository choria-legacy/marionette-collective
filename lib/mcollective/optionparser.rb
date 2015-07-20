module MCollective
  # A simple helper to build cli tools that supports a uniform command line
  # layout.
  class Optionparser
    attr_reader :parser

    # Creates a new instance of the parser, you can supply defaults and include named groups of options.
    #
    # Starts a parser that defaults to verbose and that includs the filter options:
    #
    #  oparser = MCollective::Optionparser.new({:verbose => true}, "filter")
    #
    # Stats a parser in non verbose mode that does support discovery
    #
    #  oparser = MCollective::Optionparser.new()
    #
    # Starts a parser in verbose mode that does not show the common options:
    #
    #  oparser = MCollective::Optionparser.new({:verbose => true}, "filter", "common")
    def initialize(defaults = {}, include_sections = nil, exclude_sections = nil)
      @parser = ::OptionParser.new

      @include = [include_sections].flatten
      @exclude = [exclude_sections].flatten

      @options = Util.default_options

      @options.merge!(defaults)
    end

    # Parse the options returning the options, you can pass a block that adds additional options
    # to the Optionparser.
    #
    # The sample below starts a parser that also prompts for --arguments in addition to the defaults.
    # It also sets the description and shows a usage message specific to this app.
    #
    #  options = oparser.parse{|parser, options|
    #       parser.define_head "Control the mcollective controller daemon"
    #       parser.banner = "Usage: sh-mcollective [options] command"
    #
    #       parser.on('--arg', '--argument ARGUMENT', 'Argument to pass to agent') do |v|
    #           options[:argument] = v
    #       end
    #  }
    #
    # Users can set default options that get parsed in using the MCOLLECTIVE_EXTRA_OPTS environemnt
    # variable
    def parse(&block)
      yield(@parser, @options) if block_given?

      add_required_options

      add_common_options unless @exclude.include?("common")

      @include.each do |i|
        next if @exclude.include?(i)

        options_name = "add_#{i}_options"
        send(options_name)  if respond_to?(options_name)
      end

      @parser.environment("MCOLLECTIVE_EXTRA_OPTS")

      @parser.parse!

      @options[:collective] = Config.instance.main_collective unless @options[:collective]

      @options
    end

    # These options will be added if you pass 'filter' into the include list of the
    # constructor.
    def add_filter_options
      @parser.separator ""
      @parser.separator "Host Filters"

      @parser.on('-W', '--with FILTER', 'Combined classes and facts filter') do |f|
        f.split(" ").each do |filter|
          begin
            fact_parsed = parse_fact(filter)
            @options[:filter]["fact"] << fact_parsed
          rescue
            @options[:filter]["cf_class"] << filter
          end
        end
      end

      @parser.on('-S', '--select FILTER', 'Compound filter combining facts and classes') do |f|
        @options[:filter]["compound"] << Matcher.create_compound_callstack(f)
      end

      @parser.on('-F', '--wf', '--with-fact fact=val', 'Match hosts with a certain fact') do |f|
        fact_parsed = parse_fact(f)

        @options[:filter]["fact"] << fact_parsed if fact_parsed
      end

      @parser.on('-C', '--wc', '--with-class CLASS', 'Match hosts with a certain config management class') do |f|
        @options[:filter]["cf_class"] << f
      end

      @parser.on('-A', '--wa', '--with-agent AGENT', 'Match hosts with a certain agent') do |a|
        @options[:filter]["agent"] << a
      end

      @parser.on('-I', '--wi', '--with-identity IDENT', 'Match hosts with a certain configured identity') do |a|
        @options[:filter]["identity"] << a
      end
    end

    # These options should always be present
    def add_required_options
      @parser.on('-c', '--config FILE', 'Load configuration from file rather than default') do |f|
        @options[:config] = f
      end

      @parser.on('-v', '--verbose', 'Be verbose') do |v|
        @options[:verbose] = v
      end

      @parser.on('-h', '--help', 'Display this screen') do
        puts @parser
        exit! 1
      end
    end

    # These options will be added to most cli tools
    def add_common_options
      @parser.separator ""
      @parser.separator "Common Options"

      @parser.on('-T', '--target COLLECTIVE', 'Target messages to a specific sub collective') do |f|
        @options[:collective] = f
      end

      @parser.on('--dt', '--discovery-timeout SECONDS', Integer, 'Timeout for doing discovery') do |t|
        @options[:disctimeout] = t
      end

      @parser.on('-t', '--timeout SECONDS', Integer, 'Timeout for calling remote agents') do |t|
        @options[:timeout] = t
      end

      @parser.on('-q', '--quiet', 'Do not be verbose') do |v|
        @options[:verbose] = false
      end

      @parser.on('--ttl TTL', 'Set the message validity period') do |v|
        @options[:ttl] = v.to_i
      end

      @parser.on('--reply-to TARGET', 'Set a custom target for replies') do |v|
        @options[:reply_to] = v
      end

      @parser.on('--dm', '--disc-method METHOD', 'Which discovery method to use') do |v|
        raise "Discovery method is already set by a competing option" if @options[:discovery_method] && @options[:discovery_method] != v
        @options[:discovery_method] = v
      end

      @parser.on('--do', '--disc-option OPTION', 'Options to pass to the discovery method') do |a|
        @options[:discovery_options] << a
      end

      @parser.on("--nodes FILE", "List of nodes to address") do |v|
        raise "Cannot mix --disc-method, --disc-option and --nodes" if @options[:discovery_method] || @options[:discovery_options].size > 0
        raise "Cannot read the discovery file #{v}" unless File.readable?(v)

        @options[:discovery_method] = "flatfile"
        @options[:discovery_options] << v
      end

      @parser.on("--publish_timeout TIMEOUT", Integer, "Timeout for publishing requests to remote agents.") do |pt|
        @options[:publish_timeout] = pt
      end

      @parser.on("--threaded", "Start publishing requests and receiving responses in threaded mode.") do |v|
        @options[:threaded] = true
      end

      @parser.on("--sort", "Sort the output of an RPC call before processing.") do |v|
        @options[:sort] = true
      end

      @parser.on("--connection-timeout TIMEOUT", Integer, "Set the timeout for establishing a connection to the middleware") do |v|
        @options[:connection_timeout] = Integer(v)
      end
    end

    private
    # Parse a fact filter string like foo=bar into the tuple hash thats needed
    def parse_fact(fact)
      Util.parse_fact_string(fact)
    end

  end
end
