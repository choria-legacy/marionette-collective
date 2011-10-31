require 'rubygems'
require 'stomp'
require 'timeout'
require 'digest/md5'
require 'optparse'
require 'singleton'
require 'socket'
require 'erb'
require 'shellwords'
require 'mcollective/monkey_patches'
require 'tempfile'

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
    class RPCError<StandardError;end
    class RPCAborted<RPCError;end
    class UnknownRPCAction<RPCError;end
    class MissingRPCData<RPCError;end
    class InvalidRPCData<RPCError;end
    class UnknownRPCError<RPCError;end
    class NotTargettedAtUs<RuntimeError;end
    class SecurityValidationFailed<RuntimeError;end
    class DDLValidationError<RuntimeError;end

    ROOT = File.expand_path(File.dirname(__FILE__))    
    autoload :Config,         "#{ROOT}/mcollective/config"
    autoload :Log,            "#{ROOT}/mcollective/log"
    autoload :Logger,         "#{ROOT}/mcollective/logger"
    autoload :Runner,         "#{ROOT}/mcollective/runner"
    autoload :RunnerStats,    "#{ROOT}/mcollective/runnerstats"
    autoload :Agents,         "#{ROOT}/mcollective/agents"
    autoload :Client,         "#{ROOT}/mcollective/client"
    autoload :Util,           "#{ROOT}/mcollective/util"
    autoload :Optionparser,   "#{ROOT}/mcollective/optionparser"
    autoload :Connector,      "#{ROOT}/mcollective/connector"
    autoload :Security,       "#{ROOT}/mcollective/security"
    autoload :Facts,          "#{ROOT}/mcollective/facts"
    autoload :Registration,   "#{ROOT}/mcollective/registration"
    autoload :PluginManager,  "#{ROOT}/mcollective/pluginmanager"
    autoload :RPC,            "#{ROOT}/mcollective/rpc"
    autoload :Request,        "#{ROOT}/mcollective/request"
    autoload :SSL,            "#{ROOT}/mcollective/ssl"
    autoload :Application,    "#{ROOT}/mcollective/application"
    autoload :Applications,   "#{ROOT}/mcollective/applications"
    autoload :Shell,          "#{ROOT}/mcollective/shell"
    autoload :Version,        "#{ROOT}/mcollective/version"
    autoload :Installer,      "#{ROOT}/mcollective/installer"
    
    def self.version
      Version::STRING
    end
end

# vi:tabstop=4:expandtab:ai
