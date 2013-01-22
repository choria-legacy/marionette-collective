dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift("#{dir}/")
$LOAD_PATH.unshift("#{dir}/../lib")
$LOAD_PATH.unshift("#{dir}/../plugins")

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

require 'monkey_patches/instance_variable_defined'
require 'matchers/exception_matchers'

RSpec.configure do |config|
  config.mock_with :mocha
  config.include(MCollective::Matchers)

  config.before :each do
    MCollective::Config.instance.set_config_defaults("")
    MCollective::PluginManager.clear
    MCollective::Log.stubs(:log)
    MCollective::Log.stubs(:logmsg)
    MCollective::Log.stubs(:logexception)
  end
end
