test_name 'install' do
  # add the nightlies repo
  shell 'cd /etc/yum.repos.d && curl -O http://nightlies.puppetlabs.com/puppet-agent-latest/repo_configs/rpm/pl-puppet-agent-latest-el-7-x86_64.repo'

  # add the PL products repo
  shell 'rpm -i http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm'

  install_package default, 'puppet-agent'

  # install activemq, copy config and trust/keystore
  install_package default, 'activemq'

  scp_to default, 'files/activemq.xml', '/etc/activemq/activemq.xml'
  scp_to default, 'files/activemq.truststore', '/etc/activemq/activemq.truststore'
  scp_to default, 'files/activemq.keystore', '/etc/activemq/activemq.keystore'

  shell 'service activemq start'

  # TODO(richardc): This should really be a bounded busy-loop waiting
  # until activemq starts accepting connections on port 61613.  Until
  # then, just sleep to give activemq time to start.
  shell 'sleep 10'

  # install mcollective config files
  scp_to default, 'files/server.cfg', '/etc/puppetlabs/mcollective/server.cfg'
  scp_to default, 'files/client.cfg', '/etc/puppetlabs/mcollective/client.cfg'
  scp_to default, 'files/ca_crt.pem', '/etc/puppetlabs/mcollective/ca_crt.pem'
  scp_to default, 'files/server.crt', '/etc/puppetlabs/mcollective/server.crt'
  scp_to default, 'files/server.key', '/etc/puppetlabs/mcollective/server.key'
  scp_to default, 'files/client.crt', '/etc/puppetlabs/mcollective/client.crt'
  scp_to default, 'files/client.key', '/etc/puppetlabs/mcollective/client.key'

  shell 'mkdir /etc/puppetlabs/mcollective/ssl-clients'
  scp_to default, 'files/client.crt', '/etc/puppetlabs/mcollective/ssl-clients/client.pem'

  shell 'service mcollective restart'
end
