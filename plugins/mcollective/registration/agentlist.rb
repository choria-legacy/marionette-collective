module MCollective
    module Registration
        # A registration plugin that simply sends in the list of agents we have
        class Agentlist<Base
            def body
                MCollective::Agents.agentlist
            end
        end
    end
end
# vi:tabstop=4:expandtab:ai
