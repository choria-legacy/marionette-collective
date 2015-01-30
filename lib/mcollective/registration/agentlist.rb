module MCollective
  module Registration
    # A registration plugin that simply sends in the list of agents we have
    class Agentlist<Base
      def body
        Agents.agentlist
      end
    end
  end
end
