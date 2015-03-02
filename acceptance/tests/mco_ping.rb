test_name 'mco ping'

step "run ping"
on(default, '/opt/puppetlabs/bin/mco ping') do
  assert_equal(0, exit_code)
  assert_match(/^mcollective\s+time=/, stdout)
end
