module MCollective
  module PluginPackager
    class DebpackagePackager
      require 'erb'

      def initialize(plugin, pluginpath = nil, signature = nil, verbose = false, keep_artifacts = nil, module_template = nil)
        if PluginPackager.command_available?('debuild')
          @plugin = plugin
          @verbose = verbose
          @libdir = pluginpath || '/usr/share/mcollective/plugins/mcollective/'
          @signature = signature
          @package_name = "#{@plugin.mcname}-#{@plugin.metadata[:name]}"
          @keep_artifacts = keep_artifacts
        else
          raise("Cannot build package. 'debuild' is not present on the system.")
        end
      end

      # Build process :
      # - create buildroot
      # - craete buildroot/debian
      # - create the relative directories with package contents
      # - create install files for each of the plugins that are going to be built
      # - create debian build files
      # - create tarball
      # - create pre and post install files
      # - run the build script
      # - move packages to cwd
      # - clean up
      def create_packages
        begin
          puts "Building packages for #{@package_name} plugin."

          @tmpdir = Dir.mktmpdir('mcollective_packager')
          @build_dir = File.join(@tmpdir, "#{@package_name}_#{@plugin.metadata[:version]}")
          Dir.mkdir(@build_dir)

          create_debian_dir
          @plugin.packagedata.each do |type, data|
            prepare_tmpdirs(data)
            create_install_file(type, data)
            create_pre_and_post_install(type)
          end
          create_debian_files
          create_tar
          run_build
          move_packages

          puts "Completed building all packages for #{@package_name} plugin."
        ensure
          if @keep_artifacts
            puts 'Keeping build artifacts.'
            puts "Build artifacts saved - #{@tmpdir}"
          else
            puts 'Removing build artifacts.'
            cleanup_tmpdirs
          end
        end
      end

      private

      def create_debian_files
        ['control', 'Makefile', 'compat', 'rules', 'copyright', 'changelog'].each do |f|
          create_file(f)
        end
      end

      def run_build
        FileUtils.cd(@build_dir) do
          PluginPackager.execute_verbosely(@verbose) do
            if @signature
              if @signature.is_a?(String)
                PluginPackager.safe_system("debuild --no-lintian -i -k#{@signature}")
              else
                PluginPackager.safe_system("debuild --no-lintian -i")
              end
            else
              PluginPackager.safe_system("debuild --no-lintian -i -us -uc")
            end
          end
        end
      end

      # Creates a string used by the control file to specify dependencies
      # Dependencies can be formatted as :
      # foo (>= x.x-x)
      # foo (>= x.x)
      # foo
      def build_dependency_string(data)
        dependencies = []
        PluginPackager.filter_dependencies('debian', data[:dependencies]).each do |dep|
          if dep[:version] && dep[:revision]
            dependencies << "#{dep[:name]} (>=#{dep[:version]}-#{dep[:revision]}) | puppet-agent"
          elsif dep[:version]
            dependencies << "#{dep[:name]} (>=#{dep[:version]}) | puppet-agent"
          else
            dependencies << "#{dep[:name]} | puppet-agent"
          end
        end

        if data[:plugindependency]
          dependencies << "#{data[:plugindependency][:name]} (= ${binary:Version})"
        end

        dependencies.join(', ')
      end

      # Creates an install file for each of the packages that are going to be created
      # for the plugin
      def create_install_file(type, data)
        install_file = "#{@package_name}-#{type}"
        begin
          install_file = File.join(@build_dir, 'debian', "#{install_file}.install")
          File.open(install_file, 'w') do |file|
            data[:files].each do |f|
              extended_filename = File.join(@libdir, File.expand_path(f).gsub(/^#{@plugin.target_path}/, ''))
              file.puts "#{extended_filename} #{File.dirname(extended_filename)}"
            end
          end
        rescue Errno::EACCES => e
          puts "Could not create install file '#{install_file}'. Permission denied"
          raise e
        rescue => e
          puts "Could not create install file '#{install_file}'."
          raise e
        end
      end

      # Move source package and debs to cwd
      def move_packages
        begin
          files_to_copy = Dir.glob(File.join(@tmpdir, '*.{deb,dsc,diff.gz,orig.tar.gz,changes}'))
          FileUtils.cp(files_to_copy, '.')
        rescue => e
          puts 'Could not copy packages to working directory.'
          raise e
        end
      end

      # Create pre and post install files in $buildroot/debian
      # from supplied scripts.
      # Note that all packages built for the plugin will invoke
      # the same pre and post install scripts.
      def create_pre_and_post_install(type)
        if @plugin.preinstall
          if !File.exists?(@plugin.preinstall)
            puts "pre-install script '#{@plugin.preinstall}' not found."
            raise(Errno::ENOENT, @plugin.preinstall)
          else
            FileUtils.cp(@plugin.preinstall, File.join(@build_dir, 'debian', "#{@package_name}-#{type}.preinst"))
          end
        end

        if @plugin.postinstall
          if !File.exists?(@plugin.postinstall)
            puts "post-install script '#{@plugin.postinstall}' not found."
            raise(Errno::ENOENT, @plugin.postinstall)
          else
            FileUtils.cp(@plugin.postinstall, File.join(@build_dir, 'debian', "#{@package_name}-#{type}.postinst"))
          end
        end
      end

      # Tar up source
      # Expects directory : $mcollective-$agent_$version
      # Creates file : $buildroot/$mcollective-$agent_$version.orig.tar.gz
      def create_tar
        name_and_version = "#{@package_name}_#{@plugin.metadata[:version]}"
        tarfile = "#{name_and_version}.orig.tar.gz"
        begin
          PluginPackager.execute_verbosely(@verbose) do
            Dir.chdir(@tmpdir) do
              PluginPackager.safe_system("tar -Pcvzf #{File.join(@tmpdir, tarfile)} #{name_and_version}")
            end
          end
        rescue Exception => e
          puts "Could not create tarball - #{tarfile}"
          raise e
        end
      end

      def create_file(filename)
        begin
          file = ERB.new(File.read(File.join(File.dirname(__FILE__), 'templates', 'debian', "#{filename}.erb")), nil, '-')
          File.open(File.join(@build_dir, 'debian', filename), 'w') do |f|
            f.puts file.result(binding)
          end
        rescue => e
          puts "Could not create file - '#{filename}'"
          raise e
        end
      end

      # Move files contained in the plugin to the correct directory
      # relative to the build root.
      def prepare_tmpdirs(data)
        data[:files].each do |file|
          begin
            targetdir = File.join(@build_dir, @libdir, File.dirname(File.expand_path(file)).gsub(/^#{@plugin.target_path}/, ""))
            FileUtils.mkdir_p(targetdir) unless File.directory?(targetdir)
            FileUtils.cp_r(file, targetdir)
          rescue Errno::EACCES => e
            puts "Could not create directory '#{targetdir}'. Permission denied"
            raise e
          rescue Errno::ENOENT => e
            puts "Could not copy file '#{file}' to '#{targetdir}'. File does not exist"
            raise e
          rescue => e
            puts 'Could not prepare build directory'
            raise e
          end
        end
      end

      # Create the $buildroot/debian directory
      def create_debian_dir
        deb_dir = File.join(@build_dir, 'debian')
        begin
          FileUtils.mkdir_p(deb_dir)
        rescue => e
          puts "Could not create directory '#{deb_dir}'"
          raise e
        end
      end

      def cleanup_tmpdirs
        begin
          FileUtils.rm_r(@tmpdir) if File.directory?(@tmpdir)
        rescue => e
          puts "Could not remove temporary build directory - '#{@tmpdir}'"
          raise e
        end
      end
    end
  end
end
