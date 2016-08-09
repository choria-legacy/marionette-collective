require 'rubygems'
require 'json'
require 'stomp'
require 'timeout'
require 'digest/md5'
require 'optparse'
require 'singleton'
require 'socket'
require 'erb'
require 'shellwords'
require 'stringio'
require 'rbconfig'
require 'tempfile'
require 'tmpdir'
require 'mcollective/monkey_patches'
require 'mcollective/cache'
require 'mcollective/exceptions'

# == The Marionette Collective
#
# Framework to build and run Systems Administration agents running on a
# publish/subscribe middleware system.  The system allows you to treat your
# network as the only true source of the state of your platform via discovery agents
# and allow you to run agents matching discovery criteria.
#
# For an overview of the idea behind this and what it enables please see:
#   http://www.devco.net/archives/2009/10/18/middleware_for_systems_administration.php
module MCollective

  require "mcollective/agent"
  require "mcollective/agents"
  require "mcollective/aggregate"
  require "mcollective/application"
  require "mcollective/applications"
  require "mcollective/client"
  require "mcollective/config"
  require "mcollective/connector"
  require "mcollective/data"
  require "mcollective/ddl"
  require "mcollective/discovery"
  require "mcollective/facts"
  require "mcollective/logger"
  require "mcollective/log"
  require "mcollective/matcher"
  require "mcollective/message"
  require "mcollective/optionparser"
  require "mcollective/generators"
  require "mcollective/pluginmanager"
  require "mcollective/pluginpackager"
  require "mcollective/registration"
  require "mcollective/rpc"
  require "mcollective/runnerstats"
  require "mcollective/security"
  require "mcollective/shell"
  require "mcollective/ssl"
  require "mcollective/util"
  require "mcollective/validator"
  require "mcollective/vendor"

  MCollective::Vendor.load_vendored

  VERSION="2.9.0"

  def self.version
    VERSION
  end
end
