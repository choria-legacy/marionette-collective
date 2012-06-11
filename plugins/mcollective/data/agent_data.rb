module MCollective
  module Data
    class Agent_data<Base
      query do |plugin|
        raise "No agent called #{plugin} found" unless PluginManager.include?("#{plugin}_agent")

        agent = PluginManager["#{plugin}_agent"]

        result[:agent] = plugin

        [:license, :timeout, :description, :url, :version, :author].each do |item|
          result[item] = agent.meta[item]
        end
      end
    end
  end
end
