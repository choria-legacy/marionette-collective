require 'rake/gempackagetask'

MCollective::GemSpec = Gem::Specification.new do |s|
  s.name                  = MCollective::Version::NAME
  s.version               = MCollective::Version::STRING
  s.platform              = Gem::Platform::RUBY
  s.summary               = "Kontera MCollective Version"
  s.description           = "Kontera MCollective"
  s.author                = "Eran Levi"
  s.email                 = 'eran@kontera.com'
  s.homepage              = 'http://www.kontera.com'
  s.executables           = %w(mcollective_install)
  s.required_ruby_version = '>= 1.8.5'
  s.rubyforge_project     = "kontera_mcollective"
  s.files                 = %w(README Rakefile) + Dir.glob("{bin,lib,spec,tasks,etc,plugins}/**/*") +
                                                  Dir.glob("{mc-*,mco,mcollectived.rb,mcollective.init*}")
  s.require_path          = "lib"
  s.bindir                = "bin"
  
  s.add_dependency    'stomp',  '>= 1.1.8'
  s.add_dependency    'json',   '>= 1.5.1'
  s.add_dependency    'systemu','>= 2.0.0'
end

Rake::GemPackageTask.new(MCollective::GemSpec) do |p|
  p.gem_spec = MCollective::GemSpec
end

namespace :gem do
  desc 'Upload gems to Kontera repo'
  task :push do
    Dir["pkg/#{MCollective::GemSpec.full_name}*.gem"].each {sh "gem push #{f}"}
  end
end
