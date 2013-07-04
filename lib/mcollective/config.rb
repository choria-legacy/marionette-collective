module MCollective
  # A pretty sucky config class, ripe for refactoring/improving
  class Config
    include Singleton

    attr_accessor :mode

    attr_reader :daemonize, :pluginconf, :libdir, :configured
    attr_reader :logfile, :keeplogs, :max_log_size, :loglevel, :logfacility
    attr_reader :identity, :daemonize, :connector, :securityprovider, :factsource
    attr_reader :registration, :registerinterval, :classesfile
    attr_reader :rpcauditprovider, :rpcaudit, :configdir, :rpcauthprovider
    attr_reader :rpcauthorization, :color, :configfile
    attr_reader :rpclimitmethod, :logger_type, :fact_cache_time, :collectives
    attr_reader :main_collective, :ssl_cipher, :registration_collective
    attr_reader :direct_addressing, :direct_addressing_threshold, :ttl
    attr_reader :default_discovery_method, :default_discovery_options

    def initialize
      @configured = false
    end

    def loadconfig(configfile)
      set_config_defaults(configfile)

      if File.exists?(configfile)
        File.readlines(configfile).each do |line|

          # strip blank spaces, tabs etc off the end of all lines
          line.gsub!(/\s*$/, "")

          unless line =~ /^#|^$/
            if (line =~ /(.+?)\s*=\s*(.+)/)
              key = $1.strip
              val = $2

              case key
                when "registration"
                  @registration = val.capitalize
                when "registration_collective"
                  @registration_collective = val
                when "registerinterval"
                  @registerinterval = val.to_i
                when "collectives"
                  @collectives = val.split(",").map {|c| c.strip}
                when "main_collective"
                  @main_collective = val
                when "logfile"
                  @logfile = val
                when "keeplogs"
                  @keeplogs = val.to_i
                when "max_log_size"
                  @max_log_size = val.to_i
                when "loglevel"
                  @loglevel = val
                when "logfacility"
                  @logfacility = val
                when "libdir"
                  paths = val.split(File::PATH_SEPARATOR)
                  paths.each do |path|
                    raise("libdir paths should be absolute paths but '%s' is relative" % path) unless Util.absolute_path?(path)

                    @libdir << path
                    unless $LOAD_PATH.include?(path)
                      $LOAD_PATH << path
                    end
                  end
                when "identity"
                  @identity = val
                when "direct_addressing"
                  @direct_addressing = Util.str_to_bool(val)
                when "direct_addressing_threshold"
                  @direct_addressing_threshold = val.to_i
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
                  @fact_cache_time = val.to_i
                when "ssl_cipher"
                  @ssl_cipher = val
                when "ttl"
                  @ttl = val.to_i
                when "default_discovery_options"
                  @default_discovery_options << val
                when "default_discovery_method"
                  @default_discovery_method = val
                else
                  raise("Unknown config parameter '#{key}'")
              end
            end
          end
        end

        raise('The %s config file does not specify a libdir setting, cannot continue' % configfile) if @libdir.empty?

        I18n.load_path = Dir[File.expand_path(File.join(File.dirname(__FILE__), "locales", "*.yml"))]
        I18n.locale = :en

        read_plugin_config_dir("#{@configdir}/plugin.d")

        raise 'Identities can only match /\w\.\-/' unless @identity.match(/^[\w\.\-]+$/)

        @configured = true

        @libdir.each {|dir| Log.warn("Cannot find libdir: #{dir}") unless File.directory?(dir)}

        if @logger_type == "syslog"
          raise "The sylog logger is not usable on the Windows platform" if Util.windows?
        end

        PluginManager.loadclass("Mcollective::Facts::#{@factsource}_facts")
        PluginManager.loadclass("Mcollective::Connector::#{@connector}")
        PluginManager.loadclass("Mcollective::Security::#{@securityprovider}")
        PluginManager.loadclass("Mcollective::Registration::#{@registration}")
        PluginManager.loadclass("Mcollective::Audit::#{@rpcauditprovider}") if @rpcaudit
        PluginManager << {:type => "global_stats", :class => RunnerStats.new}

        Log.logmsg(:PLMC1, "The Marionette Collective version %{version} started by %{name} using config file %{config}", :info, :version => MCollective::VERSION, :name => $0, :config => configfile)
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
      @libdir = Array.new
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
    end

    def read_plugin_config_dir(dir)
      return unless File.directory?(dir)

      Dir.new(dir).each do |pluginconfigfile|
        next unless pluginconfigfile =~ /^([\w]+).cfg$/

        plugin = $1
        File.open("#{dir}/#{pluginconfigfile}", "r").each do |line|
          # strip blank lines
          line.gsub!(/\s*$/, "")
          prefix = nil
          next if line =~ /^#|^$/
          if line =~ /^\[(.*)\]$/
            prefix = $1.strip
          end
          if (line =~ /(.+?)\s*=\s*(.+)/)
            key = $1.strip
            key = "#{prefix}.#{key}" if prefix
            val = $2
            @pluginconf["#{plugin}.#{key}"] = val
          end
        end
      end
    end
  end
end
