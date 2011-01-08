class MCollective::Application::Find<MCollective::Application
    description "Find hosts matching criteria"

    def main
        client = MCollective::Client.new(options[:config])
        client.options = options

        stats = client.req("ping", "discovery") do |resp|
            puts resp[:senderid]
        end

        client.disconnect

        client.display_stats(stats) if options[:verbose]
    end
end
