module MCollective
  module PluginPackager
    # MCollective Agent Plugin package
    class AgentDefinition
      attr_accessor :path, :packagedata, :metadata, :target_path, :vendor, :revision, :preinstall
      attr_accessor :plugintype, :dependencies, :postinstall, :mcname, :mcversion

      def initialize(configuration, mcdependency, plugintype)
        @plugintype = plugintype
        @path = PluginPackager.get_plugin_path(configuration[:target])
        @packagedata = {}
        @revision = configuration[:revision] || 1
        @preinstall = configuration[:preinstall]
        @postinstall = configuration[:postinstall]
        @vendor = configuration[:vendor] || "Puppet Labs"
        @dependencies = configuration[:dependency] || []
        @target_path = File.expand_path(@path)
        @metadata, mcversion = PluginPackager.get_metadata(@path, "agent")
        @mcname = mcdependency[:mcname] ||  "mcollective"
        @mcversion = mcdependency[:mcversion] || mcversion
        @metadata[:version] = (configuration[:version] || @metadata[:version])
        @dependencies << {:name => "#{@mcname}-common", :version => @mcversion}
        @metadata[:name] = (configuration[:pluginname] || @metadata[:name]).downcase.gsub(/\s+|_/, "-")
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
                 :dependencies => @dependencies.clone,
                 :description => "Agent plugin for #{@metadata[:name]}"}

        agentdir = File.join(@path, "agent")

        if (PluginPackager.check_dir_present(agentdir))
          ddls = Dir.glob(File.join(agentdir, "*.ddl"))
          agent[:files] = (Dir.glob(File.join(agentdir, "**", "**")) - ddls)
        else
          return nil
        end
        agent[:plugindependency] = {:name => "#{@mcname}-#{@metadata[:name]}-common", :version => @metadata[:version], :revision => @revision}
        agent
      end

      # Obtain client package files and dependencies.
      def client
        client = {:files => [],
                  :dependencies => @dependencies.clone,
                  :description => "Client plugin for #{@metadata[:name]}"}

        clientdir = File.join(@path, "application")
        aggregatedir = File.join(@path, "aggregate")

        client[:files] += Dir.glob(File.join(clientdir, "*")) if PluginPackager.check_dir_present clientdir
        client[:files] += Dir.glob(File.join(aggregatedir, "*")) if PluginPackager.check_dir_present aggregatedir
        client[:plugindependency] = {:name => "#{@mcname}-#{@metadata[:name]}-common", :version => @metadata[:version], :revision => @revision}
        client[:files].empty? ? nil : client
      end

      # Obtain common package files and dependencies.
      def common
        common = {:files =>[],
                  :dependencies => @dependencies.clone,
                  :description => "Common libraries for #{@metadata[:name]}"}

        datadir = File.join(@path, "data", "**")
        utildir = File.join(@path, "util", "**", "**")
        ddldir = File.join(@path, "agent", "*.ddl")
        validatordir = File.join(@path, "validator", "**")

        [datadir, utildir, validatordir, ddldir].each do |directory|
          common[:files] += Dir.glob(directory)
        end

        # We fail if there is no ddl file present
        if common[:files].grep(/^.*\.ddl$/).empty?
          raise "cannot create package - No ddl file found in #{File.join(@path, "agent")}"
        end

        common[:files].empty? ? nil : common
      end
    end
  end
end
