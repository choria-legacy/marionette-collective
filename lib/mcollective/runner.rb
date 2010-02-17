module MCollective
    # The main runner for the daemon, supports running in the foreground 
    # and the background, keeps detailed stats and provides hooks to access
    # all this information
    class Runner
        def initialize(configfile)
            @config = Config.instance
            @config.loadconfig(configfile) unless @config.configured

            @log = Log.instance

            @connection = PluginManager["connector_plugin"]
            @security = PluginManager["security_plugin"]

            @stats = {:starttime => Time.now.to_i,
                      :validated => 0, 
                      :unvalidated => 0, 
                      :filtered => 0, 
                      :passed => 0, 
                      :total => 0,
                      :replies => 0}

            @connection.connect

            @agents = Agents.new 
        end

        # Daemonize the current process
        def self.daemonize
            fork do
                Process.setsid
                exit if fork
                Dir.chdir('/tmp')
                STDIN.reopen('/dev/null')
                STDOUT.reopen('/dev/null', 'a')
                STDERR.reopen('/dev/null', 'a')
    
                yield
            end
        end

        # Starts the main loop, before calling this you should initialize the MCollective::Config singleton.
        def run
            controltopic = Util.make_target("mcollective", :command)
            @connection.subscribe(controltopic)

            # Start the registration plugin if interval isn't 0
            PluginManager["registration_plugin"].run(@connection) unless @config.registerinterval == 0

            loop do
                begin
                    msg = receive
                    dest = msg[:msgtarget]

                    if dest =~ /#{controltopic}/
                        @log.debug("Handling message for mcollectived controller")
    
                        controlmsg(msg) 
                    elsif dest =~ /#{@config.topicprefix}#{@config.topicsep}(.+)#{@config.topicsep}command/
                        target = $1
    
                        @log.debug("Handling message for #{target}")
    
                        agentmsg(msg, target)
                    end
                rescue Interrupt
                    @log.warn("Exiting after interrupt signal")
                    @connection.disconnect
                    exit!
                rescue Exception => e
                    @log.warn("Failed to handle message: #{e} - #{e.class}\n")
                    @log.warn(e.backtrace.join("\n\t"))
                end
            end
        end

        private
        # Deals with messages directed to agents
        def agentmsg(msg, target)
            @agents.dispatch(msg, target, @connection) do |replies|
                dest = Util.make_target(target, :reply)
                reply(target, dest, replies, msg[:requestid]) unless replies == nil
            end
        end

        # Deals with messages sent to our control topic
        def controlmsg(msg)
            begin
                body = msg[:body]
                requestid = msg[:requestid]

                replytopic = Util.make_target("mcollective", :reply)

                case body
                    when /^stats$/
                        reply("mcollective", replytopic, stats, requestid)

                    when /^reload_agent (.+)$/
                        reply("mcollective", replytopic, "reloaded #{$1} agent", requestid) if @agents.loadagent($1)

                    when /^reload_agents$/
                        reply("mcollective", replytopic, "reloaded all agents", requestid) if @agents.loadagents

                    when /^exit$/
                        @log.error("Exiting due to request to controller")
                        reply("mcollective", replytopic, "exiting after request to controller", requestid)

                        @connection.disconnect
                        exit!

                    else
                        @log.error("Received an unknown message to the controller")

                end
            rescue Exception => e
                @log.error("Failed to handle control message: #{e}")
            end
        end

        # Builds stats for this mcollectived
        def stats
            @stats[:validated] = @security.stats[:validated]
            @stats[:unvalidated] = @security.stats[:unvalidated]
            @stats[:passed] = @security.stats[:passed]
            @stats[:filtered] = @security.stats[:filtered]

            r = {:stats => @stats,
                 :threads => [],
                 :pid => Process.pid,
                 :times => {} }

            Process.times.each_pair{|k,v| 
               k = k.to_sym
               r[:times][k] = v
            }

            Thread.list.each do |t|
                r[:threads] << "#{t.inspect}"
            end

            r[:agents] = Agents.agentlist
            r
        end

        # Receive a message from the connection handler
        def receive
            msg = @connection.receive

            @stats[:total] += 1

            msg = @security.decodemsg(msg)

            raise("Received message is not targetted to us")  unless @security.validate_filter?(msg[:filter])

            msg
        end

        # Sends a reply to a specific target topic
        def reply(sender, target, msg, requestid)
            reply = @security.encodereply(sender, target, msg, requestid)

            @connection.send(target, reply)

            @stats[:replies] += 1
        end
    end
end

# vi:tabstop=4:expandtab:ai
