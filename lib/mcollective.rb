require 'rubygems'
require 'stomp'
require 'timeout'
require 'digest/md5'
require 'optparse'
require 'singleton'
require 'socket'
require 'erb'
require 'shellwords'
require 'rbconfig'
require 'tempfile'
require 'tmpdir'
require 'mcollective/monkey_patches'
require 'mcollective/cache'

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
  # Exceptions for the RPC system
  class DDLValidationError<RuntimeError;end
  class ValidatorError<RuntimeError; end
  class MsgDoesNotMatchRequestID < RuntimeError; end
  class MsgTTLExpired<RuntimeError;end
  class NotTargettedAtUs<RuntimeError;end
  class RPCError<StandardError;end
  class SecurityValidationFailed<RuntimeError;end

  class InvalidRPCData<RPCError;end
  class MissingRPCData<RPCError;end
  class RPCAborted<RPCError;end
  class UnknownRPCAction<RPCError;end
  class UnknownRPCError<RPCError;end

  autoload :Agent, "mcollective/agent"
  autoload :Agents, "mcollective/agents"
  autoload :Aggregate, "mcollective/aggregate"
  autoload :Application, "mcollective/application"
  autoload :Applications, "mcollective/applications"
  autoload :Client, "mcollective/client"
  autoload :Config, "mcollective/config"
  autoload :Connector, "mcollective/connector"
  autoload :Data, "mcollective/data"
  autoload :DDL, "mcollective/ddl"
  autoload :Discovery, "mcollective/discovery"
  autoload :Facts, "mcollective/facts"
  autoload :Logger, "mcollective/logger"
  autoload :Log, "mcollective/log"
  autoload :Matcher, "mcollective/matcher"
  autoload :Message, "mcollective/message"
  autoload :Optionparser, "mcollective/optionparser"
  autoload :Generators, "mcollective/generators"
  autoload :PluginManager, "mcollective/pluginmanager"
  autoload :PluginPackager, "mcollective/pluginpackager"
  autoload :Registration, "mcollective/registration"
  autoload :RPC, "mcollective/rpc"
  autoload :Runner, "mcollective/runner"
  autoload :RunnerStats, "mcollective/runnerstats"
  autoload :Security, "mcollective/security"
  autoload :Shell, "mcollective/shell"
  autoload :SSL, "mcollective/ssl"
  autoload :Util, "mcollective/util"
  autoload :Validator, "mcollective/validator"
  autoload :Vendor, "mcollective/vendor"

  MCollective::Vendor.load_vendored

  VERSION="@DEVELOPMENT_VERSION@"

  def self.version
    VERSION
  end
end
