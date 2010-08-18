---
layout: mcollective
title: Configuration Guide
disqus: true
---

# {{page.title}}

 * TOC Placeholder
 {:toc}

This guide tells you about the major configuration options in the daemon and client config files.  There are options not mentioned
here typically ones specific to a certain plugin.

## Configuration Files
There are 2 configuration files, one for the client and one for the server, these default to */etc/mcollective/server.cfg* and */etc/mcollective/client.cfg*.

Configuration is a simple *key = val* style configuration file.

## Common Options
<table>
<tr><th><b>Key</b></th><th><b>Sample</b></th><th><b>Description</b></th></tr>
<tr><td>topicprefix</td><td>/topic/mcollective</td><td>Prefix that gets used for all messages</td></tr>
<tr><td>topicnamesep</td><td>.</td><td>The seperator to use between parts of the topic path</td></tr>
<tr><td>logfile</td><td>/var/log/mcollective.log</td><td>Where to log</td></tr>
<tr><td>loglevel</td><td>debug</td><td>Can be info, warn, debug, fatal, error</td></tr>
<tr><td>identity</td><td>dev1.your.com</td><td>Identifier for this node, doesn't need to be unique, defaults to fqdn if unset</td></tr>
<tr><td>keeplogs</td><td>10</td><td>The amount of logs to keep</td></tr>
<tr><td>max_log_size</td><td>10240</td><td>Max size in bytes for log files before rotation happens</td></tr>
<tr><td>libdir</td><td>/usr/libexec/mcollective</td><td>Where to look for plugins</td></tr>
<tr><td>connector</td><td>Stomp</td><td>Which <em>connector</em> plugin to use for communication</td></tr>
<tr><td>securityprovider</td><td>Psk</td><td>Which security model to use, see <a href="/reference/plugins/security_ssl.html">SSL Security Plugin</a> for details on configuring SSL</td></tr>
</table>

## Server Configuration
The server configuration file should be root only readable

<table>
<tr><th><b>Key</b></th><th><b>Sample</b></th><th><b>Description</b></th></tr>
<tr><td>daemonize</td><td>1</td><td>Runs the server in the background</td></tr>
<tr><td>factsource</td><td>Facter</td><td>Which fact plugin to use</td></tr>
<tr><td>registration</td><td>Agentlist</td><td><a href="/reference/plugins/registration.html">Registration</a> plugin to use</td></tr>
<tr><td>registerinterval</td><td>120</td><td>How many seconds to sleep between registration messages, setting this to zero disables registration</td></tr>
<tr><td>classesfile</td><td>/var/lib/puppet/classes.txt</td><td>Where to find a list of classes configured by your configuration management system</td></tr>
<tr><td>rpcaudit</td><td>1</td><td>Enables <a href="/simplerpc/">SimpleRPCIntroduction</a> auditing</td></tr>
<tr><td>rpcauditprovider</td><td>Logfile</td><td>Enables auditing using <em>MCollective::Audit::Logfile</em></td></tr>
<tr><td>plugin.discovery.timeout</td><td>10</td><td>Sets the timeout for the discovery agent, useful if facts are very slow</td></tr>
<tr><td>rpcauthorization</td><td>1</td><td>Enables <a href="/simplerpc/authorization.html">SimpleRPCAuthorization</a> globally</td></tr>
<tr><td>rpcauthprovider</td><td>action_policy</td><td>Use the <em>MCollective::Util::ActionPolicy</em> plugin to manage authorization</td></tr>
</table>

## Client Configuration
The client configuration file should be readable by everyone, it's not advised to put PSK's or client SSL certs in a world readable file, see below how to do that per user.

<table>
<tr><th><b>Key</b></th><th><b>Sample</b></th><th><b>Description</b></th></tr>
<tr><td>color</td><td>0</td><td>Disables the use of color in RPC results</td></tr>
</table>

## Plugin Configuration
You can add free form config options for plugins, they take the general form like:

{% highlight ini %}
    plugin.pluginname.option = value
{% endhighlight %}

Each plugin's documentation should tell you what options are availble.

Common plugin options are:

<table>
<tr><th><b>Key</b></th><th><b>Sample</b></th><th><b>Description</b></th></tr>
<tr><td>plugin.stomp.host</td><td>stomp.your.com</td><td>Host to connect too</td></tr>
<tr><td>plugin.stomp.port</td><td>6163</td><td>Port to connecto too</td></tr>
<tr><td>plugin.stomp.user</td><td>mcollective</td><td>User to connect as</td></tr>
<tr><td>plugin.stomp.password</td><td>password</td><td>Password to use</td></tr>
<tr><td>plugin.yaml</td><td>/etc/mcollective/facts.yaml:/other/facts.yaml</td><td>Where the yaml fact source finds facts from, multiples get merged</td></tr>
<tr><td>plugin.psk</td><td>123456789</td><td>The pre-shared key to use for the Psk security provider</td></tr>
</table>

## Client Setup
It's recommended that you do not set host, user, password and Psk in the client configuration file since these files are generally world readable unlike the server one that should be root readable only.  I just set mine to *unset* so it's clear to someone who looks at the config file that it's not going to work without the settings below.

From version _1.0.0_ onwards you can also put client configuration in _~/.mcollective_ as an alternative to the method below, but you will need a full client.cfg then in that location.

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
