module MCollective
  module PluginPackager
    # MCollective plugin packager general OS implementation.
    class OspackagePackager

      attr_accessor :package, :verbose, :packager, :package_type

      # Create packager object with package parameter containing list of files,
      # dependencies and package metadata.
      def initialize(package, pluginpath = nil, signature = nil, verbose = false, keep_artifacts = false, module_template = nil)

        if File.exists?("/etc/redhat-release")
          @packager = PluginPackager["RpmpackagePackager"].new(package, pluginpath, signature, verbose, keep_artifacts, module_template)
          @package_type = "RPM"
        elsif File.exists?("/etc/debian_version")
          @packager = PluginPackager["DebpackagePackager"].new(package, pluginpath, signature, verbose, keep_artifacts, module_template)
          @package_type = "Deb"
        else
          raise "cannot identify operating system."
        end

        @package = package
        @verbose = verbose
      end

      # Hands over package creation to the detected packager implementation
      # based on operating system.
      def create_packages
        @packager.create_packages
      end

      # Displays the package metadata and detected files
      def package_information
        puts
        puts "%30s%s" % ["Plugin information : ", @package.metadata[:name]]
        puts "%30s%s" % ["-" * 22, "-" * 22]
        puts "%30s%s" % ["Plugin Type : ", @package.plugintype.capitalize]
        puts "%30s%s" % ["Package Output Format : ", @package_type]
        puts "%30s%s" % ["Version : ", @package.metadata[:version]]
        puts "%30s%s" % ["Revision : ", @package.revision]
        puts "%30s%s" % ["Vendor : ", @package.vendor]
        puts "%30s%s" % ["Post Install Script : ", @package.postinstall] if @package.postinstall
        puts "%30s%s" % ["Author : ", @package.metadata[:author]]
        puts "%30s%s" % ["License : ", @package.metadata[:license]]
        puts "%30s%s" % ["URL : ", @package.metadata[:url]]

        if @package.packagedata.size > 0
          @package.packagedata.each_with_index do |values, i|
            if i == 0
              puts "%30s%s" % ["Identified Packages : ", values[0]]
            else
              puts "%30s%s" % [" ", values[0]]
            end
          end
        end
      end
    end
  end
end
