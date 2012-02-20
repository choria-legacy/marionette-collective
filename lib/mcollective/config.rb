module MCollective
  # A pretty sucky config class, ripe for refactoring/improving
  class Config
    include Singleton

    attr_reader :topicprefix, :daemonize, :pluginconf, :libdir, :configured,
    :logfile, :keeplogs, :max_log_size, :loglevel, :logfacility, :identity,
    :daemonize, :connector, :securityprovider, :factsource, :registration,
    :registerinterval, :topicsep, :classesfile, :rpcauditprovider, :rpcaudit,
    :configdir, :rpcauthprovider, :rpcauthorization, :color, :configfile,
    :rpchelptemplate, :rpclimitmethod, :logger_type, :fact_cache_time,
    :collectives, :main_collective, :ssl_cipher, :registration_collective,
    :direct_addressing, :direct_addressing_threshold, :queueprefix, :ttl

    def initialize
      @configured = false
    end

    def loadconfig(configfile)
      set_config_defaults(configfile)

      if File.exists?(configfile)
        File.open(configfile, "r").each do |line|

          # strip blank spaces, tabs etc off the end of all lines
          line.gsub!(/\s*$/, "")

          unless line =~ /^#|^$/
            if (line =~ /(.+?)\s*=\s*(.+)/)
              key = $1
              val = $2

              case key
                when "topicsep"
                  @topicsep = val
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
                when "topicprefix"
                  @topicprefix = val
                when "queueprefix"
                  @queueprefix = val
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
                    @libdir << path
                    unless $LOAD_PATH.include?(path)
                      $LOAD_PATH << path
                    end
                  end
                when "identity"
                  @identity = val
                when "direct_addressing"
                  val =~ /^1|y/i ? @direct_addressing = true : @direct_addressing = false
                when "direct_addressing_threshold"
                  @direct_addressing_threshold = val.to_i
                when "color"
                  val =~ /^1|y/i ? @color = true : @color = false
                when "daemonize"
                  val =~ /^1|y/i ? @daemonize = true : @daemonize = false
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
                  val =~ /^1|y/i ? @rpcaudit = true : @rpcaudit = false
                when "rpcauditprovider"
                  @rpcauditprovider = val.capitalize
                when "rpcauthorization"
                  val =~ /^1|y/i ? @rpcauthorization = true : @rpcauthorization = false
                when "rpcauthprovider"
                  @rpcauthprovider = val.capitalize
                when "rpchelptemplate"
                  @rpchelptemplate = val
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
                else
                  raise("Unknown config parameter #{key}")
              end
            end
          end
        end

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
      else
        raise("Cannot find config file '#{configfile}'")
      end
    end

    def set_config_defaults(configfile)
      @stomp = Hash.new
      @subscribe = Array.new
      @pluginconf = Hash.new
      @connector = "Stomp"
      @securityprovider = "Psk"
      @factsource = "Yaml"
      @identity = Socket.gethostname
      @registration = "Agentlist"
      @registerinterval = 0
      @registration_collective = nil
      @topicsep = "."
      @topicprefix = "/topic/"
      @queueprefix = "/queue/"
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
      @direct_addressing = false
      @direct_addressing_threshold = 10
      @ttl = 60

      # look in the config dir for the template so users can provide their own and windows
      # with odd paths will just work more often, but fall back to old behavior if it does
      # not exist
      @rpchelptemplate = File.join(File.dirname(configfile), "rpc-help.erb")
      @rpchelptemplate = "/etc/mcollective/rpc-help.erb" unless File.exists?(@rpchelptemplate)
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
            key = $1
            val = $2
            @pluginconf["#{plugin}.#{key}"] = val
          end
        end
      end
    end
  end
end
