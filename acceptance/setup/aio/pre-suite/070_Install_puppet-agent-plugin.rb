test_name 'install puppet-agent plugin' do
  if agent.platform =~ /windows/ then
   mco_libdir = 'C:/ProgramData/PuppetLabs/mcollective/etc/plugins/mcollective'
  else
   mco_libdir = '/opt/puppetlabs/mcollective/plugins/mcollective'
   git_pkg = 'git'
   if agent.platform =~ /ubuntu-10/
     git_pkg = 'git-core'
   end
   install_package(agent, git_pkg)
  end
  on agent, "mkdir -p #{mco_libdir}"
  on agent, "git clone https://github.com/puppetlabs/mcollective-puppet-agent.git"
  on agent, "cd mcollective-puppet-agent && for i in agent aggregate application data util validator ; do cp -a $i #{mco_libdir} ; done"

  unless agent.platform =~/windows/ then
    on agent, 'service mcollective restart'
  else
    on agent, puppet('resource service mcollective ensure=stopped')
    on agent, puppet('resource service mcollective ensure=running')
  end

  unless port_open_within?(agent, 61613, 300 )
    raise Beaker::DSL::FailTest, 'Timed out trying to access ActiveMQ'
  end
end
