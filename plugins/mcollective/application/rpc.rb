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

  # As we're taking arguments on the command line we need a
  # way to input booleans, true on the cli is a string so this
  # method will take the ddl, find all arguments that are supposed
  # to be boolean and if they are the strings "true"/"yes" or "false"/"no"
  # turn them into the matching boolean
  def string_to_boolean(val)
    return true if ["true", "yes", "1"].include?(val)
    return false if ["false", "no", "0"].include?(val)

    raise "#{val} does not look like a boolean argument"
  end

  # a generic string to number function, if a number looks like a float
  # it turns it into a float else an int.  This is naive but should be sufficient
  # for numbers typed on the cli in most cases
  def string_to_number(val)
    return val.to_f if val =~ /^\d+\.\d+$/
    return val.to_i if val =~ /^\d+$/

    raise "#{val} does not look like a number"
  end

  def string_to_ddl_type(arguments, ddl)
    return if ddl.empty?

    arguments.keys.each do |key|
      if ddl[:input].keys.include?(key)
        begin
          case ddl[:input][key][:type]
            when :boolean
              arguments[key] = booleanish_to_boolean(arguments[key])

            when :number, :integer, :float
              arguments[key] = string_to_number(arguments[key])
          end
        rescue
          # just go on to the next key, DDL validation will figure out
          # any inconsistancies caused by exceptions when the request is made
        end
      end
    end
  end

  def main
    mc = rpcclient(configuration[:agent])

    mc.agent_filter(configuration[:agent])

    string_to_ddl_type(configuration[:arguments], mc.ddl.action_interface(configuration[:action])) unless mc.ddl.nil?

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

      printrpcstats :caption => "#{configuration[:agent]}##{configuration[:action]} call stats"

      halt mc.stats
    end
  end
end
