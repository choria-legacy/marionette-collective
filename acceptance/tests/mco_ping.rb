test_name "mco ping" do
  step "run ping"
    if agent.platform =~ /windows/ then
      if agent[:ruby_arch] == 'x86' then
        mco_bin = 'cmd.exe /c C:/Program\ Files\ \(x86\)/Puppet\ Labs/Puppet/bin/mco.bat'
      else
        mco_bin = 'cmd.exe /c C:/Program\ Files/Puppet\ Labs/Puppet/bin/mco.bat'
      end
    else
     mco_bin = '/opt/puppetlabs/bin/mco'
    end
    on(agent, "#{mco_bin} ping") do
      assert_equal(0, exit_code)
      assert_match(/^1\s+replies/, stdout)
    end
end
