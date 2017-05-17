---
layout: default
title: Configuration Guide
---

[SSLSecurity]: /mcollective/reference/plugins/security_ssl.html
[AESSecurity]: /mcollective/reference/plugins/security_aes.html
[Registration]: /mcollective/reference/plugins/registration.html
[Auditing]: /mcollective/simplerpc/auditing.html
[Authorization]: /mcollective/simplerpc/authorization.html
[Subcollectives]: /mcollective/reference/basic/subcollectives.html
[client_config]: /mcollective/configure/client.html
[server_config]: /mcollective/configure/server.html

> **Note:** For detailed information on MCollective's client and server daemon settings, see [Client Configuration Reference][client_config] and [Server Configuration Reference][server_config], respectively.

You can configure the MCollective server daemon and client by setting options in their configuration files. Plugins can also add their own options.

## Configuration Files

MCollective uses two configuration files, one for the client and one for the server. 

If you don't specify a client configuration file when invoking MCollective, it looks for one in these locations, in the listed order:

1. `~/.mcollective`
1. `/etc/puppetlabs/mcollective/client.cfg`
1. `/etc/mcollective/client.cfg`

The MCollective server daemon looks in these locations, also in order:

1. `/etc/puppetlabs/agent/mcollective/server.cfg`
1. `/etc/mcollective/server.cfg`

The configuration file formats use a simple key-value syntax:

~~~ ini
key = value
~~~

## Common Options

|Key|Sample|Description|
|---|------|-----------|
|collectives|mcollective,subcollective|A list of [Subcollectives][] to join - 1.1.3 and newer only|
|main_collective|mcollective|The main collective to target - 1.1.3 and newer only|
|logfile|/var/log/mcollective.log|Where to log|
|loglevel|debug|Can be info, warn, debug, fatal, error|
|identity|dev1.your.com|Identifier for this node, does not need to be unique, defaults to hostname if unset and must match _/\w\.\-/_ if set|
|keeplogs|5|The amount of logs to keep|
|max_log_size|2097152|Max size in bytes for log files before rotation happens|
|libdir|/usr/libexec/mcollective:/site/mcollective|Where to look for plugins|
|connector|activemq|Which _connector_ plugin to use for communication|
|securityprovider|Psk|Which security model to use, see [SSL Security Plugin][SSLSecurity] and [AES Security Plugin][AESSecurity] for details on others|
|logger_type|file|Valid logger types, currently file, syslog or console|
|ssl_cipher|aes-256-cbc|This sets the cipher in use by the SSL code, see _man enc_ for a list supported by OpenSSL|
|direct_addressing|n|Enable or disable directed requests|
|direct_addressing_threshold|10|When direct requests are enabled, send direct messages for less than or equal to this many hosts|
|ttl|60|Sets the default TTL for requests - 1.3.2 and newer only|
|logfacility|When using the syslog logger sets the facility, defaults to user|
|default_discovery_method|The default method to use for discovery - _mc_ by default|
|default_discovery_options|Options to pass to the discovery plugin, empty by default|

## Server Configuration

The server configuration file should be readable by the root user _only._

|Key|Sample|Description|
|---|------|-----------|
|daemonize|1|Runs the server in the background|
|factsource|Facter|Which fact plugin to use|
|registration|Agentlist|[Registration][] plugin to use|
|registerinterval|120|How many seconds to sleep between registration messages, setting this to zero disables registration|
|registration_collective|development|Which sub-collective to send registration messages to|
|classesfile|/var/lib/puppet/classes.txt|Where to find a list of classes configured by your configuration management system|
|rpcaudit|1|Enables [SimpleRPC Auditing][Auditing]|
|rpcauditprovider|Logfile|Enables auditing using _MCollective::Audit::Logfile_|
|rpcauthorization|1|Enables [SimpleRPC Authorization][Authorization] globally|
|rpcauthprovider|action_policy|Use the _MCollective::Util::ActionPolicy_ plugin to manage authorization|
|rpclimitmethod|The method used for --limit-results. Can be either _first_ or _random_|
|fact_cache_time|300|How long to cache fact results for before refreshing from source|

## Client Configuration

The client configuration file should be globally readable.

> **Security Note:** _Don't_ put pre-shared keys or client SSL certificates in a world-readable file. See [Client Setup](#client-setup) for details on how to provide those values for each user.

|Key|Sample|Description|
|---|------|-----------|
|color|0|Disables the use of color in RPC results|
|connection_timeout|3|Sets the timeout for server communication. Default: none|
|discovery_timeout|2|Sets the timeout for discovering nodes. Default: 2|

## Plugin Configuration

You can add configuration options for plugins you create, using this syntax:

~~~ ini
plugin.pluginname.option = value
~~~

Describe any options in the plugin's documentation.

Common plugin options include:

|Key|Sample|Description|
|---|------|-----------|
|plugin.yaml|/etc/puppetlabs/agent/mcollective/facts.yaml:/other/facts.yaml|Where the YAML fact source finds facts; multiples are merged|
|plugin.psk|123456789|The pre-shared key (PSK) to use for the PSK security provider|
|plugin.psk.callertype|group|What to base the callerid on for the PSK plugin: uid, gid, user, group, or identity|

## Client Setup

Do not set the host, user, password, and pre-shared key in the client configuration file, since these files are generally world-readable (unlike the server configuration file, which should be readable by the root user only). 

> **Note:** You can make this clearer by explicitly setting these options to 'unset' in the client configuration file, which prevents MCollective from working unless something overrides those settings.

You can set per-user environment variables to supply these values:

~~~ bash
export STOMP_USER=user
export STOMP_PASSWORD=password
export MCOLLECTIVE_PSK=123456789
~~~

You can also set options that MCollective always applies by using the `MCOLLECTIVE_EXTRA_OPTS` environment variable:

~~~ bash
export MCOLLECTIVE_EXTRA_OPTS="--dt 5 --timeout 3 --config /home/you/mcollective.cfg"
~~~

The client library uses these variables, allowing you to give each administrative user their own username and privileges.

You can also configure clients in a user's `~/.mcollective` file as an alternative to the method above, but that file must then be a complete client configuration file; MCollective will not look for and apply other client configuration files after finding one at `~/.mcollective`.