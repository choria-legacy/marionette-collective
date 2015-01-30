require 'rubygems'

gem 'mocha'

require 'rspec'
require 'mcollective'
require 'rspec/mocks'
require 'mocha'
require 'ostruct'
require 'tmpdir'
require 'tempfile'
require 'fileutils'
require 'mcollective/test'

require 'monkey_patches/instance_variable_defined'

RSpec.configure do |config|
  config.mock_with :mocha
  config.include(MCollective::Test::Matchers)

  config.before :each do
    MCollective::Config.instance.set_config_defaults("")
    MCollective::PluginManager.clear
  end
end

# With the addition of the ddl requirement for connectors its becomes necessary
# to stub the inherited method. Because tests don't use a real config files libdirs
# aren't set and connectors have no way of finding their ddls so we stub it out
# in the general case and test for is specifically.
MCollective::Connector::Base.stubs(:inherited)
