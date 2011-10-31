module MCollective
    # A collection of agents, loads them, reloads them and dispatches messages to them.
    # It uses the PluginManager to store, load and manage instances of plugins.
    class Agents
        def initialize
            @config = Config.instance
            raise ("Configuration has not been loaded, can't load agents") unless @config.configured

            @@agents = {}

            loadagents
        end

        # Loads all agents from disk
        def loadagents
            Log.debug("Reloading all agents from disk")

            # We're loading all agents so just nuke all the old agents and unsubscribe
            @@agents.each_key do |agent|
                PluginManager.delete "#{agent}_agent"
                Util.unsubscribe(Util.make_target(agent, :command))
            end

            @@agents = {}

            @config.libdir.each do |libdir|
                agentdir = "#{libdir}/mcollective/agent"
                next unless File.directory?(agentdir)

                Dir.new(agentdir).grep(/\.rb$/).each do |agent|
                    agentname = File.basename(agent, ".rb")
                    loadagent(agentname) unless PluginManager.include?("#{agentname}_agent")
                end
            end
        end

        # Loads a specified agent from disk if available
        def loadagent(agentname)
            agentfile = findagentfile(agentname)
            return false unless agentfile
            classname = "MCollective::Agent::#{agentname.capitalize}"

            PluginManager.delete("#{agentname}_agent")

            begin
                single_instance = ["registration", "discovery"].include?(agentname)

                PluginManager.loadclass(classname)
                PluginManager << {:type => "#{agentname}_agent", :class => classname, :single_instance => single_instance}

                Util.subscribe(Util.make_target(agentname, :command)) unless @@agents.include?(agentname)

                @@agents[agentname] = {:file => agentfile}
                return true
            rescue Exception => e
                Log.error("Loading agent #{agentname} failed: #{e}")
                PluginManager.delete("#{agentname}_agent")
            end
        end

        # searches the libdirs for agents
        def findagentfile(agentname)
            @config.libdir.each do |libdir|
                agentfile = "#{libdir}/mcollective/agent/#{agentname}.rb"
                if File.exist?(agentfile)
                    Log.debug("Found #{agentname} at #{agentfile}")
                    return agentfile
                end
            end
            return false
        end

        # Determines if we have an agent with a certain name
        def include?(agentname)
            PluginManager.include?("#{agentname}_agent")
        end

        # Returns the help for an agent after first trying to get
        # rid of some indentation infront
        def help(agentname)
            raise("No such agent") unless include?(agentname)

            body = PluginManager["#{agentname}_agent"].help.split("\n")

            if body.first =~ /^(\s+)\S/
                indent = $1

                body = body.map {|b| b.gsub(/^#{indent}/, "")}
            end

            body.join("\n")
        end

        # Dispatches a message to an agent, accepts a block that will get run if there are
        # any replies to process from the agent
        def dispatch(msg, target, connection)
            Log.debug("Dispatching a message to agent #{target}")

            Thread.new do
                begin
                    agent = PluginManager["#{target}_agent"]

                    Timeout::timeout(agent.timeout) do
                        replies = agent.handlemsg(msg, connection)

                        # Agents can decide if they wish to reply or not,
                        # returning nil will mean nothing goes back to the
                        # requestor
                        unless replies == nil
                            yield(replies)
                        end
                    end
                rescue Timeout::Error => e
                    Log.warn("Timeout while handling message for #{target}")
                rescue Exception => e
                    Log.error("Execution of #{target} failed: #{e}")
                    Log.error(e.backtrace.join("\n\t\t"))
                end
            end
        end

        # Get a list of agents that we have
        def self.agentlist
            @@agents.keys
        end
    end
end

# vi:tabstop=4:expandtab:ai
