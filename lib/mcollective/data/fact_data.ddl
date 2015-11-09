metadata    :name        => "Fact",
            :description => "Structured fact query",
            :author      => "Puppet Labs",
            :license     => "ASL 2.0",
            :version     => "1.0",
            :url         => "https://docs.puppetlabs.com/mcollective/",
            :timeout     => 1

dataquery :description => "Fact" do
  input :query,
        :prompt => 'Fact Path',
        :description => 'Path to a fact, eg network.eth0.address',
        :type => :string,
        :validation => /./,
        :maxlength => 256

  output :exists,
        :description => 'Fact is present',
        :display_as => 'exists'

  output :value,
        :description => 'Fact value',
        :display_as => 'value'

  output :value_encoding,
        :description => 'Encoding of the fact value (text/plain or application/json)',
        :display_as => 'value_encoding'
end
