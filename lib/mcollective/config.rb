module MCollective
  # A pretty sucky config class, ripe for refactoring/improving
  class Config
    include Singleton

    attr_accessor :mode

    attr_reader :daemonize, :pluginconf, :configured
    attr_reader :logfile, :keeplogs, :max_log_size, :loglevel, :logfacility
    attr_reader :identity, :daemonize, :connector, :securityprovider, :factsource
    attr_reader :registration, :registerinterval, :classesfile
    attr_reader :rpcauditprovider, :rpcaudit, :configdir, :rpcauthprovider
    attr_reader :rpcauthorization, :color, :configfile
    attr_reader :rpclimitmethod, :logger_type, :fact_cache_time, :collectives
    attr_reader :main_collective, :ssl_cipher, :registration_collective
    attr_reader :direct_addressing, :direct_addressing_threshold, :ttl
    attr_reader :default_discovery_method, :default_discovery_options
    attr_reader :publish_timeout, :threaded, :soft_shutdown, :activate_agents
    attr_reader :registration_splay, :discovery_timeout, :soft_shutdown_timeout
    attr_reader :connection_timeout

    def initialize
      @configured = false
    end

    def loadconfig(configfile)
      set_config_defaults(configfile)

      if File.exists?(configfile)
        libdirs = []
        File.readlines(configfile).each do |line|

          # strip blank spaces, tabs etc off the end of all lines
          line.gsub!(/\s*$/, "")

          unless line =~ /^#|^$/
            if (line =~ /(.+?)\s*=\s*(.+)/)
              key = $1.strip
              val = $2

              begin
                case key
                when "registration"
                  @registration = val.capitalize
                when "registration_collective"
                  @registration_collective = val
                when "registerinterval"
                  @registerinterval = Integer(val)
                when "registration_splay"
                  @registration_splay = Util.str_to_bool(val)
                when "collectives"
                  @collectives = val.split(",").map {|c| c.strip}
                when "main_collective"
                  @main_collective = val
                when "logfile"
                  @logfile = val
                when "keeplogs"
                  @keeplogs = Integer(val)
                when "max_log_size"
                  @max_log_size = Integer(val)
                when "loglevel"
                  @loglevel = val
                when "logfacility"
                  @logfacility = val
                when "libdir"
                  paths = val.split(File::PATH_SEPARATOR)
                  paths.each do |path|
                    raise("libdir paths should be absolute paths but '%s' is relative" % path) unless Util.absolute_path?(path)

                    libdirs << path
                  end
                when "identity"
                  @identity = val
                when "direct_addressing"
                  @direct_addressing = Util.str_to_bool(val)
                when "direct_addressing_threshold"
                  @direct_addressing_threshold = Integer(val)
                when "color"
                  @color = Util.str_to_bool(val)
                when "daemonize"
                  @daemonize = Util.str_to_bool(val)
                when "securityprovider"
                  @securityprovider = val.capitalize
                when "factsource"
                  @factsource = val.capitalize
                when "connector"
                  @connector = val.capitalize
                when "classesfile"
                  @classesfile = val
                when /^plugin.(.+)$/
                  @pluginconf[$1] = val
                when "discovery_timeout"
                  @discovery_timeout = Integer(val)
                when "publish_timeout"
                  @publish_timeout = Integer(val)
                when "connection_timeout"
                  @connection_timeout = Integer(val)
                when "rpcaudit"
                  @rpcaudit = Util.str_to_bool(val)
                when "rpcauditprovider"
                  @rpcauditprovider = val.capitalize
                when "rpcauthorization"
                  @rpcauthorization = Util.str_to_bool(val)
                when "rpcauthprovider"
                  @rpcauthprovider = val.capitalize
                when "rpclimitmethod"
                  @rpclimitmethod = val.to_sym
                when "logger_type"
                  @logger_type = val
                when "fact_cache_time"
                  @fact_cache_time = Integer(val)
                when "ssl_cipher"
                  @ssl_cipher = val
                when "threaded"
                  @threaded = Util.str_to_bool(val)
                when "ttl"
                  @ttl = Integer(val)
                when "default_discovery_options"
                  @default_discovery_options << val
                when "default_discovery_method"
                  @default_discovery_method = val
                when "soft_shutdown"
                  @soft_shutdown = Util.str_to_bool(val)
                when "soft_shutdown_timeout"
                  @soft_shutdown_timeout = Integer(val)
                when "activate_agents"
                  @activate_agents = Util.str_to_bool(val)
                when "topicprefix", "topicsep", "queueprefix", "rpchelptemplate", "helptemplatedir"
                  Log.warn("Use of deprecated '#{key}' option.  This option is ignored and should be removed from '#{configfile}'")
                else
                  raise("Unknown config parameter '#{key}'")
                end
              rescue ArgumentError => e
                raise "Could not parse value for configuration option '#{key}' with value '#{val}'"
              end
            end
          end
        end

        read_plugin_config_dir("#{@configdir}/plugin.d")

        raise 'Identities can only match /\w\.\-/' unless @identity.match(/^[\w\.\-]+$/)

        @configured = true

        libdirs.each do |dir|
          unless File.directory?(dir)
            Log.debug("Cannot find libdir: #{dir}")
          end

          # remove the old one if it exists, we're moving it to the front
          $LOAD_PATH.reject! { |elem| elem == dir }
          $LOAD_PATH.unshift dir
        end

        if @logger_type == "syslog"
          raise "The sylog logger is not usable on the Windows platform" if Util.windows?
        end

        PluginManager.loadclass("Mcollective::Facts::#{@factsource}_facts")
        PluginManager.loadclass("Mcollective::Connector::#{@connector}")
        PluginManager.loadclass("Mcollective::Security::#{@securityprovider}")
        PluginManager.loadclass("Mcollective::Registration::#{@registration}")
        PluginManager.loadclass("Mcollective::Audit::#{@rpcauditprovider}") if @rpcaudit
        PluginManager << {:type => "global_stats", :class => RunnerStats.new}

        Log.info("The Marionette Collective version #{MCollective::VERSION} started by #{$0} using config file #{configfile}")
      else
        raise("Cannot find config file '#{configfile}'")
      end
    end

    def set_config_defaults(configfile)
      @stomp = Hash.new
      @subscribe = Array.new
      @pluginconf = Hash.new
      @connector = "activemq"
      @securityprovider = "Psk"
      @factsource = "Yaml"
      @identity = Socket.gethostname
      @registration = "Agentlist"
      @registerinterval = 0
      @registration_collective = nil
      @registration_splay = false
      @classesfile = "/var/lib/puppet/state/classes.txt"
      @rpcaudit = false
      @rpcauditprovider = ""
      @rpcauthorization = false
      @rpcauthprovider = ""
      @configdir = File.dirname(configfile)
      @color = !Util.windows?
      @configfile = configfile
      @logger_type = "file"
      @keeplogs = 5
      @max_log_size = 2097152
      @rpclimitmethod = :first
      @fact_cache_time = 300
      @loglevel = "info"
      @logfacility = "user"
      @collectives = ["mcollective"]
      @main_collective = @collectives.first
      @ssl_cipher = "aes-256-cbc"
      @direct_addressing = true
      @direct_addressing_threshold = 10
      @default_discovery_method = "mc"
      @default_discovery_options = []
      @ttl = 60
      @mode = :client
      @publish_timeout = 2
      @threaded = false
      @soft_shutdown = false
      @soft_shutdown_timeout = nil
      @activate_agents = true
      @connection_timeout = nil
    end

    def libdir
      $LOAD_PATH
    end

    def read_plugin_config_dir(dir)
      return unless File.directory?(dir)

      Dir.new(dir).each do |pluginconfigfile|
        next unless pluginconfigfile =~ /^([\w]+).cfg$/

        plugin = $1
        File.open("#{dir}/#{pluginconfigfile}", "r").each do |line|
          # strip blank lines
          line.gsub!(/\s*$/, "")
          next if line =~ /^#|^$/
          if (line =~ /(.+?)\s*=\s*(.+)/)
            key = $1.strip
            val = $2
            @pluginconf["#{plugin}.#{key}"] = val
          end
        end
      end
    end
  end
end
