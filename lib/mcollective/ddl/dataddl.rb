module MCollective
  module DDL
    # A DDL file for the data query plugins.
    #
    # Query plugins can today take only one input by convention in the DDL that
    # is called :query, otherwise the input is identical to the standard input.
    #
    # metadata    :name        => "Agent",
    #             :description => "Meta data about installed MColletive Agents",
    #             :author      => "R.I.Pienaar <rip@devco.net>",
    #             :license     => "ASL 2.0",
    #             :version     => "1.0",
    #             :url         => "https://docs.puppetlabs.com/mcollective/",
    #             :timeout     => 1
    #
    # dataquery :description => "Agent Meta Data" do
    #     input :query,
    #           :prompt => "Agent Name",
    #           :description => "Valid agent name",
    #           :type => :string,
    #           :validation => /^[\w\_]+$/,
    #           :maxlength => 20
    #
    #     [:license, :timeout, :description, :url, :version, :author].each do |item|
    #       output item,
    #              :description => "Agent #{item}",
    #              :display_as => item.to_s.capitalize
    #     end
    # end
    class DataDDL<Base
      def dataquery(input, &block)
        raise "Data queries need a :description" unless input.include?(:description)
        raise "Data queries can only have one definition" if @entities[:data]

        @entities[:data]  = {:description => input[:description],
                             :input => {},
                             :output => {}}

        @current_entity = :data
        block.call if block_given?
        @current_entity = nil
      end

      def input(argument, properties)
        raise "The only valid input name for a data query is 'query'" if argument != :query

        super
      end

      # Returns the interface for the data query
      def dataquery_interface
        @entities[:data] || {}
      end
    end
  end
end
