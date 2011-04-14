

Gem::Specification.new do |s|
  s.name        = "mcollective"
  s.version     = "1.1.3"
  s.platform    = Gem::Platform::RUBY
  s.authors     = [""]
  s.email       = [""]
  s.homepage    = ""
  s.summary     = %q{}
  s.description = %q{}

  s.required_rubygems_version = ">= 1.3.6"

  s.files              = `git ls-files`.split("\n") 
  s.test_files         = `git ls-files -- {test,spec,features}/*`.split("\n")
  #s.executables        = %w(mc-ping mc-rpc mc-facts mc-call-agent mc-controller mc-find-hosts mc-inventory mco)
  s.require_paths      = ["lib", "plugins"]
end
