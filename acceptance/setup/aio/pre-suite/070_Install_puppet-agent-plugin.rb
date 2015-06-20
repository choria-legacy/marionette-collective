test_name 'install puppet-agent plugin' do
  hosts.each do |h|
    if h.platform =~ /windows/ then
     mco_libdir = 'C:/ProgramData/PuppetLabs/mcollective/etc/plugins/mcollective'
    else
     mco_libdir = '/opt/puppetlabs/mcollective/plugins/mcollective'
     git_pkg = 'git'
     if h.platform =~ /ubuntu-10/
       git_pkg = 'git-core'
     end
     install_package(h, git_pkg)
    end
    on h, "mkdir -p #{mco_libdir}"
    on h, "git clone https://github.com/puppetlabs/mcollective-puppet-agent.git"
    on h, "cd mcollective-puppet-agent && for i in agent aggregate application data util validator ; do cp -a $i #{mco_libdir} ; done"

    unless h.platform =~/windows/ then
      on h, 'service mcollective restart'
    else
      on h, puppet('resource service mcollective ensure=stopped')
      on h, puppet('resource service mcollective ensure=running')
    end
  end
  unless port_open_within?(mco_master, 61613, 300 )
    raise Beaker::DSL::FailTest, 'Timed out trying to access ActiveMQ'
  end
end
