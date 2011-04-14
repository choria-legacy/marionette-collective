

Gem::Specification.new do |s|
  s.name        = "mcollective"
  s.version     = "1.1.4"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Puppet Labs"]
  s.email       = ["info@puppetlabs.com"]
  s.homepage    = "http://www.puppetlabs.com/"
  s.summary     = %q{The Marionette Collective}
  s.description = %q{The Marionette Collective aka. mcollective is a framework to build server orchestration or parallel job execution systems.

For full information, wikis, ticketing and downloads please see http://marionette-collective.org/}


  s.required_rubygems_version = ">= 1.3.6"

  s.files              = `git ls-files`.split("\n") 
  s.test_files         = `git ls-files -- {test,spec,features}/*`.split("\n")
  #s.executables        = %w(mc-ping mc-rpc mc-facts mc-call-agent mc-controller mc-find-hosts mc-inventory mco)
  s.require_paths      = ["lib", "plugins"]
end
