module MCollective
  module PluginPackager
    class DebpackagePackager

      require 'erb'
      attr_accessor :plugin, :current_package, :tmpdir, :verbose, :libdir
      attr_accessor :workingdir, :preinstall, :postinstall, :current_package_type
      attr_accessor :current_package_data, :current_package_shortname
      attr_accessor :current_package_fullname, :build_dir, :signature

      def initialize(plugin, pluginpath = nil, signature = nil, verbose = false)
        raise RuntimeError, "package 'debuild' is not installed" unless PluginPackager.build_tool?("debuild")
        @plugin = plugin
        @verbose = verbose
        @libdir = pluginpath || "/usr/share/mcollective/plugins/mcollective/"
        @signature = signature
        @tmpdir = ""
        @build_dir = ""
        @targetdir = ""
      end

      def create_packages
        @plugin.packagedata.each do |type, data|
          begin
            @tmpdir = Dir.mktmpdir("mcollective_packager")
            @current_package_type = type
            @current_package_data = data
            @current_package_shortname = "mcollective-#{@plugin.metadata[:name]}-#{@current_package_type}"
            @current_package_fullname = "mcollective-#{@plugin.metadata[:name]}-#{@current_package_type}" +
                                        "_#{@plugin.metadata[:version]}-#{@plugin.iteration}"

            @build_dir = File.join(@tmpdir, "#{@current_package_shortname}_#{@plugin.metadata[:version]}")
            Dir.mkdir @build_dir

            prepare_tmpdirs data
            create_package
            move_packages
          rescue Exception => e
            raise e
          ensure
            cleanup_tmpdirs
          end
        end
      end

      def create_package
        begin
          ["control", "Makefile", "compat", "rules", "copyright", "changelog"].each do |filename|
            create_file(filename)
          end
          create_tar
          create_install
          create_preandpost_install

          FileUtils.cd @build_dir do |f|
            PluginPackager.do_quietly?(@verbose) do
              if @signature
                if @signature.is_a? String
                  PluginPackager.safe_system "debuild -i -k#{@signature}"
                else
                  PluginPackager.safe_system "debuild -i"
                end
              else
                PluginPackager.safe_system "debuild -i -us -uc"
              end
            end
          end

          puts "Created package #{@current_package_fullname}"
        rescue Exception => e
          raise RuntimeError, "Could not build package - #{e}"
        end
      end

      def move_packages
        begin
          FileUtils.cp(Dir.glob(File.join(@tmpdir, "*.{deb,dsc,diff.gz,orig.tar.gz,changes}")), ".")
        rescue Exception => e
          raise RuntimeError, "Could not copy packages to working directory: '#{e}'"
        end
      end

      def create_preandpost_install
        if @plugin.preinstall
          raise RuntimeError, "pre-install script '#{@plugin.preinstall}' not found"  unless File.exists?(@plugin.preinstall)
          FileUtils.cp(@plugin.preinstall, File.join(@build_dir, 'debian', "#{@current_package_shortname}.preinst"))
        end

        if @plugin.postinstall
          raise RuntimeError, "post-install script '#{@plugin.postinstall}' not found" unless File.exists?(@plugin.postinstall)
          FileUtils.cp(@plugin.postinstall, File.join(@build_dir, 'debian', "#{@current_package_shortname}.postinst"))
        end

      end

      def create_install
        begin
          File.open(File.join(@build_dir, "debian", "#{@current_package_shortname}.install"), "w") do |f|
            @current_package_data[:files].each do |filename|
              extended_filename = File.join(@libdir, File.expand_path(filename).gsub(/#{File.expand_path(plugin.path)}|\.\//, ''))
              f.puts "#{extended_filename} #{File.dirname(extended_filename)}"
            end
          end
        rescue Exception => e
          raise RuntimeError, "Could not create install file - #{e}"
        end
      end

      def create_tar
        begin
          PluginPackager.do_quietly?(@verbose) do
            Dir.chdir(@tmpdir) do
              PluginPackager.safe_system "tar -Pcvzf #{File.join(@tmpdir,"#{@current_package_shortname}_#{@plugin.metadata[:version]}.orig.tar.gz")} #{@current_package_shortname}_#{@plugin.metadata[:version]}"
            end
          end
        rescue Exception => e
          raise "Could not create tarball - #{e}"
        end
      end

      def create_file(filename)
        begin
          file = ERB.new(File.read(File.join(File.dirname(__FILE__), "templates", "debian", "#{filename}.erb")), nil, "-")
          File.open(File.join(@build_dir, "debian", filename), "w") do |f|
            f.puts file.result(binding)
          end
        rescue Exception => e
          raise RuntimeError, "could not create #{filename} file - #{e}"
        end
      end

      def prepare_tmpdirs(data)
        data[:files].each do |file|
          @targetdir = File.join(@build_dir, @libdir, File.dirname(File.expand_path(file)).gsub(@plugin.target_path, ""))
          FileUtils.mkdir_p(@targetdir) unless File.directory? @targetdir
          FileUtils.cp_r(file, @targetdir)
        end

        FileUtils.mkdir_p(File.join(@build_dir, "debian"))
      end

      def cleanup_tmpdirs
        FileUtils.rm_r @tmpdir if File.directory? @tmpdir
      end
    end
  end
end
