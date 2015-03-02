test_name 'Install puppet-agent' do
  shell 'cd /etc/yum.repos.d && curl -O http://nightlies.puppetlabs.com/puppet-agent-latest/repo_configs/rpm/pl-puppet-agent-latest-el-7-x86_64.repo'
  install_package default, 'puppet-agent'
end
