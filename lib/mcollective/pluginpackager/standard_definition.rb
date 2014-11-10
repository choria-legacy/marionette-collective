module MCollective
  module PluginPackager
    class StandardDefinition
      attr_accessor :path, :packagedata, :metadata, :target_path, :vendor, :revision
      attr_accessor :plugintype, :preinstall, :postinstall, :dependencies, :mcname, :mcversion

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
        @metadata, mcversion = PluginPackager.get_metadata(@path, @plugintype)
        @mcname = mcdependency[:mcname] || "mcollective"
        @mcversion = mcdependency[:mcversion] || mcversion
        @dependencies << {:name => "#{mcname}-common", :version => @mcversion}
        @metadata[:name] = (configuration[:pluginname] || @metadata[:name]).downcase.gsub(/\s+|_/, "-")
        @metadata[:version] = (configuration[:version] || @metadata[:version])
        identify_packages
      end

      # Identify present packages and populate the packagedata hash
      def identify_packages
        common_package = common
        @packagedata[:common] = common_package if common_package
        plugin_package = plugin
        @packagedata[@plugintype.to_sym] = plugin_package if plugin_package
      end

      # Obtain standard plugin files and dependencies
      def plugin
        plugindata = {:files => [],
                      :dependencies => @dependencies.clone,
                      :description => "#{@name} #{@plugintype} plugin for the Marionette Collective."}

        plugindir = File.join(@path, @plugintype.to_s)
        if PluginPackager.check_dir_present plugindir
          plugindata[:files] = Dir.glob(File.join(plugindir, "*"))
        else
          return nil
        end

        plugindata[:plugindependency] = {:name => "#{@mcname}-#{@metadata[:name]}-common",
                                      :version => @metadata[:version],
                                      :revision => @revision} if @packagedata[:common]
        plugindata
      end

      # Obtain list of common files
      def common
        common = {:files => [],
                  :dependencies => @dependencies.clone,
                  :description => "Common libraries for #{@name} connector plugin"}

        commondir = File.join(@path, "util")
        if PluginPackager.check_dir_present commondir
          common[:files] = Dir.glob(File.join(commondir, "*"))
          return common
        else
          return nil
        end
      end
    end
  end
end
