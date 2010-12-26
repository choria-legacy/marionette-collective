dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift("#{dir}/")
$LOAD_PATH.unshift("#{dir}/../lib")

require 'mcollective'
require 'rubygems'
require 'rspec'

