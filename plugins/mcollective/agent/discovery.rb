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
                 :timeout => @timeout,
                 :name => "Discovery Agent",
                 :version => MCollective.version,
                 :url => "http://www.marionette-collective.org",
                 :description => "MCollective Discovery Agent"}
      end

      def handlemsg(msg, stomp)
        reply = "unknown request"

        case msg[:body]
          when "ping"
            reply = "pong"

          else
            reply = "Unknown Request: #{msg[:body]}"
        end

        reply
      end
    end
  end
end
