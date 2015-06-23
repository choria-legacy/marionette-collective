test_name "MCOP-521 mco puppet run with powershell provider" do

  testdir = master.tmpdir('mco_powershell')
  testfile = master.tmpfile('mco_powershell').split('/')[-1]

  # gather array of windows hosts
  windows_hosts = []
  hosts.each do |h|
    if /windows/ =~ h[:platform]
       windows_hosts << h
    end
  end
  if windows_hosts.empty?
    skip_test "No windows hosts to test powershell on"
  end


  step "Add powershell manifest to windows host classification" do
    node_str = ''
    windows_hosts.each do |h|
      n =<<-EOS
        node #{h} {
            exec { "create-test-file":
              command => "out-file C:\\#{testfile}.txt",
              provider => powershell,
            }
        }
EOS
      node_str << n
    end

    apply_manifest_on(master, <<-MANIFEST, :catch_failures => true)
      File {
        ensure => directory,
        mode => "0750",
        owner => #{master.puppet['user']},
        group => #{master.puppet['group']},
      }
      file {
        '#{testdir}':;
        '#{testdir}/environments':;
        '#{testdir}/environments/production':;
        '#{testdir}/environments/production/manifests':;
        '#{testdir}/environments/production/manifests/site.pp':
          ensure => file,
          mode => "0640",
          content => '
            #{node_str}
            node default {}
            ';
      }
MANIFEST

  end

  master_opts = {
    'main' => {
      'environmentpath' => "#{testdir}/environments",
     }
  }

  with_puppet_running_on(master, master_opts) do
    if mco_master.platform =~ /windows/ then
      if mco_master[:ruby_arch] == 'x86' then
        mco_bin = 'cmd.exe /c "C:\Program Files (x86)\Puppet Labs\Puppet\bin\mco.bat"'
      else
        mco_bin = 'cmd.exe /c "C:\Program Files\Puppet Labs\Puppet\bin\mco.bat"'
      end
    else
     mco_bin = '/opt/puppetlabs/bin/mco'
    end

    step "Stub puppet and run agent to get certs"
    hosts.each do |host|
      stub_hosts_on(host, 'puppet' => master.ip)
    end

    step "Install powershell module on master"
    install_puppet_module_via_pmt_on(master, {:module_name => "puppetlabs-powershell"})

    step "Delete puppet cache dir on Windows hosts, because `agent` run created it with wrong permissions"
      # NOTE: `with_puppet_running_on` triggers a `puppet agent -t` run on the
      # Windows agents using the ADMINISTRATOR user. This creates a
      # `C:\ProgramData\PuppetLabs\puppet\cache\client_data` directory with
      # an owner of Administrator and a group of None. When the MCO service,
      # running as SYSTEM, later triggers an on-demand Puppet run,
      # a write to this directory fails with access denied since SYSTEM is not
      # explicitly granted permissions. The catalog write occurs because MCO
      # enables Puppet's cache terminus and therefore Puppet requires write
      # permissions to store a JSON catalog.
      #
      # When MCO triggers the puppet run it will run as the SYSTEM user and will
      # create the cache directory with an Owner of Administrators and a
      # Group of SYSTEM.
      windows_hosts.each do |h|
        on(h , 'rm -rf "C:\ProgramData\PuppetLabs\puppet\cache\client_data"')
      end

    step "Run mco puppet runonce"
      on(mco_master, "#{mco_bin} puppet runonce")
      sleep 45

    step "Verify that powershell created file on windows systems"
      cmd = "cmd.exe /c \"dir c:\\#{testfile}.txt\""
      windows_hosts.each do |h|
        (1..10).each do |iter|
          res = on(h, cmd, :acceptable_exit_codes => (0..254))
          unless res.exit_code == 0
            sleep (2**iter)/2
          else
            break
          end
        end
        result = on(h, cmd, :acceptable_exit_codes => (0..254))
        assert_equal(0, result.exit_code, 'mco failed to create file using powershell')
      end
  end

end
