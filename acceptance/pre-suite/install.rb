test_name 'install' do
  # add the nightlies repo
  shell 'cd /etc/yum.repos.d && curl -O http://nightlies.puppetlabs.com/puppet-agent-latest/repo_configs/rpm/pl-puppet-agent-latest-el-7-x86_64.repo'

  # add the PL products repo
  shell 'rpm -i http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm'

  install_package default, 'puppet-agent'

  # install activemq, copy config and trust/keystore
  install_package default, 'activemq'

  scp_to default, 'files/activemq.xml', '/etc/activemq/activemq.xml'

  shell 'service activemq start'

  # install mcollective config files
  scp_to default, 'files/server.cfg', '/etc/puppetlabs/mcollective/server.cfg'
  scp_to default, 'files/client.cfg', '/etc/puppetlabs/mcollective/client.cfg'

  shell 'service mcollective restart'
end
