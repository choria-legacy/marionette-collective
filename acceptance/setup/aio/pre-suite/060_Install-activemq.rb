test_name 'install activemq' do
  amq_version = '5.11.1'
  # install activemq, copy config and trust/keystore
  if agent.platform =~ /el-|centos/ then
    install_package agent, 'java-1.7.0-openjdk'
    curl_on(agent, "-O http://apache.osuosl.org/activemq/#{amq_version}/apache-activemq-#{amq_version}-bin.tar.gz")
    on(agent, "cd /opt && tar xzf /root/apache-activemq-#{amq_version}-bin.tar.gz")
    activemq_confdir = "/opt/apache-activemq-#{amq_version}/conf"
  elsif agent.platform =~/ubuntu|debian/ then
    install_package agent, 'openjdk-7-jdk'
    curl_on(agent, "-O http://apache.osuosl.org/activemq/#{amq_version}/apache-activemq-#{amq_version}-bin.tar.gz")
    on(agent, "cd /opt && tar xzf /root/apache-activemq-#{amq_version}-bin.tar.gz")
    activemq_confdir = "/opt/apache-activemq-#{amq_version}/conf"
  elsif agent.platform =~/windows/ then

    step "Windows - Install Oracle JDK"
    oracle_base_url = 'https://download.oracle.com/otn-pub/java/jdk'
    jdk_version_full = '8u45-b14'
    jdk_version, jdk_build = jdk_version_full.split('-')
    if agent[:ruby_arch] == 'x64' then
      jdk_arch = 'x64'
    else
      jdk_arch = 'i586'
    end
    if agent.platform =~ /2003/ then
      fail_test "Sorry, this test pre-suite does not yet support Windows 2003"
      admin_dir = 'Documents\ and\ Settings/Administrator'
    else
      admin_dir = 'Users/Administrator'
    end
    jdk_exe = "jdk-#{jdk_version}-windows-#{jdk_arch}.exe"

    curl_on(agent, "-k -L -O -H 'Cookie: oraclelicense=accept-securebackup-cookie'  '#{oracle_base_url}/#{jdk_version_full}/#{jdk_exe}'")

    on(agent, "mv #{jdk_exe} /cygdrive/c/#{admin_dir}/")
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
    apply_manifest_on(agent, manifest)

    step "Windows - Add JAVA_HOME environmental variable"
    agent.add_env_var('JAVA_HOME','C:\java')

    step "Windows - Add java/bin to PATH environmental variable"
    agent.add_env_var('PATH', 'C:\java\bin')

    step "Windows - Install activemq"
    file_path = agent.tmpfile('activemq.zip')
    curl_on(agent, "-o #{file_path}.zip http://apache.osuosl.org/activemq/#{amq_version}/apache-activemq-#{amq_version}-bin.zip")
    on(agent, puppet("module install reidmv-unzip"))
    manifest = <<EOS
    unzip { "activemq":
      source  => '#{file_path}.zip',
      creates => 'C:/apache-activemq-#{amq_version}',
    }
EOS
    apply_manifest_on(agent, manifest)

    step "Windows - Add ACTIVEMQ_HOME environmental variable"
    agent.add_env_var('ACTIVEMQ_HOME',"C:\\apache-activemq-#{amq_version}")
    activemq_confdir = "C:/apache-activemq-#{amq_version}/conf"
    # ///END Windows install
  else
    install_package agent, 'activemq'
    activemq_confdir = "/etc/activemq"
  end

  step "Setup activemq config files"
  unless agent.platform =~/windows/ then
    mco_confdir = "/etc/puppetlabs/mcollective"
  else
    mco_confdir = "C:/ProgramData/PuppetLabs/mcollective/etc"
  end

  scp_to agent, 'files/activemq.xml', "#{activemq_confdir}/activemq.xml"
  scp_to agent, 'files/activemq.truststore', "#{activemq_confdir}/activemq.truststore"
  scp_to agent, 'files/activemq.keystore', "#{activemq_confdir}/activemq.keystore"

  step "Start activemq"
  if agent.platform =~ /el-|centos|ubuntu|debian/ then
    on agent, "cd /opt/apache-activemq-#{amq_version} && ./bin/activemq start"
  elsif agent.platform =~/windows/ then
    if agent[:ruby_arch] == 'x64' then
      amq_arch = 'win64'
    else
      amq_arch = 'win32'
    end
    on agent, "C:/apache-activemq-#{amq_version}/bin/#{amq_arch}/InstallService.bat"
    on agent, puppet('resource service activemq ensure=running')
  else
    on agent, 'service activemq start'
  end

  unless port_open_within?(agent, 61613, 300 )
    raise Beaker::DSL::FailTest, 'Timed out trying to access ActiveMQ'
  end

  step "Setup mcollective config files"
  unless agent.platform =~/windows/ then
    scp_to agent, 'files/server.cfg', "#{mco_confdir}/server.cfg"
    scp_to agent, 'files/client.cfg', "#{mco_confdir}/client.cfg"
  else
    scp_to agent, 'files/windows-server.cfg', "#{mco_confdir}/server.cfg"
    scp_to agent, 'files/windows-client.cfg', "#{mco_confdir}/client.cfg"
  end
  scp_to agent, 'files/ca_crt.pem', "#{mco_confdir}/ca_crt.pem"
  scp_to agent, 'files/server.crt', "#{mco_confdir}/server.crt"
  scp_to agent, 'files/server.key', "#{mco_confdir}/server.key"
  scp_to agent, 'files/client.crt', "#{mco_confdir}/client.crt"
  scp_to agent, 'files/client.key', "#{mco_confdir}/client.key"

  on agent, "mkdir #{mco_confdir}/ssl-clients"
  scp_to agent, 'files/client.crt', "#{mco_confdir}/ssl-clients/client.pem"

  step "Start mcollective service"
  unless agent.platform =~/windows/ then
    on agent, 'service mcollective restart'
  else
    on agent, puppet('resource service mcollective ensure=running')
  end

  unless port_open_within?(agent, 61613, 300 )
    raise Beaker::DSL::FailTest, 'Timed out trying to access ActiveMQ'
  end
end
