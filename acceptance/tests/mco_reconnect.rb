test_name "mco servers should reconnect if cut-off from broker" do
  skip_test "Can't manipulate firewall rules easily on Windows" if mco_master.platform =~ /windows/

  # Add firewall rules blocking the source ports for the current incoming connections.
  # When nodes attempt to reconnect, they'll grab a new outgoing port and should bypass the firewall rules.
  step "disconnect servers" do
    hosts.reject {|host| host == mco_master}.each do |host|
      ip = fact_on(host, 'ipaddress')
      mco_port = on(mco_master, "netstat -anpt|grep 61613|grep ESTAB|grep -Po '#{ip}:\\K\\d+'").stdout.chomp
      step "blocking traffic to #{ip}:#{mco_port}" do
        on(mco_master, "iptables -A INPUT -p tcp --sport #{mco_port} -j DROP")
        on(mco_master, "iptables -A OUTPUT -p tcp --dport #{mco_port} -j DROP")
      end
    end

    on(mco_master, 'iptables -L')
    teardown do
      on(mco_master, 'iptables -F')
    end
  end

  step "check unreachable ping" do
    on(mco_master, "mco ping") do
      assert_equal(0, exit_code)
      assert_match(/^1\s+replies/, stdout)
    end
  end

  # It takes 2 heartbeat failures before stomp will retry. The minimum configurable heartbeat is 30 seconds,
  # so 30 is the minimum time before mcollective could reconnect.
  sleep 30

  step "check for reconnection" do
    retry_on(mco_master, "mco ping | grep '#{hosts.size} replies'", {:max_retries => 10, :retry_interval => 5})
  end
end
