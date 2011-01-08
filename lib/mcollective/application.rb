module MCollective
    class Application
        include RPC

        class << self
            def application_options
                intialize_application_options unless @application_options
                @application_options
            end

            def []=(option, value)
                intialize_application_options unless @application_options
                @application_options[option] = value
            end

            def [](option)
                intialize_application_options unless @application_options
                @application_options[option]
            end

            def description(descr)
                self[:description] = descr
            end

            def usage(usage)
                self[:usage] << usage
            end

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

            def intialize_application_options
                @application_options = {:description   => nil,
                                        :usage         => [],
                                        :cli_arguments => []}
            end
        end

        def configuration
            @application_configuration ||= {}
            @application_configuration
        end

        def options
            @options
        end

        def validate_option(blk, name, value)
            validation_result = blk.call(value)

            unless validation_result == true
                STDERR.puts "Validation of #{name} failed: #{validation_result}"
                exit! 1
            end
        end

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
                exit! 1
            end

            post_option_parser(configuration) if respond_to?(:post_option_parser)
        rescue Exception => e
            application_failure(e)
        end

        def application_description
            self.class.application_options[:description]
        end

        def application_usage
            usage = self.class.application_options[:usage]

            usage.empty? ? false : usage
        end

        def application_cli_arguments
            self.class.application_options[:cli_arguments]
        end

        def application_failure(e)
            STDERR.puts "#{$0} failed to run: #{e} (#{e.class})"

            if options
                e.backtrace.each{|l| STDERR.puts "\tfrom #{l}"} if options[:verbose]
            else
                e.backtrace.each{|l| STDERR.puts "\tfrom #{l}"}
            end

            exit! 1
        end

        def run
            application_parse_options

            validate_configuration(configuration) if respond_to?(:validate_configuration)

            main
        rescue Exception => e
            application_failure(e)
        end

        # abstract
        def main
            STDERR.puts "Applications need to supply a 'main' method"
            exit 1
        end
    end
end
