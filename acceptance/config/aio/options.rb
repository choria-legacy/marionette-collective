{
  :type => 'aio',
  :is_puppetserver => true,
  :puppetservice => 'puppetserver',
  :'puppetserver-confdir' => '/etc/puppetlabs/puppetserver/conf.d',
  :pre_suite => [
    'setup/aio/pre-suite/010_Install.rb',
    'setup/aio/pre-suite/015_PackageHostsPresets.rb',
    'setup/common/pre-suite/025_StopFirewall.rb',
    'setup/common/pre-suite/040_ValidateSignCert.rb',
    'setup/aio/pre-suite/045_EnsureMasterStartedOnPassenger.rb',
    'setup/common/pre-suite/070_InstallCACerts.rb',
    'setup/aio/pre-suite/050_Install-activemq.rb',
    'setup/aio/pre-suite/060_Install-mcollective-daemon.rb',
    'setup/aio/pre-suite/070_Install_puppet-agent-plugin.rb',
  ],
  :plugins => [ 'mcollective-puppet-agent' ],
}
