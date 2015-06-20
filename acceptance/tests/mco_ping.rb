test_name "mco ping" do
  step "run ping"
    if mco_master.platform =~ /windows/ then
      if mco_master[:ruby_arch] == 'x86' then
        mco_bin = 'cmd.exe /c C:/Program\ Files\ \(x86\)/Puppet\ Labs/Puppet/bin/mco.bat'
      else
        mco_bin = 'cmd.exe /c C:/Program\ Files/Puppet\ Labs/Puppet/bin/mco.bat'
      end
    else
     mco_bin = '/opt/puppetlabs/bin/mco'
    end
    on(mco_master, "#{mco_bin} ping") do
      assert_equal(0, exit_code)
      assert_match(/^#{hosts.size}\s+replies/, stdout)
    end
end
