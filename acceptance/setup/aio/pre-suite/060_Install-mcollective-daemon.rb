test_name 'configure mcollective daemon' do

  step "Setup mcollective config files"
  unless mco_master.platform =~/windows/ then
    mco_confdir = "/etc/puppetlabs/mcollective"
    scp_to mco_master, 'files/client.cfg', "#{mco_confdir}/client.cfg"
  else
    mco_confdir = "C:/ProgramData/PuppetLabs/mcollective/etc"
    scp_to mco_master, 'files/windows-client.cfg', "#{mco_confdir}/client.cfg"
  end

  hosts.each do |h|

    unless h.platform =~/windows/ then
      mco_confdir = "/etc/puppetlabs/mcollective"
      libdir = "/opt/puppetlabs/mcollective/plugins"
      logdir = "/var/log/puppetlabs"
      puppet_confdir = "/etc/puppetlabs/puppet"
    else
      mco_confdir = "C:/ProgramData/PuppetLabs/mcollective/etc"
      libdir = "#{mco_confdir}/plugins"
      logdir = "C:/ProgramData/PuppetLabs/mcollective/var/log"
      puppet_confdir = "C:/ProgramData/PuppetLabs/puppet/etc/puppet"
    end


    server_cfg =<<EOS
main_collective = mcollective
collectives = mcollective
libdir = #{libdir}
logfile = #{logdir}/mcollective/mcollective.log
loglevel = info
daemonize = 1

securityprovider = ssl
plugin.ssl_server_private = #{mco_confdir}/server.key
plugin.ssl_server_public = #{mco_confdir}/server.crt
plugin.ssl_client_cert_dir = #{mco_confdir}/ssl-clients/

connector = activemq
plugin.activemq.pool.size = 1
plugin.activemq.pool.1.host = activemq
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
end
