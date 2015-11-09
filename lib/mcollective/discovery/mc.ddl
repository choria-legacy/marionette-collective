metadata    :name        => "mc",
            :description => "MCollective Broadcast based discovery",
            :author      => "R.I.Pienaar <rip@devco.net>",
            :license     => "ASL 2.0",
            :version     => "0.1",
            :url         => "https://docs.puppetlabs.com/mcollective/",
            :timeout     => 2

discovery do
    capabilities [:classes, :facts, :identity, :agents, :compound]
end
