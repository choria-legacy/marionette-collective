metadata    :name        => "flatfile",
            :description => "Flatfile based discovery for node identities",
            :author      => "R.I.Pienaar <rip@devco.net>",
            :license     => "ASL 2.0",
            :version     => "0.1",
            :url         => "https://docs.puppetlabs.com/mcollective/",
            :timeout     => 0

discovery do
    capabilities :identity
end
