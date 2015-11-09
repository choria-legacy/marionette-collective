metadata    :name        => "Agent",
            :description => "Meta data about installed MColletive Agents",
            :author      => "R.I.Pienaar <rip@devco.net>",
            :license     => "ASL 2.0",
            :version     => "1.0",
            :url         => "https://docs.puppetlabs.com/mcollective/",
            :timeout     => 1

dataquery :description => "Agent Meta Data" do
    input :query,
          :prompt => "Agent Name",
          :description => "Valid agent name",
          :type => :string,
          :validation => /^[\w\_]+$/,
          :maxlength => 20

    [:license, :timeout, :description, :url, :version, :author].each do |item|
      output item,
             :description => "Agent #{item}",
             :display_as => item.to_s.capitalize
    end
end
