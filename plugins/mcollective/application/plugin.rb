module MCollective
  class Application::Plugin<Application

    exclude_argument_sections "common", "filter", "rpc"

    description "MCollective Plugin Application"
    usage <<-END_OF_USAGE
mco plugin package [options] <directory>
       mco plugin info <directory>
       mco plugin doc <plugin>
       mco plugin doc <type/plugin>
       mco plugin generate agent <pluginname> [actions=val,val]
       mco plugin generate data <pluginname> [outputs=val,val]

          info : Display plugin information including package details.
       package : Create all available plugin packages.
           doc : Display documentation for a specific plugin.
    END_OF_USAGE

    option  :pluginname,
            :description => "Plugin name",
            :arguments => ["-n", "--name NAME"],
            :type => String

    option :postinstall,
           :description => "Post install script",
           :arguments => ["--postinstall POSTINSTALL"],
           :type => String

    option :preinstall,
           :description => "Pre install script",
           :arguments => ["--preinstall PREINSTALL"],
           :type => String

    option :iteration,
           :description => "Iteration number",
           :arguments => ["--iteration ITERATION"],
           :type => String

    option :vendor,
           :description => "Vendor name",
           :arguments => ["--vendor VENDOR"],
           :type => String

    option :pluginpath,
           :description => "MCollective plugin path",
           :arguments => ["--pluginpath PATH"],
           :type => String

    option :mccommon,
           :description => "Set the mcollective common package that the plugin depends on",
           :arguments => ["--mc-common-pkg PACKAGE"],
           :type => String

    option :mcserver,
           :description => "Set the mcollective server package that the plugin depends on",
           :arguments => ["--mc-server-pkg PACKAGE"],
           :type => String

    option :mcclient,
           :description => "Set the mcollective client package that the plugin depends on",
           :arguments => ["--mc-client-pkg PACKAGE"],
           :type =>String

    option :dependency,
           :description => "Adds a dependency to the plugin",
           :arguments => ["--dependency DEPENDENCIES"],
           :type => :array

    option :format,
           :description => "Package output format. Defaults to rpmpackage or debpackage",
           :arguments => ["--format OUTPUTFORMAT"],
           :type => String

    option :sign,
           :description => "Embed a signature in the package",
           :arguments => ["--sign"],
           :type => :boolean

    option :rpctemplate,
           :description => "Template to use.",
           :arguments => ["--template HELPTEMPLATE"],
           :type => String

    option :description,
           :description => "Plugin description",
           :arguments => ["--description DESCRIPTION"],
           :type => String

    option :author,
           :description => "The author of the plugin",
           :arguments => ["--author AUTHOR"],
           :type => String

    option :license,
           :description => "The license under which the plugin is distributed",
           :arguments => ["--license LICENSE"],
           :type => String

    option :version,
           :description => "The version of the plugin",
           :arguments => ["--pluginversion VERSION"],
           :type => String

    option :url,
           :description => "Url at which information about the plugin can be found",
           :arguments => ["--url URL"],
           :type => String

    option :timeout,
           :description => "The plugin's timeout",
           :arguments => ["--timeout TIMEOUT"],
           :type => Integer

    option :actions,
           :description => "Actions to be generated for an Agent Plugin",
           :arguments => ["--actions [ACTIONS]"],
           :type => Array

    option :outputs,
           :description => "Outputs to be generated for an Data Plugin",
           :arguments => ["--outputs [OUTPUTS]"],
           :type => Array

    # Handle alternative format that optparser can't parse.
    def post_option_parser(configuration)
      if ARGV.length >= 1
        configuration[:action] = ARGV.delete_at(0)

        configuration[:target] = ARGV.delete_at(0) || "."

        if configuration[:action] == "generate"
          unless ARGV[0] && ARGV[0].match(/(actions|outputs)=(.+)/i)
            unless configuration[:pluginname]
              configuration[:pluginname] = ARGV.delete_at(0)
            else
              ARGV.delete_at(0)
            end
          end

          ARGV.each do |argument|
            if argument.match(/(actions|outputs)=(.+)/i)
              configuration[$1.downcase.to_sym]= $2.split(",")
            else
              raise "Could not parse --arg '#{argument}'"
            end
          end
        end
      end
    end

    # Display info about plugin
    def info_command
      plugin = prepare_plugin
      packager = PluginPackager["#{configuration[:format].capitalize}Packager"]
      packager.new(plugin).package_information
    end

    # Generate a plugin skeleton
    def generate_command
      raise "undefined plugin type. cannot generate plugin. valid types are 'agent' and 'data'" if configuration["target"] == '.' 
      
      unless configuration[:pluginname]
        puts "No plugin name specified. Using 'new_plugin'"
        configuration[:pluginname] = "new_plugin"
      end

      load_plugin_config_values

      case configuration[:target].downcase
      when 'agent'
        Generators::AgentGenerator.new(configuration[:pluginname], configuration[:actions], configuration[:pluginname],
                                       configuration[:description], configuration[:author], configuration[:license],
                                       configuration[:version], configuration[:url], configuration[:timeout])
      when 'data'
        raise "data plugin must have at least one output" unless configuration[:outputs]
        Generators::DataGenerator.new(configuration[:pluginname], configuration[:outputs], configuration[:pluginname],
                                       configuration[:description], configuration[:author], configuration[:license],
                                       configuration[:version], configuration[:url], configuration[:timeout])
      else
        raise "invalid plugin type. cannot generate plugin '#{configuration[:target]}'"
      end
    end

    # Package plugin
    def package_command
      if configuration[:sign] && Config.instance.pluginconf.include?("debian_packager.keyname")
        configuration[:sign] = Config.instance.pluginconf["debian_packager.keyname"]
        configuration[:sign] = "\"#{configuration[:sign]}\"" unless configuration[:sign].match(/\".*\"/)
      end

      plugin = prepare_plugin
      (configuration[:pluginpath] = configuration[:pluginpath] + "/") if (configuration[:pluginpath] && !configuration[:pluginpath].match(/^.*\/$/))
      packager = PluginPackager["#{configuration[:format].capitalize}Packager"]
      packager.new(plugin, configuration[:pluginpath], configuration[:sign], configuration[:verbose]).create_packages
    end

    # Agents are just called 'agent' but newer plugin types are
    # called plugin_plugintype for example facter_facts etc so
    # this will first try the old way then the new way.
    def load_plugin_ddl(plugin, type)
      [plugin, "#{plugin}_#{type}"].each do |plugin|
        ddl = DDL.new(plugin, type, false)
        if ddl.findddlfile(plugin, type)
          ddl.loadddlfile
          return ddl
        end
      end
    end

    # Show application list and plugin help
    def doc_command
      known_plugin_types = [["Agents", :agent], ["Data Queries", :data], ["Discovery Methods", :discovery]]

      if configuration.include?(:target) && configuration[:target] != "."
        if configuration[:target] =~ /^(.+?)\/(.+)$/
          ddl = load_plugin_ddl($1.to_sym, $2)
        else
          found_plugin_type = nil

          known_plugin_types.each do |plugin_type|
            PluginManager.find(plugin_type[1], "ddl").each do |ddl|
              pluginname = ddl.gsub(/_#{plugin_type[1]}$/, "")
              if pluginname == configuration[:target]
                abort "Duplicate plugin name found, please specify a full path like agent/rpcutil" if found_plugin_type
                found_plugin_type = plugin_type[1]
              end
            end
          end

          abort "Could not find a plugin named %s in any supported plugin type" % plugin_type[1] unless found_plugin_type

          ddl = load_plugin_ddl(configuration[:target], found_plugin_type)
        end

        puts ddl.help(configuration[:rpctemplate])
      else
        puts "Please specify a plugin. Available plugins are:"
        puts

        known_plugin_types.each do |plugin_type|
          puts "%s:" % plugin_type[0]

          PluginManager.find(plugin_type[1], "ddl").each do |ddl|
            help = DDL.new(ddl, plugin_type[1])
            pluginname = ddl.gsub(/_#{plugin_type[1]}$/, "")
            puts "  %-15s %s" % [pluginname, help.meta[:description]]
          end

          puts
        end
      end
    end

    # Creates the correct package plugin object.
    def prepare_plugin
        plugintype = set_plugin_type unless configuration[:plugintype]
        configuration[:format] = "ospackage" unless configuration[:format]
        PluginPackager.load_packagers
        plugin_class = PluginPackager[configuration[:plugintype]]
        configuration[:dependency] = configuration[:dependency][0].split(" ") if configuration[:dependency] && configuration[:dependency].size == 1
        mcodependency = {:server => configuration[:mcserver],
                         :client => configuration[:mcclient],
                         :common => configuration[:mccommon]}

        plugin_class.new(configuration[:target], configuration[:pluginname],
                         configuration[:vendor], configuration[:preinstall],
                         configuration[:postinstall], configuration[:iteration],
                         configuration[:dependency], mcodependency , plugintype)
    end

    def directory_for_type(type)
      File.directory?(File.join(configuration[:target], type))
    end

    # Identify plugin type if not provided.
    def set_plugin_type
      if directory_for_type("agent") || directory_for_type("application")
        configuration[:plugintype] = "AgentDefinition"
        return "Agent"
      elsif directory_for_type(plugintype = identify_plugin)
        configuration[:plugintype] = "StandardDefinition"
        return plugintype
      else
        raise RuntimeError, "target directory is not a valid mcollective plugin"
      end
    end

    # If plugintype is StandardDefinition, identify which of the special
    # plugin types we are dealing with based on directory structure.
    # To keep it simple we limit it to one type per target directory.
    def identify_plugin
      plugintype = Dir.glob(File.join(configuration[:target], "*")).select do |file|
        File.directory?(file) && file.match(/(connector|facts|registration|security|audit|pluginpackager|data|discovery)/)
      end

      raise RuntimeError, "more than one plugin type detected in directory" if plugintype.size > 1
      raise RuntimeError, "no plugins detected in directory" if plugintype.size < 1

      stripdir = configuration[:target] == "." ? "" : configuration[:target]
      plugintype.first.gsub(/\.|\/|#{stripdir}/, "")
    end

    # Load preset metadata values from config if they are present
    # This makes it possible to override metadata values in a local
    # client config file.
    #
    # Example : plugin.metadata.license = Apache 2
    def load_plugin_config_values
      config = Config.instance
      [:pluginname, :description, :author, :license, :version, :url, :timeout].each do |confoption|
        configuration[confoption] = config.pluginconf["metadata.#{confoption}"] unless configuration[confoption]
      end
    end

    def main
        abort "No action specified, please run 'mco help plugin' for help" unless configuration.include?(:action)

        cmd = "#{configuration[:action]}_command"

        if respond_to? cmd
          send cmd
        else
          abort "Invalid action #{configuration[:action]}, please run 'mco help plugin' for help."
        end
    end
  end
end
