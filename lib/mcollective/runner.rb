module MCollective
    # The main runner for the daemon, supports running in the foreground
    # and the background, keeps detailed stats and provides hooks to access
    # all this information
    class Runner
        def initialize(configfile)
            @config = Config.instance
            @config.loadconfig(configfile) unless @config.configured

            @stats = PluginManager["global_stats"]

            @security = PluginManager["security_plugin"]
            @security.initiated_by = :node

            @connection = PluginManager["connector_plugin"]
            @connection.connect

            @agents = Agents.new

            Signal.trap("USR1") do
                Log.info("Reloading all agents after receiving USR1 signal")
                @agents.loadagents
            end

            Signal.trap("USR2") do
                Log.info("Cycling logging level due to USR2 signal")
                Log.cycle_level
            end
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
            begin
                PluginManager["registration_plugin"].run(@connection) unless @config.registerinterval == 0
            rescue Exception => e
                Log.error("Failed to start registration plugin: #{e}")
            end

            loop do
                begin
                    msg = receive
                    dest = msg[:msgtarget]

                    if dest =~ /#{controltopic}/
                        Log.debug("Handling message for mcollectived controller")

                        controlmsg(msg)
                    elsif dest =~ /#{@config.topicprefix}#{@config.topicsep}(.+)#{@config.topicsep}command/
                        target = $1

                        Log.debug("Handling message for #{target}")

                        agentmsg(msg, target)
                    end
                rescue Interrupt
                    Log.warn("Exiting after interrupt signal")
                    @connection.disconnect
                    exit!

                rescue NotTargettedAtUs => e
                    Log.debug("Message does not pass filters, ignoring")

                rescue Exception => e
                    Log.warn("Failed to handle message: #{e} - #{e.class}\n")
                    Log.warn(e.backtrace.join("\n\t"))
                end
            end
        end

        private
        # Deals with messages directed to agents
        def agentmsg(msg, target)
            @agents.dispatch(msg, target, @connection) do |replies|
                dest = Util.make_target(target, :reply)
                reply(target, dest, replies, msg[:requestid], msg[:callerid]) unless replies == nil
            end
        end

        # Deals with messages sent to our control topic
        def controlmsg(msg)
            begin
                body = msg[:body]
                requestid = msg[:requestid]
                callerid = msg[:callerid]

                replytopic = Util.make_target("mcollective", :reply)

                case body
                    when /^stats$/
                        reply("mcollective", replytopic, @stats.to_hash, requestid, callerid)

                    when /^reload_agent (.+)$/
                        reply("mcollective", replytopic, "reloaded #{$1} agent", requestid, callerid) if @agents.loadagent($1)

                    when /^reload_agents$/
                        reply("mcollective", replytopic, "reloaded all agents", requestid, callerid) if @agents.loadagents

                    when /^exit$/
                        Log.error("Exiting due to request to controller")
                        reply("mcollective", replytopic, "exiting after request to controller", requestid, callerid)

                        @connection.disconnect
                        exit!

                    else
                        Log.error("Received an unknown message to the controller")

                end
            rescue Exception => e
                Log.error("Failed to handle control message: #{e}")
            end
        end

        # Receive a message from the connection handler
        def receive
            msg = @connection.receive

            @stats.received

            msg = @security.decodemsg(msg)

            raise(NotTargettedAtUs, "Received message is not targetted to us")  unless @security.validate_filter?(msg[:filter])

            msg
        end

        # Sends a reply to a specific target topic
        def reply(sender, target, msg, requestid, callerid)
            reply = @security.encodereply(sender, target, msg, requestid, callerid)

            @connection.send(target, reply)

            @stats.sent
        end
    end
end

# vi:tabstop=4:expandtab:ai
