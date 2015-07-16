test_name "mco puppet count" do
  step "run puppet count"
    if mco_master.platform =~ /windows/ then
      mco_bin = 'cmd.exe /c mco.bat'
    else
      mco_bin = 'mco'
    end
    on(mco_master, "#{mco_bin} puppet count") do
      assert_equal(0, exit_code)
      assert_match(/^Total Puppet nodes:\s+#{hosts.size}/, stdout)
    end
end
