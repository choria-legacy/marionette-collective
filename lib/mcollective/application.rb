require 'mcollective/rpc'

module MCollective
  class Application
    include RPC

    class << self
      # Intialize a blank set of options if its the first time used
      # else returns active options
      def application_options
        intialize_application_options unless @application_options
        @application_options
      end

      # set an option in the options hash
      def []=(option, value)
        intialize_application_options unless @application_options
        @application_options[option] = value
      end

      # retrieves a specific option
      def [](option)
        intialize_application_options unless @application_options
        @application_options[option]
      end

      # Sets the application description, there can be only one
      # description per application so multiple calls will just
      # change the description
      def description(descr)
        self[:description] = descr
      end

      # Supplies usage information, calling multiple times will
      # create multiple usage lines in --help output
      def usage(usage)
        self[:usage] << usage
      end

      def exclude_argument_sections(*sections)
        sections = [sections].flatten

        sections.each do |s|
          raise "Unknown CLI argument section #{s}" unless ["rpc", "common", "filter"].include?(s)
        end

        intialize_application_options unless @application_options
        self[:exclude_arg_sections] = sections
      end

      # Wrapper to create command line options
      #
      #  - name: varaible name that will be used to access the option value
      #  - description: textual info shown in --help
      #  - arguments: a list of possible arguments that can be used
      #    to activate this option
      #  - type: a data type that ObjectParser understand of :bool or :array
      #  - required: true or false if this option has to be supplied
      #  - validate: a proc that will be called with the value used to validate
      #    the supplied value
      #
      #   option :foo,
      #          :description => "The foo option"
      #          :arguments   => ["--foo ARG"]
      #
      # after this the value supplied will be in configuration[:foo]
      def option(name, arguments)
        opt = {:name => name,
               :description => nil,
               :arguments => [],
               :type => String,
               :required => false,
               :validate => Proc.new { true }}

        arguments.each_pair{|k,v| opt[k] = v}

        self[:cli_arguments] << opt
      end

      # Creates an empty set of options
      def intialize_application_options
        @application_options = {:description          => nil,
                                :usage                => [],
                                :cli_arguments        => [],
                                :exclude_arg_sections => []}
      end
    end

    # The application configuration built from CLI arguments
    def configuration
      @application_configuration ||= {}
      @application_configuration
    end

    # The active options hash used for MC::Client and other configuration
    def options
      @options
    end

    # Calls the supplied block in an option for validation, an error raised
    # will log to STDERR and exit the application
    def validate_option(blk, name, value)
      validation_result = blk.call(value)

      unless validation_result == true
        STDERR.puts "Validation of #{name} failed: #{validation_result}"
        exit 1
      end
    end

    # Creates a standard options hash, pass in a block to add extra headings etc
    # see Optionparser
    def clioptions(help)
      oparser = Optionparser.new({:verbose => false, :progress_bar => true}, "filter", application_options[:exclude_arg_sections])

      options = oparser.parse do |parser, options|
        if block_given?
          yield(parser, options)
        end

        RPC::Helpers.add_simplerpc_options(parser, options) unless application_options[:exclude_arg_sections].include?("rpc")
      end

      return oparser.parser.help if help

      validate_cli_options

      post_option_parser(configuration) if respond_to?(:post_option_parser)

      return options
    rescue Exception => e
      application_failure(e)
    end

    # Builds an ObjectParser config, parse the CLI options and validates based
    # on the option config
    def application_parse_options(help=false)
      @options ||= {:verbose => false}

      @options = clioptions(help) do |parser, options|
        parser.define_head application_description if application_description
        parser.banner = ""

        if application_usage
          parser.separator ""

          application_usage.each do |u|
            parser.separator "Usage: #{u}"
          end

          parser.separator ""
        end

        parser.separator "Application Options" unless application_cli_arguments.empty?

        parser.define_tail ""
        parser.define_tail "The Marionette Collective #{MCollective.version}"


        application_cli_arguments.each do |carg|
          opts_array = []

          opts_array << :on

          # if a default is set from the application set it up front
          if carg.include?(:default)
            configuration[carg[:name]] = carg[:default]
          end

          # :arguments are multiple possible ones
          if carg[:arguments].is_a?(Array)
            carg[:arguments].each {|a| opts_array << a}
          else
            opts_array << carg[:arguments]
          end

          # type was given and its not one of our special types, just pass it onto optparse
          opts_array << carg[:type] if carg[:type] && ![:boolean, :bool, :array].include?(carg[:type])

          opts_array << carg[:description]

          # Handle our special types else just rely on the optparser to handle the types
          if [:bool, :boolean].include?(carg[:type])
            parser.send(*opts_array) do |v|
              validate_option(carg[:validate], carg[:name], v)

              configuration[carg[:name]] = v
            end

          elsif carg[:type] == :array
            parser.send(*opts_array) do |v|
              validate_option(carg[:validate], carg[:name], v)

              configuration[carg[:name]] = [] unless configuration.include?(carg[:name])
              configuration[carg[:name]] << v
            end

          else
            parser.send(*opts_array) do |v|
              validate_option(carg[:validate], carg[:name], v)

              configuration[carg[:name]] = v
            end
          end
        end
      end
    end

    def validate_cli_options
      # Check all required parameters were set
      validation_passed = true
      application_cli_arguments.each do |carg|
        # Check for required arguments
        if carg[:required]
          unless configuration[ carg[:name] ]
            validation_passed = false
            STDERR.puts "The #{carg[:name]} option is mandatory"
          end
        end
      end

      unless validation_passed
        STDERR.puts "\nPlease run with --help for detailed help"
        exit 1
      end


    end

    # Retrieves the full hash of application options
    def application_options
      self.class.application_options
    end

    # Retrieve the current application description
    def application_description
      application_options[:description]
    end

    # Return the current usage text false if nothing is set
    def application_usage
      usage = application_options[:usage]

      usage.empty? ? false : usage
    end

    # Returns an array of all the arguments built using
    # calls to optin
    def application_cli_arguments
      application_options[:cli_arguments]
    end

    # Handles failure, if we're far enough in the initialization
    # phase it will log backtraces if its in verbose mode only
    def application_failure(e, err_dest=STDERR)
      # peole can use exit() anywhere and not get nasty backtraces as a result
      if e.is_a?(SystemExit)
        disconnect
        raise(e)
      end

      if options[:verbose]
        err_dest.puts "\nThe %s application failed to run: %s\n" % [ Util.colorize(:bold, $0), Util.colorize(:red, e.to_s)]
      else
        err_dest.puts "\nThe %s application failed to run, use -v for full error backtrace details: %s\n" % [ Util.colorize(:bold, $0), Util.colorize(:red, e.to_s)]
      end

      if options.nil? || options[:verbose]
        e.backtrace.first << Util.colorize(:red, "  <----")
        err_dest.puts "\n%s %s" % [ Util.colorize(:red, e.to_s), Util.colorize(:bold, "(#{e.class.to_s})")]
        e.backtrace.each{|l| err_dest.puts "\tfrom #{l}"}
      end

      disconnect

      exit 1
    end

    def help
      application_parse_options(true)
    end

    # The main logic loop, builds up the options, validate configuration and calls
    # the main as supplied by the user.  Disconnects when done and pass any exception
    # onto the application_failure helper
    def run
      application_parse_options

      validate_configuration(configuration) if respond_to?(:validate_configuration)

      Util.setup_windows_sleeper if Util.windows?

      main

      disconnect

    rescue Exception => e
      application_failure(e)
    end

    def disconnect
      MCollective::PluginManager["connector_plugin"].disconnect
    rescue
    end

    # Fake abstract class that logs if the user tries to use an application without
    # supplying a main override method.
    def main
      STDERR.puts "Applications need to supply a 'main' method"
      exit 1
    end

    def halt_code(stats)
      request_stats = {:discoverytime => 0,
                       :discovered => 0,
                       :okcount => 0,
                       :failcount => 0}.merge(stats.to_hash)

      if (request_stats[:discoverytime] == 0 && request_stats[:responses] == 0)
        return 4
      end

      if (request_stats[:discovered] > 0)
        if (request_stats[:responses] == 0)
          return 3
        elsif (request_stats[:failcount] > 0)
          return 2
        end
      end

      if (request_stats[:discovered] == 0)
        if (request_stats[:responses] && request_stats[:responses] > 0)
          return 0
        else
          return 1
        end
      end

      return 0
    end

    # A helper that creates a consistent exit code for applications by looking at an
    # instance of MCollective::RPC::Stats
    #
    # Exit with 0 if nodes were discovered and all passed
    # Exit with 0 if no discovery were done and > 0 responses were received, all ok
    # Exit with 1 if no nodes were discovered
    # Exit with 2 if nodes were discovered but some RPC requests failed
    # Exit with 3 if nodes were discovered, but no responses received
    # Exit with 4 if no discovery were done and no responses were received
    def halt(stats)
      exit(halt_code(stats))
    end

    # Wrapper around MC::RPC#rpcclient that forcably supplies our options hash
    # if someone forgets to pass in options in an application the filters and other
    # cli options wouldnt take effect which could have a disasterous outcome
    def rpcclient(agent, flags = {})
      flags[:options] = options unless flags.include?(:options)
      flags[:exit_on_failure] = false

      super
    end
  end
end
