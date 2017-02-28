test_name "mco puppet runonce" do

  testdir = master.tmpdir('mco_puppet_runonce')
  @testfilename = master.tmpfile('mco_puppet_runonce').split('/')[-1]

  def testfile(h)
    if /windows/ =~ h[:platform]
      "C:/#{@testfilename}"
    else
      "/tmp/#{@testfilename}"
    end
  end

  step "Add manifest to host classification" do
    node_str = ''
    hosts.each do |h|
      n =<<-EOS
        node #{h} {
            file { "#{testfile(h)}":
              ensure => file,
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
      mco_bin = 'cmd.exe /c mco.bat'
    else
      mco_bin = 'mco'
    end

    step "Stub puppet and run agent to get certs"
    hosts.each do |host|
      stub_hosts_on(host, 'puppet' => master.ip)
    end

    step "Run mco puppet runonce"
    on(mco_master, "#{mco_bin} puppet runonce")
    sleep 30

    step "Verify that file created on systems"
    hosts.each do |h|
      cmd = "ls #{testfile(h)}"
      (1..10).each do |iter|
        res = on(h, cmd, :acceptable_exit_codes => (0..254))
        unless res.exit_code == 0
          sleep (2**iter)/2
        else
          break
        end
      end
      result = on(h, cmd, :acceptable_exit_codes => (0..254))
      assert_equal(0, result.exit_code, 'mco failed to create file')
    end
  end
end
