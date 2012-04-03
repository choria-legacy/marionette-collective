module MCollective
  module PluginPackager
    # MCollective Agent Plugin package
    class AgentDefinition
      attr_accessor :path, :packagedata, :metadata, :target_path, :vendor, :iteration, :postinstall
      attr_accessor :plugintype

      def initialize(path, name, vendor, postinstall, iteration, plugintype)
        @plugintype = plugintype
        @path = path
        @packagedata = {}
        @iteration = iteration || 1
        @postinstall = postinstall
        @vendor = vendor || "Puppet Labs"
        @target_path = File.expand_path(@path)
        @metadata = PluginPackager.get_metadata(@path, "agent")
        @metadata[:name] = (name || @metadata[:name]).downcase.gsub(" ", "_")
        identify_packages
      end

      # Identify present packages and populate packagedata hash.
      def identify_packages
        @packagedata[:common] = common
        @packagedata[:agent] = agent
        @packagedata[:client] = client
      end

      # Obtain Agent package files and dependencies.
      def agent
        agent = {:files => [],
                 :dependencies => ["mcollective"],
                 :description => "Agent plugin for #{@metadata[:name]}"}

        agentdir = File.join(@path, "agent")

        if PluginPackager.check_dir_present agentdir
          ddls = Dir.glob(File.join(agentdir, "*.ddl"))
          agent[:files] = (Dir.glob(File.join(agentdir, "*")) - ddls)
          implementations = Dir.glob(File.join(@metadata[:name], "**"))
          agent[:files] += implementations unless implementations.empty?
        else
          return nil
        end

        agent[:dependencies] << "mcollective-#{@metadata[:name]}-common" if @packagedata[:common]
        agent
      end

      # Obtain client package files and dependencies.
      def client
        client = {:files => [],
                  :dependencies => ["mcollective-client"],
                  :description => "Client plugin for #{@metadata[:name]}"}

        clientdir = File.join(@path, "application")
        bindir = File.join(@path, "bin")
        ddldir = File.join(@path, "agent")

        client[:files] += Dir.glob(File.join(clientdir, "*")) if PluginPackager.check_dir_present clientdir
        client[:files] += Dir.glob(File.join(bindir,"*")) if PluginPackager.check_dir_present bindir
        client[:files] += Dir.glob(File.join(ddldir, "*.ddl")) if PluginPackager.check_dir_present ddldir
        client[:dependencies] << "mcollective-#{@metadata[:name]}-common" if @packagedata[:common]
        client[:files].empty? ? nil : client
      end

      # Obtain common package files and dependencies.
      def common
        common = {:files =>[],
                  :dependencies => ["mcollective-common"],
                  :description => "Common libraries for #{@metadata[:name]}"}

        commondir = File.join(@path, "util")
        common[:files] += Dir.glob(File.join(commondir,"*")) if PluginPackager.check_dir_present commondir
        common[:files].empty? ? nil : common
      end

    end
  end
end
