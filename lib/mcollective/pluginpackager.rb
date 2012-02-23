module MCollective
  module PluginPackager
    # Plugin definition classes
    autoload :AgentDefinition, "mcollective/pluginpackager/agent_definition"

    # Package implementation plugins
    def self.load_packagers
      PluginManager.find_and_load("pluginpackager")
    end

    def self.[](klass)
      const_get("#{klass}")
    end
  end
end
