module MCollective
  module PluginPackager
    class RpmpackagePackager
      require 'erb'

      def initialize(plugin, pluginpath = nil, signature = nil, verbose = false, keep_artifacts = nil, module_template = nil)
        if @buildtool = select_command
          @plugin = plugin
          @package_name = "#{@plugin.mcname}-#{@plugin.metadata[:name]}"
          @package_name_and_version = "#{@package_name}-#{@plugin.metadata[:version]}"
          @verbose = verbose
          @libdir = pluginpath || '/usr/libexec/mcollective/mcollective/'
          @signature = signature
          @rpmdir = rpmdir
          @srpmdir = srpmdir
          @keep_artifacts = keep_artifacts
        else
          raise("Cannot build package. 'rpmbuild' or 'rpmbuild-md5' is not present on the system")
        end
      end

      # Determine the build tool present on the system
      def select_command
        if PluginPackager.command_available?('rpmbuild-md5')
          return 'rpmbuild-md5'
        elsif PluginPackager.command_available?('rpmbuild')
          return 'rpmbuild'
        else
          return nil
        end
      end

      def rpmdir
        `rpm --eval '%_rpmdir'`.chomp
      end

      def srpmdir
        `rpm --eval '%_srcrpmdir'`.chomp
      end

      # Build Process :
      # - create temporary buildroot
      # - create the spec file
      # - create the tarball
      # - run the build script
      # - move pacakges to cwd
      # - clean up
      def create_packages
        begin
          puts "Building packages for #{@package_name} plugin."

          @tmpdir = Dir.mktmpdir('mcollective_packager')
          prepare_tmpdirs

          make_spec_file
          run_build
          move_packages

          puts "Completed building all packages for #{@package_name} plugin."
        ensure
          if @keep_artifacts
            puts 'Keeping build artifacts'
            puts "Build artifacts saved - #{@tmpdir}"
          else
            cleanup_tmpdirs
          end
        end
      end

      private

      def run_build
        begin
          tarfile = create_tar
          PluginPackager.execute_verbosely(@verbose) do
            PluginPackager.safe_system("#{@buildtool} -ta#{" --quiet" unless @verbose}#{" --sign" if @signature} #{tarfile}")
          end
        rescue => e
          puts 'Build process has failed'
          raise e
        end
      end

      # Tar up source
      # Expects directory $mcollective-$agent-$version
      # Creates file : $tmpbuildroot/$mcollective-$agent-$version
      def create_tar
        tarfile = File.join(@tmpdir, "#{@package_name_and_version}.tgz")
        begin
         PluginPackager.execute_verbosely(@verbose) do
            Dir.chdir(@tmpdir) do
              PluginPackager.safe_system("tar -cvzf #{tarfile} #{@package_name_and_version}")
            end
          end
        rescue => e
          puts "Could not create tarball - '#{tarfile}'"
          raise e
        end
        tarfile
      end

      # Move rpm's and srpm's to cwd
      def move_packages
        begin
          files_to_copy = []
          files_to_copy += Dir.glob(File.join(@rpmdir, 'noarch', "#{@package_name}-*-#{@plugin.metadata[:version]}-#{@plugin.revision}*.noarch.rpm"))
          files_to_copy += Dir.glob(File.join(@srpmdir, "#{@package_name}-#{@plugin.metadata[:version]}-#{@plugin.revision}*.src.rpm"))
          FileUtils.cp(files_to_copy, '.')
        rescue => e
          puts 'Could not copy packages to working directory'
          raise e
        end
      end

      # Create the specfile and place as $tmpbuildroot/$mcollective-$agent-$version/$mcollective-$agent-$version.spec
      def make_spec_file
        spec_file = File.join(@tmpdir, @package_name_and_version, "#{@package_name_and_version}.spec")
        begin
          spec_template = ERB.new(File.read(File.join(File.dirname(__FILE__), 'templates', 'redhat', 'rpm_spec.erb')), nil, '-')
          File.open(spec_file, 'w') do |f|
            f.puts spec_template.result(binding)
          end
        rescue => e
          puts "Could not create specfile - '#{spec_file}'"
          raise e
        end
      end

      # Move files contained in the plugin to the correct directory
      # relative to the build root.
      def prepare_tmpdirs
        plugin_files.each do |file|
          begin
            targetdir = File.join(@tmpdir, @package_name_and_version, @libdir, File.dirname(File.expand_path(file)).gsub(@plugin.target_path, ""))
            FileUtils.mkdir_p(targetdir) unless File.directory?(targetdir)
            FileUtils.cp_r(file, targetdir)
          rescue Errno::EACCES => e
            puts "Could not create directory '#{targetdir}'. Permission denied"
            raise e
          rescue Errno::ENOENT => e
            puts "Could not copy file '#{file}' to '#{targetdir}'. File does not exist"
            raise e
          rescue => e
            puts 'Could not prepare temporary build directory'
            raise e
          end
        end
      end

      # Extract all the package files from the plugin's package data hash
      def plugin_files
        files = []
        @plugin.packagedata.each do |name, data|
          files += data[:files].reject{ |f| File.directory?(f) }
        end
        files
      end

      # Extract the package specific files from the file list and omits directories
      def package_files(files)
        package_files = []
        files.each do |f|
          if !File.directory?(f)
            package_files << File.join(@libdir, File.expand_path(f).gsub(/#{@plugin.target_path}|\.\//, ''))
          end
        end
        package_files
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
