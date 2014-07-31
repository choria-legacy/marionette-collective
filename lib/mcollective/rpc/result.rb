module MCollective
  module RPC
    # Simple class to manage compliant results from MCollective::RPC agents
    #
    # Currently it just fakes Hash behaviour to the result to remain backward
    # compatible but it also knows which agent and action produced it so you
    # can associate results to a DDL
    class Result
      attr_reader :agent, :action, :results

      include Enumerable

      def initialize(agent, action, result={})
        @agent = agent
        @action = action
        @results = result
      end

      def [](idx)
        @results[idx]
      end

      def []=(idx, item)
        @results[idx] = item
      end

      def fetch(key, default)
        @results.fetch(key, default)
      end

      def each
        @results.each_pair {|k,v| yield(k,v) }
      end

      def to_json(*a)
        {:agent => @agent,
         :action => @action,
         :sender => @results[:sender],
         :statuscode => @results[:statuscode],
         :statusmsg => @results[:statusmsg],
         :data => @results[:data]}.to_json(*a)
      end

      def <=>(other)
        self[:sender] <=> other[:sender]
      end
    end
  end
end
