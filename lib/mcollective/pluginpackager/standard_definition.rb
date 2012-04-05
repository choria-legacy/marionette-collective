module MCollective
  module PluginPackager
    class StandardDefinition
      attr_accessor :path, :packagedata, :metadata, :target_path, :vendor, :iteration
      attr_accessor :plugintype, :preinstall, :postinstall, :dependencies, :mcserver
      attr_accessor :mccommon

      def initialize(path, name, vendor, preinstall, postinstall, iteration, dependencies, mcodependency, plugintype)
        @plugintype = plugintype
        @path = path
        @packagedata = {}
        @iteration = iteration || 1
        @preinstall = preinstall
        @postinstall = postinstall
        @vendor = vendor || "Puppet Labs"
        @dependencies = dependencies || []
        @mcserver = mcodependency[:server] || "mcollective"
        @mccommon = mcodependency[:common] || "mcollective-common"
        @target_path = File.expand_path(@path)
        @metadata = PluginPackager.get_metadata(@path, @plugintype)
        @metadata[:name] = (name || @metadata[:name]).downcase.gsub(" ", "-")
        identify_packages
      end

      # Identify present packages and populate the packagedata hash
      def identify_packages
        common_package = common
        @packagedata[:common] = common_package if common_package
        plugin_package = plugin
        @packagedata[@plugintype] = plugin_package if plugin_package
      end

      # Obtain standard plugin files and dependencies
      def plugin
        plugindata = {:files => [],
                      :dependencies => @dependencies.clone << @mcserver,
                      :description => "#{@name} #{@plugintype} plugin for the Marionette Collective."}

        plugindir = File.join(@path, @plugintype.to_s)
        if PluginPackager.check_dir_present plugindir
          plugindata[:files] = Dir.glob(File.join(plugindir, "*"))
        else
          return nil
        end

        plugindata[:dependencies] <<"mcollective-#{@metadata[:name]}-common" if @packagedata[:common]
        plugindata
      end

      # Obtain list of common files
      def common
        common = {:files => [],
                  :dependencies => @dependencies.clone << @mccommon,
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
