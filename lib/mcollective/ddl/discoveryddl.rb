module MCollective
  module DDL
    # DDL for discovery plugins, a full example can be seen below
    #
    # metadata    :name        => "mc",
    #             :description => "MCollective Broadcast based discovery",
    #             :author      => "R.I.Pienaar <rip@devco.net>",
    #             :license     => "ASL 2.0",
    #             :version     => "0.1",
    #             :url         => "https://docs.puppetlabs.com/mcollective/",
    #             :timeout     => 2
    #
    # discovery do
    #     capabilities [:classes, :facts, :identity, :agents, :compound]
    # end
    class DiscoveryDDL<Base
      def discovery_interface
        @entities[:discovery]
      end

      # records valid capabilities for discovery plugins
      def capabilities(*caps)
        caps = [caps].flatten

        raise "Discovery plugin capabilities can't be empty" if caps.empty?

        caps.each do |cap|
          if [:classes, :facts, :identity, :agents, :compound].include?(cap)
            @entities[:discovery][:capabilities] << cap
          else
            raise "%s is not a valid capability, valid capabilities are :classes, :facts, :identity, :agents and :compound" % cap
          end
        end
      end

      # Creates the definition for new discovery plugins
      #
      #    discovery do
      #       capabilities [:classes, :facts, :identity, :agents, :compound]
      #    end
      def discovery(&block)
        raise "Discovery plugins can only have one definition" if @entities[:discovery]

        @entities[:discovery] = {:capabilities => []}

        @current_entity = :discovery
        block.call if block_given?
        @current_entity = nil
      end
    end
  end
end
