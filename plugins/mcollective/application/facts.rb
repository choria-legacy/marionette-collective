class MCollective::Application::Facts<MCollective::Application
    description "Reports on usage for a specific fact"

    def post_option_parser(configuration)
        configuration[:fact] = ARGV.shift if ARGV.size > 0
    end

    def validate_configuration(configuration)
        raise "Please specify a fact to report for" unless configuration.include?(:fact)
    end

    def show_single_fact_report(fact, facts, verbose=false)
        puts("Report for fact: #{fact}\n\n")

        facts.keys.sort.each do |k|
            printf("        %-40sfound %d times\n", k, facts[k].size)

            if verbose
                puts

                facts[k].sort.each do |f|
                    puts("            #{f}")
                end

                puts
            end
        end
    end

    def main
        rpcutil = rpcclient("rpcutil", :options => options)
        rpcutil.progress = false

        facts = {}

        rpcutil.get_fact(:fact => configuration[:fact]) do |resp|
            begin
                value = resp[:body][:data][:value]
                if value
                    facts.include?(value) ? facts[value] << resp[:senderid] : facts[value] = [ resp[:senderid] ]
                end
            rescue Exception => e
                STDERR.puts "Could not parse facts for #{resp[:senderid]}: #{e.class}: #{e}"
            end
        end

        show_single_fact_report(configuration[:fact], facts, options[:verbose])

        printrpcstats
    end
end
