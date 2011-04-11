module MCollective
    module Agent
        # Discovery agent for The Marionette Collective
        #
        # Released under the Apache License, Version 2
        class Discovery
            attr_reader :timeout, :meta

            def initialize
                config = Config.instance.pluginconf

                @timeout = 5
                @timeout = config["discovery.timeout"].to_i if config.include?("discovery.timeout")

                @meta = {:license => "Apache License, Version 2",
                         :author => "R.I.Pienaar <rip@devco.net>",
                         :timeout => @timeout}
            end

            def handlemsg(msg, stomp)
                reply = "unknown request"

                case msg[:body]
                    when "inventory"
                        reply = inventory

                    when /echo (.+)/
                        reply = $1

                    when "ping"
                        reply = "pong"

                    when /^get_fact (.+)/
                        reply = Facts[$1]

                    else
                        reply = "Unknown Request: #{msg[:body]}"
                end

                reply
            end

            def help
                <<-EOH
                Discovery Agent
                ===============

                Agent to facilitate discovery of machines and data about machines.

                Accepted Messages
                -----------------

                inventory     - returns a hash with various bits of information like
                                list of agents, threads, etc

                ping          - simply responds with 'pong'
                get_fact fact - replies with the value of a facter fact
                EOH
            end

            private
            def inventory
                reply = {:agents => Agents.agentlist,
                         :threads => [],
                         :facts => {},
                         :classes => [],
                         :times => ::Process.times}

                reply[:facts] = PluginManager["facts_plugin"].get_facts

                cfile = Config.instance.classesfile
                if File.exist?(cfile)
                    reply[:classes] = File.readlines(cfile).map {|i| i.chomp}
                end

                Thread.list.each do |t|
                    reply[:threads] << "#{t.inspect}"
                end

                reply
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai:filetype=ruby
