metadata    :name        => "stdin",
            :description => "STDIN based discovery for node identities",
            :author      => "Tomas Doran <bobtfish@bobtfish.net.net>",
            :license     => "ASL 2.0",
            :version     => "0.1",
            :url         => "http://marionette-collective.org/",
            :timeout     => 0

discovery do
    capabilities :identity
end
