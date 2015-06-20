test_name 'install activemq' do
  amq_version = '5.11.1'
  # install activemq, copy config and trust/keystore
  if mco_master.platform =~ /el-|centos/ then
    install_package mco_master, 'java-1.7.0-openjdk'
    curl_on(mco_master, "-O http://apache.osuosl.org/activemq/#{amq_version}/apache-activemq-#{amq_version}-bin.tar.gz")
    on(mco_master, "cd /opt && tar xzf /root/apache-activemq-#{amq_version}-bin.tar.gz")
    activemq_confdir = "/opt/apache-activemq-#{amq_version}/conf"
  elsif mco_master.platform =~/ubuntu|debian/ then
    install_package mco_master, 'openjdk-7-jdk'
    curl_on(mco_master, "-O http://apache.osuosl.org/activemq/#{amq_version}/apache-activemq-#{amq_version}-bin.tar.gz")
    on(mco_master, "cd /opt && tar xzf /root/apache-activemq-#{amq_version}-bin.tar.gz")
    activemq_confdir = "/opt/apache-activemq-#{amq_version}/conf"
  elsif mco_master.platform =~/windows/ then

    step "Windows - Install Oracle JDK"
    oracle_base_url = 'https://download.oracle.com/otn-pub/java/jdk'
    jdk_version_full = '8u45-b14'
    jdk_version, jdk_build = jdk_version_full.split('-')
    if mco_master[:ruby_arch] == 'x64' then
      jdk_arch = 'x64'
    else
      jdk_arch = 'i586'
    end
    if mco_master.platform =~ /2003/ then
      fail_test "Sorry, this test pre-suite does not yet support Windows 2003"
      admin_dir = 'Documents\ and\ Settings/Administrator'
    else
      admin_dir = 'Users/Administrator'
    end
    jdk_exe = "jdk-#{jdk_version}-windows-#{jdk_arch}.exe"

    curl_on(mco_master, "-k -L -O -H 'Cookie: oraclelicense=accept-securebackup-cookie'  '#{oracle_base_url}/#{jdk_version_full}/#{jdk_exe}'")

    on(mco_master, "mv #{jdk_exe} /cygdrive/c/#{admin_dir}/")
    manifest = <<EOS
    file { 'C:/#{admin_dir}/#{jdk_exe}':
      mode => '0777',
    }
    ->
    package {'java':
      ensure => installed,
      source => 'C:/#{admin_dir}/#{jdk_exe}',
      install_options => ['INSTALLDIR=C:\\java', 'STATIC=1', '/s'],
    }
EOS
    apply_manifest_on(mco_master, manifest)

    step "Windows - Add JAVA_HOME environmental variable"
    mco_master.add_env_var('JAVA_HOME','C:\java')

    step "Windows - Add java/bin to PATH environmental variable"
    mco_master.add_env_var('PATH', 'C:\java\bin')

    step "Windows - Install activemq"
    file_path = mco_master.tmpfile('activemq.zip')
    curl_on(mco_master, "-o #{file_path}.zip http://apache.osuosl.org/activemq/#{amq_version}/apache-activemq-#{amq_version}-bin.zip")
    on(mco_master, puppet("module install reidmv-unzip"))
    manifest = <<EOS
    unzip { "activemq":
      source  => '#{file_path}.zip',
      creates => 'C:/apache-activemq-#{amq_version}',
    }
EOS
    apply_manifest_on(mco_master, manifest)

    step "Windows - Add ACTIVEMQ_HOME environmental variable"
    mco_master.add_env_var('ACTIVEMQ_HOME',"C:\\apache-activemq-#{amq_version}")
    activemq_confdir = "C:/apache-activemq-#{amq_version}/conf"
    # ///END Windows install
  else
    install_package mco_master, 'activemq'
    activemq_confdir = "/etc/activemq"
  end

  step "Setup activemq config files"
  unless mco_master.platform =~/windows/ then
    mco_confdir = "/etc/puppetlabs/mcollective"
  else
    mco_confdir = "C:/ProgramData/PuppetLabs/mcollective/etc"
  end

  scp_to mco_master, 'files/activemq.xml', "#{activemq_confdir}/activemq.xml"
  scp_to mco_master, 'files/activemq.truststore', "#{activemq_confdir}/activemq.truststore"
  scp_to mco_master, 'files/activemq.keystore', "#{activemq_confdir}/activemq.keystore"

  step "Start activemq"
  if mco_master.platform =~ /el-|centos|ubuntu|debian/ then
    on mco_master, "cd /opt/apache-activemq-#{amq_version} && ./bin/activemq start"
  elsif mco_master.platform =~/windows/ then
    if mco_master[:ruby_arch] == 'x64' then
      amq_arch = 'win64'
    else
      amq_arch = 'win32'
    end
    on mco_master, "C:/apache-activemq-#{amq_version}/bin/#{amq_arch}/InstallService.bat"
    on mco_master, puppet('resource service activemq ensure=running')
  else
    on mco_master, 'service activemq start'
  end

  unless port_open_within?(mco_master, 61613, 300 )
    raise Beaker::DSL::FailTest, 'Timed out trying to access ActiveMQ'
  end

  ############################
  step "Setup mcollective config files"
  unless mco_master.platform =~/windows/ then
    scp_to mco_master, 'files/client.cfg', "#{mco_confdir}/client.cfg"
  else
    scp_to mco_master, 'files/windows-client.cfg', "#{mco_confdir}/client.cfg"
  end
  hosts.each do |h|

    unless h.platform =~/windows/ then
      mco_confdir = "/etc/puppetlabs/mcollective"
      libdir = "/opt/puppetlabs/mcollective/plugins"
      logdir = "/var/log/puppetlabs"
      puppet_cmd = "/opt/puppetlabs/bin/puppet"
      puppet_confdir = "/etc/puppetlabs/puppet"
    else
      mco_confdir = "C:/ProgramData/PuppetLabs/mcollective/etc"
      libdir = "#{mco_confdir}/plugins"
      logdir = "C:/ProgramData/PuppetLabs/mcollective/var/log"
      puppet_cmd = "C:/Program Files/Puppet Labs\\Puppet\\bin\\puppet.bat"
      puppet_confdir = "C:/ProgramData/PuppetLabs\\puppept\\etc\\puppet"
    end


    server_cfg =<<EOS
main_collective = mcollective
collectives = mcollective
libdir = #{libdir}
logfile = #{logdir}/mcollective.log
loglevel = info
daemonize = 1

securityprovider = ssl
plugin.ssl_server_private = #{mco_confdir}/server.key
plugin.ssl_server_public = #{mco_confdir}/server.crt
plugin.ssl_client_cert_dir = #{mco_confdir}/ssl-clients/

connector = activemq
plugin.activemq.pool.size = 1
plugin.activemq.pool.1.host = #{mco_master}
plugin.activemq.pool.1.port = 61613
plugin.activemq.pool.1.user = mcollective
plugin.activemq.pool.1.password = marionette
plugin.activemq.pool.1.ssl = true
plugin.activemq.pool.1.ssl.ca = #{mco_confdir}/ca_crt.pem
plugin.activemq.pool.1.ssl.cert = #{mco_confdir}/server.crt
plugin.activemq.pool.1.ssl.key = #{mco_confdir}/server.key

# Facts
factsource = yaml
plugin.yaml = #{mco_confdir}/facts.yaml

# Plugin settings for puppet-agent
plugin.puppet.command = "#{puppet_cmd}" agent
plugin.puppet.splay = true
plugin.puppet.splaylimit = 30
plugin.puppet.config = #{puppet_confdir}/puppet.conf
plugin.puppet.windows_service = puppet
plugin.puppet.signal_daemon = true
EOS

    create_remote_file(h,  "#{mco_confdir}/server.cfg", server_cfg)

    scp_to h, 'files/ca_crt.pem', "#{mco_confdir}/ca_crt.pem"
    scp_to h, 'files/server.crt', "#{mco_confdir}/server.crt"
    scp_to h, 'files/server.key', "#{mco_confdir}/server.key"
    scp_to h, 'files/client.crt', "#{mco_confdir}/client.crt"
    scp_to h, 'files/client.key', "#{mco_confdir}/client.key"

    on h, "mkdir #{mco_confdir}/ssl-clients"
    scp_to h, 'files/client.crt', "#{mco_confdir}/ssl-clients/client.pem"
  end

  step "Start mcollective service"
  hosts.each do |h|
    unless h.platform =~/windows/ then
      on h, 'service mcollective restart'
    else
      on h, puppet('resource service mcollective ensure=running')
    end
  end

  unless port_open_within?(mco_master, 61613, 300 )
    raise Beaker::DSL::FailTest, 'Timed out trying to access ActiveMQ'
  end
end
