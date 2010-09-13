module MCollective
    module Agent
        class Rpcutil<RPC::Agent
            metadata    :name        => "Utilities and Helpers for SimpleRPC Agents",
                        :description => "General helpful actions that expose stats and internals to SimpleRPC clients", 
                        :author      => "R.I.Pienaar <rip@devco.net>",
                        :license     => "Apache License, Version 2.0",
                        :version     => "1.0",
                        :url         => "http://marionette-collective.org/",
                        :timeout     => 3

            # Basic system inventory, same as the basic discovery agent
            action "inventory" do
                reply[:agents] = Agents.agentlist
                reply[:facts] = PluginManager["facts_plugin"].get_facts
                reply[:classes] = []

                cfile = Config.instance.classesfile
                if File.exist?(cfile)
                    reply[:classes] = File.readlines(cfile).map {|i| i.chomp}
                end
            end

            # Retrieve a single fact from the node
            action "get_fact" do
                validate :fact, String

                reply[:fact] = request[:fact]
                reply[:value] = Facts[request[:fact]]
            end

            # Get the global stats for this mcollectied
            action "daemon_stats" do
                stats = PluginManager["global_stats"].to_hash

                reply[:threads] = stats[:threads]
                reply[:agents] = stats[:agents]
                reply[:pid] = stats[:pid]
                reply[:times] = stats[:times]
                reply[:configfile] = Config.instance.configfile

                reply.data.merge!(stats[:stats])
            end

            # Builds an inventory of all agents on teh machine
            # including license, version and timeout information
            action "agent_inventory" do
                reply[:agents] = []

                Agents.agentlist.sort.each do |target_agent|
                    agent = PluginManager["#{target_agent}_agent"]
                    actions = agent.methods.grep(/_agent/)

                    agent_data = {:agent => target_agent}
                    agent_data.merge!(agent.meta)

                    reply[:agents] << agent_data
                end
            end
        end
    end
end
