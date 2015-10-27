metadata    :name        => "stdin",
            :description => "STDIN based discovery for node identities",
            :author      => "Tomas Doran <bobtfish@bobtfish.net.net>",
            :license     => "ASL 2.0",
            :version     => "0.1",
            :url         => "https://docs.puppetlabs.com/mcollective/",
            :timeout     => 0

discovery do
    capabilities :identity
end
