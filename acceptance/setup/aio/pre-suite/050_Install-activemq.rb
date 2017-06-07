test_name 'install activemq' do
  amq_version = ENV['ACTIVEMQ_VERSION'] || '5.14.4'
  amq_source_url =
    if amq_source = ENV['ACTIVEMQ_SOURCE']
      "#{amq_source}/activemq/#{amq_version}"
    else
      'http://buildsources.delivery.puppetlabs.net'
    end
  jdk_version = '8'
  jdk_source_url =
    if jdk_source = ENV['JDK_SOURCE'] and jdk_version_full = ENV['JDK_VERSION_FULL']
      jdk_version, jdk_build = jdk_version_full.split('-')
      "#{jdk_source}/#{jdk_version_full}"
    else
      'http://buildsources.delivery.puppetlabs.net'
    end

  # install activemq, copy config and trust/keystore
  curl_options = '--silent --show-error --fail'
  if mco_master.platform =~ /el-|centos/ then
    install_package mco_master, "java-1.#{jdk_version}.0-openjdk"
    curl_on(mco_master, "#{curl_options} -O #{amq_source_url}/apache-activemq-#{amq_version}-bin.tar.gz")
    on(mco_master, "cd /opt && tar xzf /root/apache-activemq-#{amq_version}-bin.tar.gz")
    activemq_confdir = "/opt/apache-activemq-#{amq_version}/conf"
  elsif mco_master.platform =~/ubuntu|debian/ then
    if mco_master.platform =~/ubuntu-14.04/
      # fallback to JDK 7 on older Ubuntu
      jdk_version = '7'
    end
    install_package mco_master, "openjdk-#{jdk_version}-jdk"
    curl_on(mco_master, "#{curl_options} -O #{amq_source_url}/apache-activemq-#{amq_version}-bin.tar.gz")
    on(mco_master, "cd /opt && tar xzf /root/apache-activemq-#{amq_version}-bin.tar.gz")
    activemq_confdir = "/opt/apache-activemq-#{amq_version}/conf"
  elsif mco_master.platform =~/windows/ then

    step "Windows - Install Oracle JDK"
    if mco_master[:ruby_arch] == 'x64' then
      jdk_arch = 'x64'
    else
      jdk_arch = 'i586'
    end
    if mco_master.platform =~ /2003/ then
      fail_test "Windows 2003 is not supported"
    else
      admin_dir = 'Users/Administrator'
    end
    jdk_exe = "jdk-#{jdk_version}-windows-#{jdk_arch}.exe"

    curl_on(mco_master, "-k -L -O -H 'Cookie: oraclelicense=accept-securebackup-cookie'  '#{jdk_source_url}/#{jdk_exe}'")

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
    curl_on(mco_master, "-o #{file_path}.zip #{amq_source_url}/apache-activemq-#{amq_version}-bin.zip")
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

  step "Add activemq to hosts" do
    ip = fact_on(mco_master, 'ipaddress')
    hosts.each do |h|
      apply_manifest_on(h, "host { 'activemq': ip => '#{ip}'}")
    end
  end
end
