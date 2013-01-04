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
        @rpmdir = `rpm --eval '%_rpmdir'`.chomp
        @srpmdir = `rpm --eval '%_srcrpmdir'`.chomp
      end

      def rpmdir
        `rpm --eval '%_rpmdir'`.chomp
      end

      def srpmdir
        `rpm --eval '%_srcrpmdir'`.chomp
      end

      def create_packages
        @plugin.packagedata.each do |type, data|
          begin
            @current_package_type = type
            @current_package_data = data
            @current_package_name = "#{@plugin.mcname}-#{@plugin.metadata[:name]}-#{@current_package_type}"
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
          tarfile = "#{@current_package_name}-#{@plugin.metadata[:version]}.tgz"
          make_spec_file
          PluginPackager.do_quietly?(verbose) do
            Dir.chdir(@tmpdir) do
              PluginPackager.safe_system("tar -cvzf #{File.join(@tmpdir, tarfile)} #{@current_package_name}-#{@plugin.metadata[:version]}")
            end

            PluginPackager.safe_system("#{@buildtool} -ta #{"--quiet" unless verbose} #{"--sign" if @signature} #{File.join(@tmpdir, tarfile)}")
          end

          FileUtils.cp(File.join(@rpmdir, "noarch", "#{@current_package_name}-#{@plugin.metadata[:version]}-#{@plugin.iteration}.noarch.rpm"), ".")
          FileUtils.cp(File.join(@srpmdir, "#{@current_package_name}-#{@plugin.metadata[:version]}-#{@plugin.iteration}.src.rpm"), ".")

          puts "Created RPM and SRPM packages for #{@current_package_name}"
        rescue Exception => e
          raise RuntimeError, "Could not build package. Reason - #{e}"
        end
      end

      def make_spec_file
        begin
          spec_template = ERB.new(File.read(File.join(File.dirname(__FILE__), "templates", "redhat", "rpm_spec.erb")), nil, "-")
          File.open(File.join(@tmpdir, "#{@current_package_name}-#{@plugin.metadata[:version]}" ,"#{@current_package_name}-#{@plugin.metadata[:version]}.spec"), "w") do |f|
            f.puts spec_template.result(binding)
          end
        rescue Exception => e
          raise RuntimeError, "Could not create specfile - #{e}"
        end
      end

      def prepare_tmpdirs(data)
        data[:files].each do |file|
          targetdir = File.join(@tmpdir, "#{@current_package_name}-#{@plugin.metadata[:version]}", @libdir, File.dirname(File.expand_path(file)).gsub(@plugin.target_path, ""))
          FileUtils.mkdir_p(targetdir) unless File.directory? targetdir
          FileUtils.cp_r(file, targetdir)
        end
      end

      def cleanup_tmpdirs
        FileUtils.rm_r @tmpdir if File.directory? @tmpdir
      end
    end
  end
end
