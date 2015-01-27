---
layout: default
title: "MCollective Plugin Directory"
---

This directory of MCollective plugins was migrated from the Puppet Labs wiki in January, 2015. 

# Agents

 * [Apt](apt.html) - Perform various tasks for apt/dpkg
 * [File Manager](agent_file_manager.html) - create, touch, remove and retrieve information about files
 * [IP Tables Junkfilter Manager](agent_iptables_junk_filter.html) - Add, removes and queries rules on a specific chain
 * [Net Test](net_test.html) - Performs network reachability testing
 * [NRPE](nrpe_agent.html) - Runs NRPE commands using MCollective as transport
 * [Process](process_management.html) - Manage server processes
 * [Puppet](puppet_agent.html) - enable, disable, run puppet daemons. 
 * [Puppet CA](puppet_ca.html) - Manage the Puppet Certificate Authority
 * [Package](package.html) - installs, uninstalls and query Operating System packages
 * [Packages](packages.html) - install, update, uninstall multiple packages in one run with fine version/revision control
 * [Service](services.html) - stop, starts and query Operating System services
 * [Spam Assassin](spamassassin.html) - Perform various tasks for Spam Assassin
 * [Stomp Utilities](stomp_util.html) - helpers and utilities for the STOMP connector

# Fact Sources


 * [Facter via YAML](facter_via_yaml.html) - Access Facter variables as YAML
 * [Facter](facter.html) - Use Puppet Labs Facter as a fact source
 * [Ohai](ohai.html) - Use OpsCode Ohai as a fact source

# Auditing


 * [Central RPC Log](central_rpc_log.html) - Logs RPC audit logs to a central log file or MongoDB instance
 * [Central LogStash log](logstash_rpc_audit_logs.html) - Logs RPC audit logs to a central [LogStash](http://code.google.com/p/logstash/) instance

# Authorization

 * [Action Policy](authorization_action_policy.html) - Authorization plugin with fine grain per action ACLs

# Data

 * [Puppet Resource Status]() - Datasource to facilitate discovery of machines based on the state of Puppet resources
 * [Sysctl Value](sysctl_data.html) - Datasource to retrieve values from any Linux sysctl
 * [Agent Meta Data](agent_metadata.html) - Datasource to retrieve meta data about currently installed agents for nodes

# Discovery


 * [Registration Data in MongoDB](agent_registration_mongodb.html) - Discover against registration data in a MongoDB NoSQL server

# Security

 
 * [None](none.html) - A plugin for development that provides no security

# Registration


 * [Meta Data](agent_metadata.html) - Sends agents, facts and classes lists to registration agents
 * [Registration Monitor](agent_registration_monitor.html) - Writes registration data to file and a Nagios check
 * [Registration Data in MongoDB](agent_registration_mongodb.html) - Writes registration data to a MongoDB NoSQL server

# Tools


 * [Puppet Commander](puppet_commander.html) - schedule puppet runs on a group of hosts with enforced concurrency
 * [SSH](discovery_assisted_ssh.html) - Discovery assisted ssh
