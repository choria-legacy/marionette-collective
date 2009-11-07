module MCollective
    # A pretty sucky config class, ripe for refactoring/improving
    class Config
        include Singleton

        attr_reader :topicprefix, :daemonize, :pluginconf, :libdir, :configured, :logfile, 
                    :keeplogs, :max_log_size, :loglevel, :identity, :daemonize, :connector,
                    :securityprovider, :factsource

        def initialize
            @configured = false
        end

        def loadconfig(configfile)
            @stomp = Hash.new
            @subscribe = Array.new
            @pluginconf = Hash.new
            @connector = "Stomp"
            @securityprovider = "Psk"
            @factsource = "Facter"
            @identity = Socket.gethostname

            if File.exists?(configfile)
                File.open(configfile, "r").each do |line|
                    unless line =~ /^#|^$/
                        if (line =~ /(.+?)\s*=\s*(.+)/)
                            key = $1
                            val = $2

                            case key
                                when "topicprefix"
                                    @topicprefix = val
                                when "logfile"
                                    @logfile = val
                                when "keeplogs"
                                    @keeplogs = val.to_i
                                when "max_log_size"
                                     @max_log_size = val.to_i
                                when "loglevel"
                                     @loglevel = val
                                when "libdir"
                                    @libdir = val
                                    unless $LOAD_PATH.include?(val)
                                        $LOAD_PATH << val
                                    end
                                when "identity"
                                    @identity = val
                                when "daemonize"
                                    val =~ /^1|y/i ? @daemonize = true : @daemonize = false
                                when "securityprovider"
                                    @securityprovider = val.capitalize
                                when "factsource"
                                    @factsource = val.capitalize
                                when "connector"
                                    @connector = val.capitalize
                                when /^plugin.(.+)$/
                                    @pluginconf[$1] = val
                                else
                                    raise("Unknown config parameter #{key}")
                            end
                        end
                    end
                end

                require("mcollective/facts/#{@factsource.downcase}")
                require("mcollective/connector/#{@connector.downcase}")
                require("mcollective/security/#{@securityprovider.downcase}")

                @configured = true
            else
                raise("Cannot find config file")
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai
