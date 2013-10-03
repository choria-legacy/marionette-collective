module MCollective
  module Agent
    class Rpcutil<RPC::Agent
      # Basic system inventory, same as the basic discovery agent
      action "inventory" do
        reply[:agents] = Agents.agentlist
        reply[:facts] = PluginManager["facts_plugin"].get_facts
        reply[:version] = MCollective.version
        reply[:classes] = []
        reply[:main_collective] = config.main_collective
        reply[:collectives] = config.collectives
        reply[:data_plugins] = PluginManager.grep(/_data$/)

        cfile = Config.instance.classesfile
        if File.exist?(cfile)
          reply[:classes] = File.readlines(cfile).map {|i| i.chomp}
        end
      end

      # Retrieve a single fact from the node
      action "get_fact" do
        reply[:fact] = request[:fact]
        reply[:value] = Facts[request[:fact]]
      end 

      action "get_facts" do
        response = {}
        request[:facts].split(',').map { |x| x.strip }.each do |fact|
          value = Facts[fact]
          response[fact] = value
        end
        reply[:values] = response
      end

      # Get the global stats for this mcollectied
      action "daemon_stats" do
        stats = PluginManager["global_stats"].to_hash

        reply[:threads] = stats[:threads]
        reply[:agents] = stats[:agents]
        reply[:pid] = stats[:pid]
        reply[:times] = stats[:times]
        reply[:configfile] = Config.instance.configfile
        reply[:version] = MCollective.version

        reply.data.merge!(stats[:stats])
      end

      # Builds an inventory of all agents on teh machine
      # including license, version and timeout information
      action "agent_inventory" do
        reply[:agents] = []

        Agents.agentlist.sort.each do |target_agent|
          agent = PluginManager["#{target_agent}_agent"]
          actions = agent.methods.grep(/_agent/)

          agent_data = {:agent => target_agent,
                        :license => "unknown",
                        :timeout => agent.timeout,
                        :description => "unknown",
                        :name => target_agent,
                        :url => "unknown",
                        :version => "unknown",
                        :author => "unknown"}

          agent_data.merge!(agent.meta)

          reply[:agents] << agent_data
        end
      end

      # Retrieves a single config property that is in effect
      action "get_config_item" do
        reply.fail! "Unknown config property #{request[:item]}" unless config.respond_to?(request[:item])

        reply[:item] = request[:item]
        reply[:value] = config.send(request[:item])
      end

      # Responds to PING requests with the local timestamp
      action "ping" do
        reply[:pong] = Time.now.to_i
      end

      # Returns all configured collectives
      action "collective_info" do
        config = Config.instance
        reply[:main_collective] = config.main_collective
        reply[:collectives] = config.collectives
      end

      action "get_data" do
        if request[:query]
          query = Data.ddl_transform_input(Data.ddl(request[:source]), request[:query].to_s)
        else
          query = nil
        end

        data = Data[ request[:source] ].lookup(query)

        data.keys.each do |key|
          reply[key] = data[key]
        end
      end
    end
  end
end
