module MCollective
  module PluginPackager
    # Plugin definition classes
    autoload :AgentDefinition, "mcollective/pluginpackager/agent_definition"
    autoload :StandardDefinition, "mcollective/pluginpackager/standard_definition"

    # Package implementation plugins
    def self.load_packagers
      PluginManager.find_and_load("pluginpackager")
    end

    def self.[](klass)
      const_get("#{klass}")
    end

    def self.get_metadata(path, type)
      ddl = MCollective::RPC::DDL.new("package", false)
      ddl.instance_eval File.read(Dir.glob(File.join(path, type, "*.ddl")).first)
      ddl.meta
    end

    def self.check_dir_present(path)
      (File.directory?(path) && !Dir.glob(File.join(path, "*")).empty?)
    end
  end
end
