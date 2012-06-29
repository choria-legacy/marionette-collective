module MCollective
  module PluginPackager
    # MCollective Agent Plugin package
    class AgentDefinition
      attr_accessor :path, :packagedata, :metadata, :target_path, :vendor, :iteration, :preinstall
      attr_accessor :plugintype, :dependencies, :postinstall, :mcserver, :mcclient, :mccommon

      def initialize(path, name, vendor, preinstall, postinstall, iteration, dependencies, mcodependency, plugintype)
        @plugintype = plugintype
        @path = path
        @packagedata = {}
        @iteration = iteration || 1
        @preinstall = preinstall
        @postinstall = postinstall
        @vendor = vendor || "Puppet Labs"
        @mcserver = mcodependency[:server] || "mcollective"
        @mcclient = mcodependency[:client] || "mcollective-client"
        @mccommon = mcodependency[:common] || "mcollective-common"
        @dependencies = dependencies || []
        @target_path = File.expand_path(@path)
        @metadata = PluginPackager.get_metadata(@path, "agent")
        @metadata[:name] = (name || @metadata[:name]).downcase.gsub(" ", "-")
        identify_packages
      end

      # Identify present packages and populate packagedata hash.
      def identify_packages
        common_package = common
        @packagedata[:common] = common_package if common_package
        agent_package = agent
        @packagedata[:agent] = agent_package if agent_package
        client_package = client
        @packagedata[:client] = client_package if client_package
      end

      # Obtain Agent package files and dependencies.
      def agent
        agent = {:files => [],
                 :dependencies => @dependencies.clone << @mcserver,
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
        agent[:dependencies] << "mcollective-#{@metadata[:name]}-common"
        agent
      end

      # Obtain client package files and dependencies.
      def client
        client = {:files => [],
                  :dependencies => @dependencies.clone << @mcclient,
                  :description => "Client plugin for #{@metadata[:name]}"}

        clientdir = File.join(@path, "application")
        bindir = File.join(@path, "bin")
        aggregatedir = File.join(@path, "aggregate")

        client[:files] += Dir.glob(File.join(clientdir, "*")) if PluginPackager.check_dir_present clientdir
        client[:files] += Dir.glob(File.join(bindir,"*")) if PluginPackager.check_dir_present bindir
        client[:files] += Dir.glob(File.join(aggregatedir, "*")) if PluginPackager.check_dir_present aggregatedir
        client[:dependencies] << "mcollective-#{@metadata[:name]}-common"
        client[:files].empty? ? nil : client
      end

      # Obtain common package files and dependencies.
      def common
        common = {:files =>[],
                  :dependencies => @dependencies.clone << @mccommon,
                  :description => "Common libraries for #{@metadata[:name]}"}

        commondir = File.join(@path, "util")
        ddldir = File.join(@path, "agent")
        common[:files] += Dir.glob(File.join(ddldir, "*.ddl")) if PluginPackager.check_dir_present ddldir

        # We fail if there is no ddl file present
        if common[:files].empty?
          raise "cannot create package - No ddl file found in #{File.join(@path, "agent")}"
        end

        common[:files] += Dir.glob(File.join(commondir,"*")) if PluginPackager.check_dir_present commondir
        common[:files].empty? ? nil : common
      end
    end
  end
end
