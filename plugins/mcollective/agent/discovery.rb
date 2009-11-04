module MCollective
    module Agent
        # Discovery agent for The Marionette Collective
        # 
        # Released under the Apache License, Version 2
        class Discovery
            attr_reader :timeout, :meta

            def initialize
                @log = MCollective::Log.instance

                @timeout = 5
                @meta = {:license => "Apache License, Version 2",
                         :author => "R.I.Pienaar <rip@devco.net>"}
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
                        reply = MCollective::Facts[$1]

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

                inventory     - returns a has with various bits of information like 
                                list of agents, threads, etc

                ping          - simply responds with 'pong'
                get_fact fact - replies with the value of a facter fact
                EOH
            end

            private
            def inventory
                reply = {:agents => MCollective::Agents.agentlist,
                         :threads => [],
                         :times => Process.times}

                Thread.list.each do |t|
                    reply[:threads] << "#{t.inspect}"
                end

                reply
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai:filetype=ruby
