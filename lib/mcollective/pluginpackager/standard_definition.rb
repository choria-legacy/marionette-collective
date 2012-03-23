module MCollective
  module PluginPackager
    class StandardDefinition
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
        @metadata = PluginPackager.get_metadata(@path, @plugintype)
        @metadata[:name] = name.downcase.gsub(" ", "_") if name
        identify_packages
      end

      # Identify present packages and populate the packagedata hash
      def identify_packages
        @packagedata[:common] = common
        @packagedata[@plugintype] = plugin
      end

      # Obtain standard plugin files and dependencies
      def plugin
        plugindata = {:files => [],
                      :dependencies => ["mcollective"],
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
                  :dependencies => ["mcolelctive-common"],
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
