test_name 'install puppet-agent plugin' do
  require 'beaker/dsl/install_utils'
  extend Beaker::DSL::InstallUtils

  hosts.each_with_index do |h, index|
    if h.platform =~ /windows/ then
     # On Windows, '/' leads to a different path for Cygwin utils vs Git. Explicitly
     # use the root drive.
     SourcePath  = 'C:'+Beaker::DSL::InstallUtils::SourcePath
     mco_libdir = 'C:/ProgramData/PuppetLabs/mcollective/etc/plugins/mcollective'
    else
     SourcePath  = Beaker::DSL::InstallUtils::SourcePath
     mco_libdir = '/opt/puppetlabs/mcollective/plugins/mcollective'
     git_pkg = 'git'
     if h.platform =~ /ubuntu-10/
       git_pkg = 'git-core'
     end
     install_package(h, git_pkg)
    end
    on h, "mkdir -p #{mco_libdir}"

    GitURI      = Beaker::DSL::InstallUtils::GitURI
    GitHubSig   = Beaker::DSL::InstallUtils::GitHubSig

    repositories = []
    puppet_module_version = ENV['PUPPET_MODULE_VERSION'] || 'master'
    options[:plugins].each do |uri|
      raise(ArgumentError, "Missing GitURI argument. URI is nil.") if uri.nil?
      uri += '#' + puppet_module_version if uri =~ /^mcollective-puppet-agent$/
      project = uri.split('#')
      fork    = project[1].split(':') if project[1]
      if fork && fork[1]
        newURI = "#{build_git_url(project[0],fork[0])}##{fork[1]}"
      else
        newURI = "#{build_git_url(project[0])}##{project[1]}"
      end
      raise(ArgumentError, "#{uri} is not recognized.") unless(newURI =~ GitURI)
      repositories << extract_repo_info_from(newURI)
    end

    on h, "echo #{GitHubSig} >> $HOME/.ssh/known_hosts"

    repositories.each do |repository|
      step "Install #{repository[:name]}"
      if repository[:path] =~ /^file:\/\/(.+)$/
        on h, "test -d #{SourcePath} || mkdir -p #{SourcePath}"
        source_dir = $1
        checkout_dir = "#{SourcePath}/#{repository[:name]}"
        on h, "rm -f #{checkout_dir}" # just the symlink, do not rm -rf !
        on h, "ln -s #{source_dir} #{checkout_dir}"
        on h, "cd #{checkout_dir} && if [ -f install.rb ]; then ruby ./install.rb ; else true; fi"
      else
        install_from_git_on h, SourcePath, repository
      end
      on h, "cd #{SourcePath}/#{repository[:name]} && for i in agent aggregate application data util validator ; do cp -a $i #{mco_libdir} ; done"
    end

    unless h.platform =~/windows/ then
      on h, 'service mcollective restart'
    else
      on h, puppet('resource service mcollective ensure=stopped')
      on h, puppet('resource service mcollective ensure=running')
    end
    sleep 30 # wait for mco to finish starting
  end
  unless port_open_within?(mco_master, 61613, 300 )
    raise Beaker::DSL::FailTest, 'Timed out trying to access ActiveMQ'
  end
end
