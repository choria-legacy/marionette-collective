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
            #      :description => "The foo option"
            #      :arguments   => ["--foo ARG"]
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
                @application_options = {:description   => nil,
                                        :usage         => [],
                                        :cli_arguments => []}
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

        # Builds an ObjectParser config, parse the CLI options and validates based
        # on the option config
        def application_parse_options
            @options = rpcoptions do |parser, options|
                parser.define_head application_description if application_description
                parser.banner = ""

                if application_usage
                    parser.separator ""

                    application_usage.each do |u|
                        parser.separator "Usage: #{u}"
                    end

                    parser.separator ""
                end

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
                    opts_array << carg[:type] if carg[:type] and ! [:bool, :array].include?(carg[:type])

                    opts_array << carg[:description]

                    # Handle our special types else just rely on the optparser to handle the types
                    if carg[:type] == :bool
                        parser.send(*opts_array) do |v|
                            validate_option(carg[:validate], carg[:name], v)

                            configuration[carg[:name]] = true
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

            post_option_parser(configuration) if respond_to?(:post_option_parser)
        rescue Exception => e
            application_failure(e)
        end

        # Retrieve the current application description
        def application_description
            self.class.application_options[:description]
        end

        # Return the current usage text false if nothing is set
        def application_usage
            usage = self.class.application_options[:usage]

            usage.empty? ? false : usage
        end

        # Returns an array of all the arguments built using
        # calls to optin
        def application_cli_arguments
            self.class.application_options[:cli_arguments]
        end

        # Handles failure, if we're far enough in the initialization
        # phase it will log backtraces if its in verbose mode only
        def application_failure(e)
            STDERR.puts "#{$0} failed to run: #{e} (#{e.class})"

            if options
                e.backtrace.each{|l| STDERR.puts "\tfrom #{l}"} if options[:verbose]
            else
                e.backtrace.each{|l| STDERR.puts "\tfrom #{l}"}
            end

            MCollective::PluginManager["connector_plugin"].disconnect rescue true

            exit 1
        end

        # The main logic loop, builds up the options, validate configuration and calls
        # the main as supplied by the user.  Disconnects when done and pass any exception
        # onto the application_failure helper
        def run
            application_parse_options

            validate_configuration(configuration) if respond_to?(:validate_configuration)

            main

            MCollective::PluginManager["connector_plugin"].disconnect rescue true

        rescue SystemExit
            raise
        rescue Exception => e
            application_failure(e)
        end

        # Fake abstract class that logs if the user tries to use an application without
        # supplying a main override method.
        def main
            STDERR.puts "Applications need to supply a 'main' method"
            exit 1
        end

        # Wrapper around MC::RPC#rpcclient that forcably supplies our options hash
        # if someone forgets to pass in options in an application the filters and other
        # cli options wouldnt take effect which could have a disasterous outcome
        def rpcclient(agent, flags = {})
            flags[:options] = options unless flags.include?(:options)

            super
        end
    end
end
