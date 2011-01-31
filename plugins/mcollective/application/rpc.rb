class MCollective::Application::Rpc<MCollective::Application
    description "Generic RPC agent client application"

    usage "mc-rpc [options] [filters] --agent <agent> --action <action> [--argument <key=val> --argument ...]"
    usage "mc-rpc [options] [filters] <agent> <action> [<key=val> <key=val> ...]"

    option :no_results,
        :description    => "Do not process results, just send request",
        :arguments      => ["--no-results", "--nr"],
        :default        => false,
        :type           => :bool

    option :agent,
        :description    => "Agent to call",
        :arguments      => ["-a", "--agent AGENT"]

    option :action,
        :description    => "Action to call",
        :arguments      => ["--action ACTION"]

    option :arguments,
        :description    => "Arguments to pass to agent",
        :arguments      => ["--arg", "--argument ARGUMENT"],
        :type           => :array,
        :default        => [],
        :validate       => Proc.new {|val| val.match(/^(.+?)=(.+)$/) ? true : "Could not parse --arg #{val} should be of the form key=val" }

    def post_option_parser(configuration)
        # handle the alternative format that optparse cant parse
        unless (configuration.include?(:agent) && configuration.include?(:action))
            if ARGV.length >= 2
                configuration[:agent] = ARGV[0]
                ARGV.delete_at(0)

                configuration[:action] = ARGV[0]
                ARGV.delete_at(0)

                ARGV.each do |v|
                    if v =~ /^(.+?)=(.+)$/
                        configuration[:arguments] = [] unless configuration.include?(:arguments)
                        configuration[:arguments] << v
                    else
                        STDERR.puts("Could not parse --arg #{v}")
                    end
                end
            else
                STDERR.puts("No agent, action and arguments specified")
                exit!
            end
        end

        # convert arguments to symbols for keys to comply with simplerpc conventions
        args = configuration[:arguments].clone
        configuration[:arguments] = {}

        args.each do |v|
            if v =~ /^(.+?)=(.+)$/
                configuration[:arguments][$1.to_sym] = $2
            end
        end
    end

    # As we're taking arguments on the command line we need a
    # way to input booleans, true on the cli is a string so this
    # method will take the ddl, find all arguments that are supposed
    # to be boolean and if they are the strings "true"/"yes" or "false"/"no"
    # turn them into the matching boolean
    def booleanish_to_boolean(arguments, ddl)
        arguments.keys.each do |key|
            if ddl[:input].keys.include?(key)
                if ddl[:input][key][:type] == :boolean
                    arguments[key] = true if arguments[key] == "true"
                    arguments[key] = true if arguments[key] == "yes"
                    arguments[key] = true if arguments[key] == "1"
                    arguments[key] = false if arguments[key] == "false"
                    arguments[key] = false if arguments[key] == "no"
                    arguments[key] = false if arguments[key] == "0"
                end
            end
        end
    end

    def main
        if configuration[:no_results]
            configuration[:arguments][:process_results] = false

            mc = rpcclient(configuration[:agent], {:options => options})

            booleanish_to_boolean(configuration[:arguments], mc.ddl.action_interface(configuration[:action])) unless mc.ddl.nil?

            mc.agent_filter(configuration[:agent])

            puts "Request sent with id: " + mc.send(configuration[:action], configuration[:arguments])

            mc.disconnect
        else
            mc = rpcclient(configuration[:agent], {:options => options})

            booleanish_to_boolean(configuration[:arguments], mc.ddl.action_interface(configuration[:action])) unless mc.ddl.nil?

            mc.agent_filter(configuration[:agent])
            mc.discover :verbose => true

            printrpc mc.send(configuration[:action], configuration[:arguments])

            printrpcstats :caption => "#{configuration[:agent]}##{configuration[:action]} call stats"

            mc.disconnect
        end
    end
end
