metadata    :name        => "Collective",
            :description => "Collective membership",
            :author      => "Puppet Labs",
            :license     => "ASL 2.0",
            :version     => "1.0",
            :url         => "https://docs.puppetlabs.com/mcollective/",
            :timeout     => 1

dataquery :description => "Collective" do
  input :query,
        :prompt => 'Collective',
        :description => 'Collective name to ask about, eg mcollective',
        :type => :string,
        :validation => /./,
        :maxlength => 256

  output :member,
        :description => 'Node is a member of the named collective',
        :display_as => 'member'
end
