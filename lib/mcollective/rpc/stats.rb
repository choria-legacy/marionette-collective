module MCollective
  module RPC
    # Class to wrap all the stats and to keep track of some timings
    class Stats
      attr_accessor :noresponsefrom, :starttime, :discoverytime, :blocktime, :responses, :totaltime
      attr_accessor :discovered, :discovered_nodes, :okcount, :failcount, :noresponsefrom, :responsesfrom
      attr_accessor :requestid, :aggregate_summary, :ddl, :aggregate_failures

      def initialize
        reset
      end

      # Resets stats, if discovery time is set we keep it as it was
      def reset
        @noresponsefrom = []
        @responsesfrom = []
        @responses = 0
        @starttime = Time.now.to_f
        @discoverytime = 0 unless @discoverytime
        @blocktime = 0
        @totaltime = 0
        @discovered = 0
        @discovered_nodes = []
        @okcount = 0
        @failcount = 0
        @noresponsefrom = []
        @requestid = nil
        @aggregate_summary = []
        @aggregate_failures = []
      end

      # returns a hash of our stats
      def to_hash
        {:noresponsefrom    => @noresponsefrom,
         :starttime         => @starttime,
         :discoverytime     => @discoverytime,
         :blocktime         => @blocktime,
         :responses         => @responses,
         :totaltime         => @totaltime,
         :discovered        => @discovered,
         :discovered_nodes  => @discovered_nodes,
         :okcount           => @okcount,
         :requestid         => @requestid,
         :failcount         => @failcount,
         :aggregate_summary => @aggregate_summary,
         :aggregate_failures => @aggregate_failures}
      end

      # Fake hash access to keep things backward compatible
      def [](key)
        to_hash[key]
      rescue
        nil
      end

      # increment the count of ok hosts
      def ok
        @okcount += 1
      rescue
        @okcount = 1
      end

      # increment the count of failed hosts
      def fail
        @failcount += 1
      rescue
        @failcount = 1
      end

      # Re-initializes the object with stats from the basic client
      def client_stats=(stats)
        @noresponsefrom = stats[:noresponsefrom]
        @responses = stats[:responses]
        @starttime = stats[:starttime]
        @blocktime = stats[:blocktime]
        @totaltime = stats[:totaltime]
        @requestid = stats[:requestid]
        @discoverytime = stats[:discoverytime] if @discoverytime == 0
      end

      # Utility to time discovery from :start to :end
      def time_discovery(action)
        if action == :start
          @discovery_start = Time.now.to_f
        elsif action == :end
          @discoverytime = Time.now.to_f - @discovery_start
        else
          raise("Uknown discovery action #{action}")
        end
      rescue
        @discoverytime = 0
      end

      # helper to time block execution time
      def time_block_execution(action)
        if action == :start
          @block_start = Time.now.to_f
        elsif action == :end
          @blocktime += Time.now.to_f - @block_start
        else
          raise("Uknown block action #{action}")
        end
      rescue
        @blocktime = 0
      end

      # Update discovered and discovered_nodes based on
      # discovery results
      def discovered_agents(agents)
        @discovered_nodes = agents
        @discovered = agents.size
      end

      # Helper to calculate total time etc
      def finish_request
        @totaltime = @blocktime + @discoverytime

        # figures out who we had no responses from
        dhosts = @discovered_nodes.clone
        @responsesfrom.each {|r| dhosts.delete(r)}
        @noresponsefrom = dhosts
      rescue
        @totaltime = 0
        @noresponsefrom = []
      end

      # Helper to keep track of who we received responses from
      def node_responded(node)
        @responsesfrom << node
      rescue
        @responsesfrom = [node]
      end

      def text_for_aggregates
        result = StringIO.new

        @aggregate_summary.each do |aggregate|
          output_item = aggregate.result[:output]

          begin
            action_interface = @ddl.action_interface(aggregate.action)
            display_as = action_interface[:output][output_item][:display_as]
          rescue
            display_as = output_item
          end

          if aggregate.is_a?(Aggregate::Result::Base)
            aggregate_report = aggregate.to_s
          else
            next
          end

          result.puts Util.colorize(:bold, "Summary of %s:" % display_as)
          result.puts
          unless aggregate_report == ""
            result.puts aggregate.to_s.split("\n").map{|x| "   " + x}.join("\n")
          else
            result.puts Util.colorize(:yellow, "     No aggregate summary could be computed")
          end
          result.puts
        end

        @aggregate_failures.each do |failed|
          case(failed[:type])
          when :startup
            message = "exception raised while processing startup hook"
          when :create
            message = "unspecified output '#{failed[:name]}' for the action"
          when :process_result
            message = "exception raised while processing result data"
          when :summarize
            message = "exception raised while summarizing"
          end

          result.puts Util.colorize(:bold, "Summary of %s:" % failed[:name])
          result.puts
          result.puts Util.colorize(:yellow, "     Could not compute summary - %s" % message)
          result.puts
        end

        result.string
      end

      # Returns a blob of text representing the request status based on the
      # stats contained in this class
      def report(caption = "rpc stats", summarize = true, verbose = false)
        result_text = []

        if verbose
            if @aggregate_summary.size > 0 && summarize
              result_text << text_for_aggregates
            else
              result_text << ""
            end

          result_text << Util.colorize(:yellow, "---- #{caption} ----")

          if @discovered
            @responses < @discovered ? color = :red : color = :reset
            result_text << "           Nodes: %s / %s" % [ Util.colorize(color, @discovered), Util.colorize(color, @responses) ]
          else
            result_text << "           Nodes: #{@responses}"
          end

          @failcount < 0 ? color = :red : color = :reset

          result_text << "     Pass / Fail: %s / %s" % [Util.colorize(color, @okcount), Util.colorize(color, @failcount) ]
          result_text << "      Start Time: %s"      % [Time.at(@starttime)]
          result_text << "  Discovery Time: %.2fms"  % [@discoverytime * 1000]
          result_text << "      Agent Time: %.2fms"  % [@blocktime * 1000]
          result_text << "      Total Time: %.2fms"  % [@totaltime * 1000]
        else
          if @discovered
            @responses < @discovered ? color = :red : color = :green

            if @aggregate_summary.size + @aggregate_failures.size > 0 && summarize
              result_text << text_for_aggregates
            else
              result_text << ""
            end

            result_text << "Finished processing %s / %s hosts in %.2f ms" % [Util.colorize(color, @responses), Util.colorize(color, @discovered), @blocktime * 1000]
          else
            result_text << "Finished processing %s hosts in %.2f ms" % [Util.colorize(:bold, @responses), @blocktime * 1000]
          end
        end

        if no_response_report != ""
          result_text << "" << no_response_report
        end

        result_text.join("\n")
      end

      # Returns a blob of text indicating what nodes did not respond
      def no_response_report
        result_text = StringIO.new

        if @noresponsefrom.size > 0
          result_text.puts
          result_text.puts Util.colorize(:red, "No response from:")
          result_text.puts

          field_size = Util.field_size(@noresponsefrom, 30)
          fields_num = Util.field_number(field_size)
          format = "   " + ( " %-#{field_size}s" * fields_num )

          @noresponsefrom.sort.in_groups_of(fields_num) do |c|
            result_text.puts format % c
          end

          result_text.puts
        end

        result_text.string
      end
    end
  end
end
