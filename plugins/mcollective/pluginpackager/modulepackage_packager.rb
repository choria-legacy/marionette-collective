module MCollective
  module PluginPackager
    class ModulepackagePackager
      require 'erb'

      def initialize(plugin, pluginpath = nil, signature = nil, verbose = false, keep_artifacts = nil, module_template = nil)
        assert_new_enough_puppet
        @plugin = plugin
        @package_name = "#{@plugin.mcname}_#{@plugin.metadata[:name]}".gsub(/-/, '_')
        @verbose = verbose
        @keep_artifacts = keep_artifacts
        @module_template = module_template || File.join(File.dirname(__FILE__), 'templates', 'module')
      end

      # Build Process :
      # - create module directory
      # - run 'puppet module build'
      # - move generated package back to cwd
      def create_packages
        begin
          puts "Building module for #{@package_name} plugin."

          @tmpdir = Dir.mktmpdir('mcollective_packager')
          make_module
          run_build
          move_package

          puts "Completed building module for #{@package_name} plugin."
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

      def assert_new_enough_puppet
        unless PluginPackager.command_available?('puppet')
          raise("Cannot build package. 'puppet' is not present on the system.")
        end

        s = Shell.new('puppet --version')
        s.runcommand
        actual_version = s.stdout.chomp

        required_version = '3.3.0'
        if Util.versioncmp(actual_version, required_version) < 0
          raise("Cannot build package. puppet #{required_version} or greater required.  We have #{actual_version}.")
        end
      end

      def make_module
        targetdir = File.join(@tmpdir, 'manifests')
        FileUtils.mkdir_p(targetdir) unless File.directory?(targetdir)

        # for each subpackage make a subclass
        @plugin.packagedata.each do |klass,data|
          data[:files].each do |file|
            relative_path = File.expand_path(file).gsub(/#{@plugin.target_path}|^\.\//, '')
            targetdir = File.join(@tmpdir, 'files', klass.to_s, 'mcollective', File.dirname(relative_path))
            FileUtils.mkdir_p(targetdir) unless File.directory?(targetdir)
            FileUtils.cp_r(file, targetdir)
          end

          @klass = klass.to_s
          render_template('_manifest.pp.erb', File.join(@tmpdir, 'manifests', "#{klass}.pp"))
        end

        # render all the templates we have
        Dir.glob(File.join(@module_template, '*.erb')).each do |template|
          filename = File.basename(template, '.erb')
          next if filename =~ /^_/ # starting with underscore makes it private
          render_template("#{filename}.erb", File.join(@tmpdir, filename))
        end
      end

      def render_template(template, path)
        begin
          erb = ERB.new(File.read(File.join(@module_template, template)), nil, '-')
          File.open(path, 'w') do |f|
            f.puts erb.result(binding)
          end
        rescue => e
          puts "Could not render template to path - '#{path}'"
          raise e
        end
      end

      def run_build
        begin
          PluginPackager.execute_verbosely(@verbose) do
            Dir.chdir(@tmpdir) do
              PluginPackager.safe_system('puppet module build')
            end
          end
        rescue => e
          puts 'Build process has failed'
          raise e
        end
      end

      # Move built package to cwd
      def move_package
        begin
          package_file = File.join(@tmpdir, 'pkg', "#{@plugin.vendor}-#{@package_name}-#{@plugin.metadata[:version]}.tar.gz")
          FileUtils.cp(package_file, '.')
        rescue => e
          puts 'Could not copy package to working directory'
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
