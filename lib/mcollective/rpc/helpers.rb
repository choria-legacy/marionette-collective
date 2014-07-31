module MCollective
  module RPC
    # Various utilities for the RPC system
    class Helpers
      # Parse JSON output as produced by printrpc and extract
      # the "sender" of each rpc response
      #
      # The simplist valid JSON based data would be:
      #
      # [
      #  {"sender" => "example.com"},
      #  {"sender" => "another.com"}
      # ]
      def self.extract_hosts_from_json(json)
        hosts = JSON.parse(json)

        raise "JSON hosts list is not an array" unless hosts.is_a?(Array)

        hosts.map do |host|
          raise "JSON host list is not an array of Hashes" unless host.is_a?(Hash)
          raise "JSON host list does not have senders in it" unless host.include?("sender")

          host["sender"]
        end.uniq
      end

      # Given an array of something, make sure each is a string
      # chomp off any new lines and return just the array of hosts
      def self.extract_hosts_from_array(hosts)
        [hosts].flatten.map do |host|
          raise "#{host} should be a string" unless host.is_a?(String)
          host.chomp
        end
      end

      # Returns a blob of text representing the results in a standard way
      #
      # It tries hard to do sane things so you often
      # should not need to write your own display functions
      #
      # If the agent you are getting results for has a DDL
      # it will use the hints in there to do the right thing specifically
      # it will look at the values of display in the DDL to choose
      # when to show results
      #
      # If you do not have a DDL you can pass these flags:
      #
      #    printrpc exim.mailq, :flatten => true
      #    printrpc exim.mailq, :verbose => true
      #
      # If you've asked it to flatten the result it will not print sender
      # hostnames, it will just print the result as if it's one huge result,
      # handy for things like showing a combined mailq.
      def self.rpcresults(result, flags = {})
        flags = {:verbose => false, :flatten => false, :format => :console, :force_display_mode => false}.merge(flags)

        result_text = ""
        ddl = nil

        # if running in verbose mode, just use the old style print
        # no need for all the DDL helpers obfuscating the result
        if flags[:format] == :json
          if STDOUT.tty?
            result_text = JSON.pretty_generate(result)
          else
            result_text = result.to_json
          end
        else
          if flags[:verbose]
            result_text = old_rpcresults(result, flags)
          else
            [result].flatten.each do |r|
              begin
                ddl ||= DDL.new(r.agent).action_interface(r.action.to_s)

                sender = r[:sender]
                status = r[:statuscode]
                message = r[:statusmsg]
                result = r[:data]

                if flags[:force_display_mode]
                  display = flags[:force_display_mode]
                else
                  display = ddl[:display]
                end

                # appand the results only according to what the DDL says
                case display
                  when :ok
                    if status == 0
                      result_text << text_for_result(sender, status, message, result, ddl)
                    end

                  when :failed
                    if status > 0
                      result_text << text_for_result(sender, status, message, result, ddl)
                    end

                  when :always
                    result_text << text_for_result(sender, status, message, result, ddl)

                  when :flatten
                    Log.warn("The display option :flatten is being deprecated and will be removed in the next minor release")
                    result_text << text_for_flattened_result(status, result)

                end
              rescue Exception => e
                # no DDL so just do the old style print unchanged for
                # backward compat
                result_text = old_rpcresults(result, flags)
              end
            end
          end
        end

        result_text
      end

      # Return text representing a result
      def self.text_for_result(sender, status, msg, result, ddl)
        statusses = ["",
                     Util.colorize(:red, "Request Aborted"),
                     Util.colorize(:yellow, "Unknown Action"),
                     Util.colorize(:yellow, "Missing Request Data"),
                     Util.colorize(:yellow, "Invalid Request Data"),
                     Util.colorize(:red, "Unknown Request Status")]

        result_text = "%-40s %s\n" % [sender, statusses[status]]
        result_text << "   %s\n" % [Util.colorize(:yellow, msg)] unless msg == "OK"

        # only print good data, ignore data that results from failure
        if status == 0
          if result.is_a?(Hash)
            # figure out the lengths of the display as strings, we'll use
            # it later to correctly justify the output
            lengths = result.keys.map do |k|
              begin
                ddl[:output][k][:display_as].size
              rescue
                k.to_s.size
              end
            end

            result.keys.sort_by{|k| k}.each do |k|
              # get all the output fields nicely lined up with a
              # 3 space front padding
              begin
                display_as = ddl[:output][k][:display_as]
              rescue
                display_as = k.to_s
              end

              display_length = display_as.size
              padding = lengths.max - display_length + 3
              result_text << " " * padding

              result_text << "#{display_as}:"

              if [String, Numeric].include?(result[k].class)
                lines = result[k].to_s.split("\n")

                if lines.empty?
                  result_text << "\n"
                else
                  lines.each_with_index do |line, i|
                    i == 0 ? padtxt = " " : padtxt = " " * (padding + display_length + 2)

                    result_text << "#{padtxt}#{line}\n"
                  end
                end
              else
                padding = " " * (lengths.max + 5)
                result_text << " " << result[k].pretty_inspect.split("\n").join("\n" << padding) << "\n"
              end
            end
          elsif status == 1
            # for status 1 we dont want to show half baked
            # data by default since the DDL will supply all the defaults
            # it just doesnt look right
          else
            result_text << "\n\t" + result.pretty_inspect.split("\n").join("\n\t")
          end
        end

        result_text << "\n"
        result_text
      end

      # Returns text representing a flattened result of only good data
      def self.text_for_flattened_result(status, result)
        result_text = ""

        if status <= 1
          unless result.is_a?(String)
            result_text << result.pretty_inspect
          else
            result_text << result
          end
        end
      end

      # Backward compatible display block for results without a DDL
      def self.old_rpcresults(result, flags = {})
        result_text = ""

        if flags[:flatten]
          result.each do |r|
            if r[:statuscode] <= 1
              data = r[:data]

              unless data.is_a?(String)
                result_text << data.pretty_inspect
              else
                result_text << data
              end
            else
              result_text << r.pretty_inspect
            end
          end

          result_text << ""
        else
          [result].flatten.each do |r|

            if flags[:verbose]
              result_text << "%-40s: %s\n" % [r[:sender], r[:statusmsg]]

              if r[:statuscode] <= 1
                r[:data].pretty_inspect.split("\n").each {|m| result_text += "    #{m}"}
                result_text << "\n\n"
              elsif r[:statuscode] == 2
                # dont print anything, no useful data to display
                # past what was already shown
              elsif r[:statuscode] == 3
                # dont print anything, no useful data to display
                # past what was already shown
              elsif r[:statuscode] == 4
                # dont print anything, no useful data to display
                # past what was already shown
              else
                result_text << "    #{r[:statusmsg]}"
              end
            else
              unless r[:statuscode] == 0
                result_text << "%-40s %s\n" % [r[:sender], Util.colorize(:red, r[:statusmsg])]
              end
            end
          end
        end

        result_text << ""
      end

      # Add SimpleRPC common options
      def self.add_simplerpc_options(parser, options)
        parser.separator ""
        parser.separator "RPC Options"

        # add SimpleRPC specific options to all clients that use our library
        parser.on('--np', '--no-progress', 'Do not show the progress bar') do |v|
          options[:progress_bar] = false
        end

        parser.on('--one', '-1', 'Send request to only one discovered nodes') do |v|
          options[:mcollective_limit_targets] = 1
        end
    
        parser.on('--batch SIZE', 'Do requests in batches') do |v|
          # validate batch string. Is it x% where x > 0 or is it an integer
          if ((v =~ /^(\d+)%$/ && Integer($1) != 0) || v =~ /^(\d+)$/)
            options[:batch_size] = v
          else
            raise(::OptionParser::InvalidArgument.new(v))
          end
        end

        parser.on('--batch-sleep SECONDS', Float, 'Sleep time between batches') do |v|
          options[:batch_sleep_time] = v
        end

        parser.on('--limit-seed NUMBER', Integer, 'Seed value for deterministic random batching') do |v|
          options[:limit_seed] = v
        end

        parser.on('--limit-nodes COUNT', '--ln', '--limit', 'Send request to only a subset of nodes, can be a percentage') do |v|
          raise "Invalid limit specified: #{v} valid limits are /^\d+%*$/" unless v =~ /^\d+%*$/

          if v =~ /^\d+$/
            options[:mcollective_limit_targets] = v.to_i
          else
            options[:mcollective_limit_targets] = v
          end
        end

        parser.on('--json', '-j', 'Produce JSON output') do |v|
          options[:progress_bar] = false
          options[:output_format] = :json
        end

        parser.on('--display MODE', 'Influence how results are displayed. One of ok, all or failed') do |v|
          if v == "all"
            options[:force_display_mode] = :always
          else
            options[:force_display_mode] = v.intern
          end

          raise "--display has to be one of 'ok', 'all' or 'failed'" unless [:ok, :failed, :always].include?(options[:force_display_mode])
        end
      end
    end
  end
end
