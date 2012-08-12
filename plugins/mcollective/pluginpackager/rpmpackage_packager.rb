module MCollective
  module PluginPackager
    class RpmpackagePackager

      require 'erb'
      attr_accessor :plugin, :tmpdir, :verbose, :libdir, :workingdir
      attr_accessor :current_package_type, :current_package_data
      attr_accessor :current_package_name, :signature

      def initialize(plugin, pluginpath = nil, signature = nil, verbose = false)
        if(PluginPackager.build_tool?("rpmbuild-md5"))
          @buildtool = "rpmbuild-md5"
        elsif(PluginPackager.build_tool?("rpmbuild"))
          @buildtool = "rpmbuild"
        else
          raise RuntimeError, "creating rpms require 'rpmbuild' or 'rpmbuild-md5' to be installed"
        end
              
        @plugin = plugin
        @verbose = verbose
        @libdir = pluginpath || "/usr/libexec/mcollective/mcollective/"
        @signature = signature
      end

      def create_packages
        @plugin.packagedata.each do |type, data|
          begin
            @current_package_type = type
            @current_package_data = data
            @current_package_name = "mcollective-#{@plugin.metadata[:name]}-#{@current_package_type}"
            @tmpdir = Dir.mktmpdir("mcollective_packager")
            prepare_tmpdirs data
            create_package type, data
          rescue Exception => e
            raise e
          ensure
            cleanup_tmpdirs
          end
        end
      end

      def create_package(type, data)
        begin
          make_spec_file
          PluginPackager.do_quietly?(@verbose) do
            PluginPackager.safe_system("rpmbuild -ba #{"--quiet" unless verbose} #{"--sign" if @signature} #{File.join(@tmpdir, "SPECS", "#{type}.spec")} --buildroot #{File.join(@tmpdir, "BUILD")}")
          end

          FileUtils.cp(File.join(`rpm --eval '%_rpmdir'`.chomp, "noarch", "#{@current_package_name}-#{@plugin.metadata[:version]}-#{@plugin.iteration}.noarch.rpm"), ".")
          FileUtils.cp(File.join(`rpm --eval '%_srcrpmdir'`.chomp, "#{@current_package_name}-#{@plugin.metadata[:version]}-#{@plugin.iteration}.src.rpm"), ".")
          puts "Created RPM and SRPM packages for #{@current_package_name}"
        rescue Exception => e
          raise RuntimeError, "Could not build package. Reason - #{e}"
        end
      end

      def make_spec_file
        begin
          spec_template = ERB.new(File.read(File.join(File.dirname(__FILE__), "templates", "redhat", "rpm_spec.erb")), nil, "-")
          File.open(File.join(@tmpdir, "SPECS", "#{@current_package_type}.spec"), "w") do |f|
            f.puts spec_template.result(binding)
          end
        rescue Exception => e
          raise RuntimeError, "Could not create specfile - #{e}"
        end
      end

      def prepare_tmpdirs(data)
        make_rpm_dirs
        data[:files].each do |file|
          targetdir = File.join(@tmpdir, "BUILD", @libdir, File.dirname(File.expand_path(file)).gsub(@plugin.target_path, ""))
          FileUtils.mkdir_p(targetdir) unless File.directory? targetdir
          FileUtils.cp_r(file, targetdir)
        end
      end

      def make_rpm_dirs
        ["BUILD", "SOURCES", "SPECS", "SRPMS", "RPMS"].each do |dir|
          begin
            FileUtils.mkdir(File.join(@tmpdir, dir))
          rescue Exception => e
            raise RuntimeError, "Could not create #{dir} directory - #{e}"
          end
        end
      end

      def cleanup_tmpdirs
        FileUtils.rm_r @tmpdir if File.directory? @tmpdir
      end
    end
  end
end
