module MCollective
  class Application::Plugin<Application

    exclude_argument_sections "common", "filter", "rpc"

    description "MCollective Plugin Application"
    usage <<-END_OF_USAGE
mco plugin package [options] <directory>
       mco plugin info <directory>
       mco plugin doc <agent>

          info : Display plugin information including package details.
       package : Create all available plugin packages.
           doc : Application list and RPC agent help
    END_OF_USAGE

    option  :pluginname,
            :description => "Plugin name",
            :arguments => ["-n", "--name NAME"],
            :type => String

    option :postinstall,
           :description => "Post install script",
           :arguments => ["--postinstall POSTINSTALL"],
           :type => String

    option :iteration,
           :description => "Iteration number",
           :arguments => ["--iteration ITERATION"],
           :type => String

    option :vendor,
           :description => "Vendor name",
           :arguments => ["--vendor VENDOR"],
           :type => String

    option :format,
           :description => "Package output format. Defaults to rpm or deb",
           :arguments => ["--format OUTPUTFORMAT"],
           :type => String

    option :plugintype,
           :description => "Plugin type.",
           :arguments => ["--plugintype PLUGINTYPE"],
           :type => String

    option :rpctemplate,
           :description => "RPC Template to use.",
           :arguments => ["--template RPCHELPTEMPLATE"],
           :type => String

    # Handle alternative format that optparser can't parse.
    def post_option_parser(configuration)
      if ARGV.length >= 1
        configuration[:action] = ARGV.delete_at(0)

        configuration[:target] = ARGV.delete_at(0) || "."
      end
    end

    # Display info about plugin
    def info_command
      plugin = prepare_plugin
      packager = PluginPackager["#{configuration[:format].capitalize}Packager"]
      packager.new(plugin).package_information
    end

    # Package plugin
    def package_command
      plugin = prepare_plugin
      packager = PluginPackager["#{configuration[:format].capitalize}Packager"]
      packager.new(plugin).create_packages
    end

    # Show application list and RPC agent help
    def doc_command
      if configuration.include?(:target) && configuration[:target] != "."
        ddl = MCollective::RPC::DDL.new(configuration[:target])
        puts ddl.help(configuration[:rpctemplate] || Config.instance.rpchelptemplate)
      else
        puts "The Marionette Collective version #{MCollective.version}"
        puts

        PluginManager.find("agent", "ddl").each do |ddl|
          help = MCollective::RPC::DDL.new(ddl)
          puts "  %-15s %s" % [ddl, help.meta[:description]]
        end
      end
    end

    # Creates the correct package plugin object.
    def prepare_plugin
        set_plugin_type unless configuration[:plugintype]
        configuration[:format] = "ospackage" unless configuration[:format]
        PluginPackager.load_packagers
        plugin_class = PluginPackager[configuration[:plugintype]]
        plugin_class.new(configuration[:target], configuration[:pluginname], configuration[:vendor], configuration[:postinstall], configuration[:iteration])
    end

    def directory_for_type(type)
      File.directory?(File.join(configuration[:target], type))
    end

    # Identify plugin type if not provided.
    def set_plugin_type
      if directory_for_type("agent") || directory_for_type("application")
        configuration[:plugintype] = "AgentDefinition"
      else
        raise "error. target directory is not a valid mcollective plugin"
      end
    end

    # Returns a list of available actions in a pretty format
    def list_actions
      methods.sort.grep(/_command/).map{|x| x.to_s.gsub("_command", "")}.join("|")
    end

    def main
        abort "No action specified" unless configuration.include?(:action)

        cmd = "#{configuration[:action]}_command"

        if respond_to? cmd
          send cmd
        else
          abort "Invalid action #{configuration[:action]}. Valid actions are [#{list_actions}]."
        end
    end
  end
end
