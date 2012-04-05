dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift("#{dir}/")
$LOAD_PATH.unshift("#{dir}/../lib")

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

RSpec.configure do |config|
  config.mock_with :mocha

  config.before :each do
    MCollective::PluginManager.clear
  end
end
