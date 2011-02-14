module MCollective
    class Applications
        def self.[](appname)
            load_application(appname)
            PluginManager["#{appname}_application"]
        end

        def self.run(appname)
            load_config

            load_application(appname)
            PluginManager["#{appname}_application"].run
        end

        def self.load_application(appname)
            return if PluginManager.include?("#{appname}_application")

            load_config

            PluginManager.loadclass "MCollective::Application::#{appname.capitalize}"
            PluginManager << {:type => "#{appname}_application", :class => "MCollective::Application::#{appname.capitalize}"}
        end

        # Returns an array of applications found in the lib dirs
        def self.list
            load_config

            applist = []

            Config.instance.libdir.each do |libdir|
                applicationdir = "#{libdir}/mcollective/application"
                next unless File.directory?(applicationdir)

                Dir.entries(applicationdir).grep(/\.rb$/).each do |application|
                    applist << File.basename(application, ".rb")
                end
            end

            applist
        rescue
            return []
        end

        # Loads the config and checks if --config or -c is given
        #
        # This is mostly a hack, when we're redoing how config works
        # this stuff should be made less sucky
        def self.load_config
            return if Config.instance.configured

            original_argv = ARGV.clone
            configfile = nil

            parser = OptionParser.new
            parser.on("--config CONFIG", "-c", "Config file") do |f|
                configfile = f
            end

            parser.program_name = $0

            parser.on("--help")

            # avoid option parsers own internal version handling that sux
            parser.on("-v", "--verbose")

            parser.environment("MCOLLECTIVE_EXTRA_OPTS")

            begin
                parser.parse!
            rescue OptionParser::InvalidOption
                retry
            end

            ARGV.clear
            original_argv.each {|a| ARGV << a}

            configfile = Util.config_file_for_user unless configfile

            Config.instance.loadconfig(configfile)
        end
    end
end
