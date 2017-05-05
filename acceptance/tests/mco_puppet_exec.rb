require 'yaml'

test_name "mco puppet exec" do

  testdir = master.tmpdir('mco_puppet_exec')

  step "Add manifest to host classification" do
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
            node default {
              exec { "hostname":
                path => ["/bin", "/usr/bin", "C:/cygwin32/bin", "C:/cygwin64/bin"],
                logoutput => true,
              }
            }
            ';
      }
MANIFEST

  end

  master_opts = {
    'main' => {
      'environmentpath' => "#{testdir}/environments",
     }
  }

  def last_run_report(h)
    if h['platform'] =~ /windows/
      'C:/ProgramData/PuppetLabs/puppet/cache'
    else
      '/opt/puppetlabs/puppet/cache'
    end + '/state/last_run_report.yaml'
  end

  with_puppet_running_on(master, master_opts) do
    if mco_master.platform =~ /windows/ then
      mco_bin = 'cmd.exe /c mco.bat'
    else
      mco_bin = 'mco'
    end

    step "Stub puppet and run agent to get certs"
    hosts.each do |host|
      stub_hosts_on(host, 'puppet' => master.ip)
      on(host, "rm -f #{last_run_report(host)}")
    end

    step "Run mco puppet runonce"
    on(mco_master, "#{mco_bin} puppet runonce")
    sleep 30

    step "Verify that hostname results logged"
    hosts.each do |h|
      cmd = "cat #{last_run_report(h)}"
      (1..10).each do |iter|
        @res = on(h, cmd, :acceptable_exit_codes => (0..254))
        unless @res.exit_code == 0
          sleep (2**iter)/2
        else
          break
        end
      end

      assert_equal(0, @res.exit_code, 'puppet failed to run')

      # Parse the last run report, ignoring object tags
      data = YAML.parse(@res.stdout)
      data.root.each do |o|
        o.tag = nil if o.respond_to?(:tag=)
      end
      data = data.to_ruby

      hostname = on(h, 'hostname').stdout.chomp
      expected = data['logs'].select {|log| log['source'] =~ /Exec\[hostname\]/}.select {|log| log['message'] == hostname}
      assert_equal(1, expected.count, 'puppet failed to exec hostname')
    end
  end
end
