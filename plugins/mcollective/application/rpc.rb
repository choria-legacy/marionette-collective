class MCollective::Application::Rpc<MCollective::Application
  description "Generic RPC agent client application"

  usage "mco rpc [options] [filters] --agent <agent> --action <action> [--argument <key=val> --argument ...]"
  usage "mco rpc [options] [filters] <agent> <action> [<key=val> <key=val> ...]"

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

  def string_to_ddl_type(arguments, ddl)
    return if ddl.empty?

    arguments.keys.each do |key|
      if ddl[:input].keys.include?(key)
        case ddl[:input][key][:type]
          when :boolean
            arguments[key] = MCollective::DDL.string_to_boolean(arguments[key])

          when :number, :integer, :float
            arguments[key] = MCollective::DDL.string_to_number(arguments[key])
        end
      end
    end
  end

  def main
    mc = rpcclient(configuration[:agent])

    mc.agent_filter(configuration[:agent])

    string_to_ddl_type(configuration[:arguments], mc.ddl.action_interface(configuration[:action])) if mc.ddl

    if mc.reply_to
      configuration[:arguments][:process_results] = true

      puts "Request sent with id: " + mc.send(configuration[:action], configuration[:arguments]) + " replies to #{mc.reply_to}"
    elsif configuration[:no_results]
      configuration[:arguments][:process_results] = false

      puts "Request sent with id: " + mc.send(configuration[:action], configuration[:arguments])
    else
      # if there's stuff on STDIN assume its JSON that came from another
      # rpc or printrpc, we feed that in as discovery data
      discover_args = {:verbose => true}

      unless STDIN.tty?
        discovery_data = STDIN.read.chomp
        discover_args = {:json => discovery_data} unless discovery_data == ""
      end

      mc.discover discover_args

      printrpc mc.send(configuration[:action], configuration[:arguments])

      printrpcstats :summarize => true, :caption => "#{configuration[:agent]}##{configuration[:action]} call stats" if mc.discover.size > 0

      halt mc.stats
    end
  end
end
