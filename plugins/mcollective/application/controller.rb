require 'pp'

module MCollective
    class Application::Controller < Application
        description "Control the mcollective daemon"

        usage <<-END_OF_USAGE
mco controller [OPTIONS] [FILTERS] <COMMAND> [--argument <ARGUMENT>]

The COMMAND can be one of the following:

    stats         - retrieve statistics from the mcollectived
    reload_agent  - reloads an agent, requires an agent name as argument
    reload_agents - reloads all agents
        END_OF_USAGE

        option :argument,
            :description => "Argument to pass to an agent",
            :arguments   => [ '-a', '--arg', '--argument ARGUMENT' ],
            :type        => String

        def print_statistics(sender, statistics)
            printf("%40s> total=%d, replies=%d, valid=%d, invalid=%d, " +
                "filtered=%d, passed=%d\n", sender,
                statistics[:total], statistics[:replies],
                statistics[:validated], statistics[:unvalidated],
                statistics[:filtered], statistics[:passed])
        end

        def post_option_parser(configuration)
            configuration[:command] = ARGV.shift if ARGV.size > 0
        end

        def validate_configuration(configuration)
            unless configuration.include?(:command)
                raise "Please specify a command and optional arguments"
            end

            #
            # When asked to restart an agent we need to make sure that
            # we have this agent name and set appropriate filters ...
            #
            if configuration[:command].match(/^reload_agent$/)
                unless configuration.include?(:argument)
                    raise "Please specify an agent name to reload with --argument"
                end

                options[:filter]['agent'] << configuration[:argument]
            end
        end

        def main
            client = MCollective::Client.new(options[:config])
            client.options = options

            counter = 0

            command = configuration[:command]
            command += " #{configuration[:argument]}" if configuration[:argument]

            statistics = client.discovered_req(command, 'mcollective') do |response|
                next unless response

                counter += 1

                sender = response[:senderid]
                body   = response[:body]

                case command
                    when /^stats$/
                        print_statistics(sender, body[:stats])
                    when /^reload_agent(?:.+)/
                        printf("%40s> %s\n", sender, body)
                    else
                        if options[:verbose]
                            puts "#{sender}>"
                            pp body
                        else
                            puts if counter % 4 == 1
                            print "#{sender} "
                        end
                end
            end

            client.disconnect

            client.display_stats(statistics, false, "mcollectived controller summary")
        end
    end
end

# vim: set ts=4 sw=4 et :
