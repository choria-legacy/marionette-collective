test_name "mco ping" do
  step "run ping"
    if mco_master.platform =~ /windows/ then
      mco_bin = 'cmd.exe /c mco.bat'
    else
      mco_bin = 'mco'
    end
    on(mco_master, "#{mco_bin} ping") do
      assert_equal(0, exit_code)
      assert_match(/^#{hosts.size}\s+replies/, stdout)
    end
end
