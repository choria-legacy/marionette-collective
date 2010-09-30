---
layout: mcollective
title: Configuration Guide
disqus: true
---

[SSLSecurity]: /reference/plugins/security_ssl.html
[Registration]: /reference/plugins/registration.html
[Auditing]: /simplerpc/auditing.html
[Authorization]: /simplerpc/authorization.html

# {{page.title}}

 * TOC Placeholder
 {:toc}

This guide tells you about the major configuration options in the daemon and client config files.  There are options not mentioned
here typically ones specific to a certain plugin.

## Configuration Files
There are 2 configuration files, one for the client and one for the server, these default to */etc/mcollective/server.cfg* and */etc/mcollective/client.cfg*.

Configuration is a simple *key = val* style configuration file.

## Common Options
|Key|Sample|Description|
|---|------|-----------|
|topicprefix|/topic/mcollective|Prefix that gets used for all messages|
|topicnamesep|.|The seperator to use between parts of the topic path|
|logfile|/var/log/mcollective.log|Where to log|
|loglevel|debug|Can be info, warn, debug, fatal, error|
|identity|dev1.your.com|Identifier for this node, doesn't need to be unique, defaults to fqdn if unset|
|keeplogs|5|The amount of logs to keep|
|max_log_size|2097152|Max size in bytes for log files before rotation happens|
|libdir|/usr/libexec/mcollective|Where to look for plugins|
|connector|Stomp|Which _connector_ plugin to use for communication|
|securityprovider|Psk|Which security model to use, see [SSL Security Plugin][SSLSecurity] for details on configuring SSL|
|rpchelptemplate|/etc/mcollective/rpc-help.erb|The path to the erb template used for generating help|

## Server Configuration
The server configuration file should be root only readable

|Key|Sample|Description|
|---|------|-----------|
|daemonize|1|Runs the server in the background|
|factsource|Facter|Which fact plugin to use|
|registration|Agentlist|[Registration] plugin to use|
|registerinterval|120|How many seconds to sleep between registration messages, setting this to zero disables registration|
|classesfile|/var/lib/puppet/classes.txt|Where to find a list of classes configured by your configuration management system|
|rpcaudit|1|Enables [SimpleRPC Auditing][Auditing]|
|rpcauditprovider|Logfile|Enables auditing using _MCollective::Audit::Logfile_|
|plugin.discovery.timeout|10|Sets the timeout for the discovery agent, useful if facts are very slow|
|rpcauthorization|1|Enables [SimpleRPC Authorization][Authorization] globally|
|rpcauthprovider|action_policy|Use the _MCollective::Util::ActionPolicy_ plugin to manage authorization|

## Client Configuration
The client configuration file should be readable by everyone, it's not advised to put PSK's or client SSL certs in a world readable file, see below how to do that per user.

|Key|Sample|Description|
|---|------|-----------|
|color|0|Disables the use of color in RPC results|

## Plugin Configuration
You can add free form config options for plugins, they take the general form like:

{% highlight ini %}
    plugin.pluginname.option = value
{% endhighlight %}

Each plugin's documentation should tell you what options are availble.

Common plugin options are:

|Key|Sample|Description|
|---|------|-----------|
|plugin.stomp.host|stomp.your.com|Host to connect too|
|plugin.stomp.port|6163|Port to connecto too|
|plugin.stomp.user|mcollective|User to connect as|
|plugin.stomp.password|password|Password to use|
|plugin.yaml|/etc/mcollective/facts.yaml:/other/facts.yaml|Where the yaml fact source finds facts from, multiples get merged|
|plugin.psk|123456789|The pre-shared key to use for the Psk security provider|
|plugin.psk.callertype|group|What to base the callerid on for the PSK plugin, uid, gid, user, group or identity|

## Client Setup
It's recommended that you do not set host, user, password and Psk in the client configuration file since these files are generally world readable unlike the server one that should be root readable only.  I just set mine to *unset* so it's clear to someone who looks at the config file that it's not going to work without the settings below.

From version _0.4.8_ onwards you can also put client configuration in _~/.mcollective_ as an alternative to the method below, but you will need a full client.cfg then in that location.

You can set various Environment variables per user to supply these values:

{% highlight bash %}
export STOMP_USER=user
export STOMP_PASSWORD=password
export STOMP_SERVER=stomp.your.com
export MCOLLECTIVE_PSK=123456789
{% endhighlight %}

You can also adjust some default behaviors on a per user basis with environment variables:

{% highlight bash %}
export MCOLLECTIVE_TIMEOUT=10
export MCOLLECTIVE_DTIMEOUT=1
{% endhighlight %}

This sets the overall timeout and discovery timeout respectively.

The client library will use these and so you can give each user who use the admin utilities their own username and rights.
