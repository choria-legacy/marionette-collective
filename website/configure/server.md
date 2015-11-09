---
title: "MCollective » Configure » Servers"
layout: default
---


[middleware]: /mcollective/deploy/middleware/
[filters]: /mcollective/reference/ui/filters.html
[plugin_directory]: https://docs.puppetlabs.com/mcollective/plugin_directory/
[subcollectives]: /mcollective/reference/basic/subcollectives.html
[registration]: /mcollective/reference/plugins/registration.html
[puppetdb]: /puppetdb/
[security_plugin]: #security-plugin-settings
[auditing]: /mcollective/simplerpc/auditing.html
[authorization]: /mcollective/simplerpc/authorization.html
[actionpolicy]: https://docs.puppetlabs.com/mcollective/plugin_directory/authorization_action_policy.html
[security_aes]: /mcollective/reference/plugins/security_aes.html
[security_overview]: /mcollective/security.html
[ssl_plugin]: /mcollective/reference/plugins/security_ssl.html
[activemq_tls_verified]: /mcollective/reference/integration/activemq_ssl.html#ca-verified-tls
[activemq_connector]: /mcollective/reference/plugins/connector_activemq.html
[rabbitmq_connector]: /mcollective/reference/plugins/connector_rabbitmq.html
[stdlib]: http://forge.puppetlabs.com/puppetlabs/stdlib
[client_config_ssl_plugin]: ./client.html#ssl-plugin-settings

{% capture badbool %}**Note:** Use these exact values only; do not use "true" or "false."{% endcapture %}

{% capture pluginname %}**Note:** Capitalization of plugin names doesn't matter; MCollective normalizes it before loading the plugin.{% endcapture %}

{% capture path_separator %}system path separator (colon \[`:`\] on \*nix, semicolon \[`;`\] on Windows){% endcapture %}



This document describes MCollective server configuration in MCollective 2.0.0 and higher. Older versions may lack certain fetaures.


Example / Index
-----

The following is an example MCollective server config file showing all of the major groups of settings. All of the setting names styled as links can be clicked, and will take you down the page to a full description of that setting.

[See below the example for a full description of the config file location and format.](#the-server-config-files)

<pre><code># /etc/mcollective/server.cfg

# <a href="#connector-settings">Connector settings (required):</a>
# -----------------------------

<a href="#connector">connector</a> = activemq
<a href="#directaddressing">direct_addressing</a> = 1

# <a href="#activemq-connector-settings">ActiveMQ connector settings:</a>
plugin.activemq.pool.size = 1
plugin.activemq.pool.1.host = middleware.example.net
plugin.activemq.pool.1.port = 61614
plugin.activemq.pool.1.user = mcollective
plugin.activemq.pool.1.password = secret
plugin.activemq.pool.1.ssl = 1
plugin.activemq.pool.1.ssl.ca = /var/lib/puppet/ssl/certs/ca.pem
plugin.activemq.pool.1.ssl.cert = /var/lib/puppet/ssl/certs/web01.example.com.pem
plugin.activemq.pool.1.ssl.key = /var/lib/puppet/ssl/private_keys/web01.example.com.pem
plugin.activemq.pool.1.ssl.fallback = 0
plugin.activemq.stomp_1_0_fallback = 0
plugin.activemq.heartbeat_interval = 30
plugin.activemq.max_hbread_fails = 2
plugin.activemq.max_hbrlck_fails = 0

# <a href="#rabbitmq-connector-settings">RabbitMQ connector settings:</a>
plugin.rabbitmq.vhost = /mcollective
plugin.rabbitmq.pool.size = 1
plugin.rabbitmq.pool.1.host = middleware.example.net
# ... etc., similar to activemq settings

# <a href="#security-plugin-settings">Security plugin settings (required):</a>
# -----------------------------------

<a href="#securityprovider">securityprovider</a> = ssl

# <a href="#ssl-plugin-settings">SSL plugin settings:</a>
plugin.ssl_client_cert_dir = /etc/mcollective.d/clients
plugin.ssl_server_private = /etc/mcollective.d/server_private.pem
plugin.ssl_server_public = /etc/mcollective.d/server_public.pem

# <a href="#psk-plugin-settings">PSK plugin settings:</a>
plugin.psk = j9q8kx7fnuied9e

# <a href="#facts-identity-and-classes">Facts, identity, and classes (recommended):</a>
# ------------------------------------------

<a href="#factsource">factsource</a> = yaml
<a href="#pluginyaml">plugin.yaml</a> = /etc/mcollective/facts.yaml
<a href="#factcachetime">fact_cache_time</a> = 300

<a href="#identity">identity</a> = web01.example.com

<a href="#classesfile">classesfile</a> = /var/lib/puppet/state/classes.txt

# <a href="#node-registration">Registration (recommended):</a>
# -----------------------

<a href="#registerinterval">registerinterval</a> = 600
<a href="#registration_splay">registration_splay</a> = true
<a href="#registration">registration</a> = agentlist
<a href="#registrationcollective">registration_collective</a> = mcollective

# <a href="#subcollectives">Subcollectives (optional):</a>
# -------------------------

<a href="#collectives">collectives</a> = mcollective,uk_collective
<a href="#maincollective">main_collective</a> = mcollective

# <a href="#auditing">Auditing (optional):</a>
# -------------------

<a href="#rpcaudit">rpcaudit</a> = 1
<a href="#rpcauditprovider">rpcauditprovider</a> = logfile
<a href="#pluginrpcauditlogfile">plugin.rpcaudit.logfile</a> = /var/log/mcollective-audit.log

# <a href="#authorization">Authorization (optional):</a>
# ------------------------

<a href="#rpcauthorization">rpcauthorization</a> = 1
<a href="#rpcauthprovider">rpcauthprovider</a> = action_policy

# <a href="#logging">Logging:</a>
# -------

<a href="#loggertype">logger_type</a> = file
<a href="#loglevel">loglevel</a> = info
<a href="#logfile">logfile</a> = /var/log/mcollective.log
<a href="#keeplogs">keeplogs</a> = 5
<a href="#maxlogsize">max_log_size</a> = 2097152
<a href="#logfacility">logfacility</a> = user

# <a href="#platform-defaults">Platform defaults:</a>
# -----------------

<a href="#daemonize">daemonize</a> = 1
<a href="#activate_agents">activate_agents</a> = true
<a href="#soft_shutdown">soft_shutdown</a> = false
<a href="#soft_shutdown_timeout">soft_shutdown_timeout</a> = 5
<a href="#libdir">libdir</a> = /usr/libexec/mcollective
<a href="#sslcipher">ssl_cipher</a> = aes-256-cbc
</code>
</pre>


([↑ Back to top](#content))






The Server Config File(s)
-----

### Main Config File

MCollective servers are configured with the `server.cfg` file located at `/etc/puppetlabs/mcollective/server.cfg` or `/etc/mcollective/server.cfg`. It contains MCollective's core settings, as well as settings for the various plugins.

> **Warning:** This file contains sensitive credentials, and should only be readable by the root user, or whatever user the MCollective daemon runs as.

### File Format

Each line consists of a setting, an equals sign, and a value:

    # setting = value
    connector = activemq

The spaces on either side of the equals sign are optional. Lines starting with a `#` are comments.

> **Note on Boolean Values:** MCollective's config code does not have consistent handling of boolean values. Many of the core settings will accept values of `1/0` and `y/n`, but will fail to handle `true/false`; additionally, each plugin can handle boolean values differently, and some of them do not properly handle the `y/n` values accepted by the core settings.
>
> Nearly all known plugins and core settings accept `1` and `0`. Until further notice, you should always use these for all boolean settings, as no other values are universally safe.

### Plugin Config Directory (Optional)

Many of MCollective's settings are named with the format `plugin.<NAME>.<SETTING_NAME>`. These settings can optionally be put in separate files, in the `/etc/mcollective/plugin.d/` directory.  Note the directory `/etc/mcollective/plugin.d` is determined relative to the configuration file in use, if you were to use `/etc/puppetlabs/mcollective/server.cfg` then `/etc/puppetlabs/mcollective/plugin.d` would be consulted.

To move a `plugin.<NAME>.<SETTING_NAME>` setting to an external file, put it in `/etc/mcollective/plugin.d/<NAME>.cfg`, and use only the `<SETTING_NAME>` segment of the setting. So this:

    # /etc/mcollective/server.cfg
    plugin.puppet.splay = true

...is equivalent to:

    # /etc/mcollective/plugin.d/puppet.cfg
    splay = true

Note that this doesn't work for settings like `plugin.psk`, since they have no `<SETTING_NAME>` segment; a setting must have at least three segments to go in a plugin.cfg file.

### Best Practices

You should manage your MCollective servers' config files with config management software (such as Puppet). While most settings in a deployment are the same, several should be different for each server, and managing these differences manually is impractical.

If your deployment is fairly simple and there is little division of responsibility (e.g. having one group in charge of MCollective core and another group in charge of several agent plugins), then you can manage the config file with a simple template.

If your deployment is large or complex, or you expect it to become so, you should manage MCollective settings as individual resources, as this is the only practical way to divide responsibilities within a single file.

Below is an example of how to do this using the `file_line` type from the [puppetlabs/stdlib module][stdlib]:

{% highlight ruby %}
    # /etc/puppet/modules/mcollective/manifests/setting.pp
    define mcollective::setting ($setting = $title, $target = '/etc/mcollective/server.cfg', $value) {
      validate_re($target, '\/(plugin\.d\/[a-z]+|server)\.cfg\Z')
      $regex_escaped_setting = regsubst($setting, '\.', '\\.', 'G') # assume dots are the only regex-unsafe chars in a setting name.

      file_line {"mco_setting_${title}":
        path  => $target,
        line  => "${setting} = ${value}",
        match => "^ *${regex_escaped_setting} *=.*$",
      }
    }

    # /etc/puppet/modules/mcollective_core/manifests/server/connector.pp
    # ...
    # Connector settings:
    mcollective::setting {
      'connector':
        value => 'activemq';
      'direct_addressing':
        value => '1';
      'plugin.activemq.pool.size':
        value => '1';
      'plugin.activemq.pool.1.host':
        value => $activemq_server;
      'plugin.activemq.pool.1.port':
        value => '61614';
      'plugin.activemq.pool.1.user':
        value => $activemq_user;
      'plugin.activemq.pool.1.password':
        value => $activemq_password;
      'plugin.activemq.pool.1.ssl':
        value => '1';
      'plugin.activemq.pool.1.ssl.fallback':
        value => '1';
    }
    # ...
{% endhighlight %}

([↑ Back to top](#content))


Required Settings
-----

### Connector Settings


<pre><code><a href="#connector">connector</a> = activemq
<a href="#directaddressing">direct_addressing</a> = 1

# <a href="#activemq-connector-settings">ActiveMQ connector settings:</a>
plugin.activemq.pool.size = 1
plugin.activemq.pool.1.host = middleware.example.net
plugin.activemq.pool.1.port = 61614
plugin.activemq.pool.1.user = mcollective
plugin.activemq.pool.1.password = secret
plugin.activemq.pool.1.ssl = 1
# When ssl == 1:
plugin.activemq.pool.1.ssl.ca = /var/lib/puppet/ssl/certs/ca.pem
plugin.activemq.pool.1.ssl.cert = /var/lib/puppet/ssl/certs/web01.example.com.pem
plugin.activemq.pool.1.ssl.key = /var/lib/puppet/ssl/private_keys/web01.example.com.pem
plugin.activemq.pool.1.ssl.fallback = 0
# STOMP 1.1 heartbeat settings
plugin.activemq.stomp_1_0_fallback = 0
plugin.activemq.heartbeat_interval = 30
plugin.activemq.max_hbread_fails = 2
plugin.activemq.max_hbrlck_fails = 0

# <a href="#rabbitmq-connector-settings">RabbitMQ connector settings:</a>
plugin.rabbitmq.vhost = /mcollective
plugin.rabbitmq.pool.size = 1
plugin.rabbitmq.pool.1.host = middleware.example.net
plugin.rabbitmq.pool.1.port = 61613
# ... etc., similar to activemq settings
</code>
</pre>


MCollective always requires a connector plugin. The connector plugin is determined by the [middleware][] you chose for your deployment. Each connector plugin will have additional settings it requires.

> #### Shared Configuration
>
> * All servers and clients must use the same connector plugin, and its settings must be configured compatibly.
> * You must use the right connector plugin for your [choice of middleware][middleware].
> * The hostname and port must match what the middleware is using. The username and password must be valid login accounts on the middleware. If you are using [CA-verified TLS][activemq_tls_verified], the certificate must be signed by the same CA the middleware is using.

#### `connector`

Which connector plugin to use. This is determined by your [choice of middleware][middleware].

- _Default:_ `activemq`
- _Allowed values:_ `activemq`, `rabbitmq`, or the name of a third-party connector plugin. {{ pluginname }}


#### `direct_addressing`

Whether your middleware supports direct point-to-point messages. **This should usually be turned on,** and is enabled by default. The built-in `activemq` and `rabbitmq` connectors both support direct addressing, as does the external `redis` connector. (The older `stomp` connector, however, does not.)

- _Default:_ `1`
- _Allowed values:_ `1`, `0`, `y`, `n` --- {{ badbool }}

#### ActiveMQ Connector Settings

ActiveMQ is the main middleware we recommend for MCollective. The ActiveMQ connector can use multiple servers as a failover pool; if you have only one server, just use a pool size of `1`.

> **Note:** This is only a summary of the most commonly used ActiveMQ settings; there are about ten more settings that can be used to tune the connector's performance. [See the ActiveMQ connector documentation][activemq_connector] for more complete details.

- **`plugin.activemq.pool.size`** --- How many ActiveMQ servers to attempt to use. _Default:_ (nothing)
- **`plugin.activemq.pool.1.host`** --- The hostname of the first ActiveMQ server. (Note that additional servers use the same settings as the first, incrementing the number.) _Default:_ (nothing)
- **`plugin.activemq.pool.1.port`** --- The Stomp port of the first ActiveMQ server. _Default:_ `61613` or `6163`, depending on the MCollective version.
- **`plugin.activemq.pool.1.user`** --- The ActiveMQ user account to connect as. If the `STOMP_USER` environment variable is set, MCollective will use its value instead of this setting.
- **`plugin.activemq.pool.1.password`** --- The password for the user account being used. If the `STOMP_PASSWORD` environment variable is set, MCollective will use its value instead of this setting.
- **`plugin.activemq.pool.1.ssl`** --- Whether to use TLS when connecting to ActiveMQ. _Default:_ `0`; _allowed:_ `1/0`, `true/false`, `yes/no`
- **`plugin.activemq.pool.1.ssl.fallback`** --- _(When `ssl == 1`)_ Whether to allow unverified TLS if the ca/cert/key settings aren't set. _Default:_ `0`; _allowed:_ `1/0`, `true/false`, `yes/no`
- **`plugin.activemq.pool.1.ssl.ca`** --- _(When `ssl == 1`)_ The CA certificate to use when verifying ActiveMQ's certificate. Must be the path to a `.pem` file. _Default:_ (nothing)
- **`plugin.activemq.pool.1.ssl.cert`** --- _(When `ssl == 1`)_ The certificate to present when connecting to ActiveMQ. Must be the path to a `.pem` file. _Default:_ (nothing)
- **`plugin.activemq.pool.1.ssl.key`** --- _(When `ssl == 1`)_ The private key corresponding to this node's certificate. Must be the path to a `.pem` file. _Default:_ (nothing)
- **`plugin.activemq.stomp_1_0_fallback`** --- Whether to fall back to STOMP 1.0 when attempting a STOMP 1.1 connection.  _Default:_ true; _allowed_: boolean
- **`plugin.activemq.heartbeat_interval`** --- The minimum period to heartbeat the connection.  _Default_: (nothing); _allowed_: positive integer.

> **Note:** We recommend that everyone using the ActiveMQ or RabbitMQ connector configure `plugin.activemq.heartbeat_interval` and disable `plugin.activemq.stomp_1_0_fallback`
>
> We do this to work around potential problems in the underlying network protocols:
>
> * STOMP 1.0 connections are idle when no messages are being sent.
> * Many firewalls will kill idle TCP connections after a while, which can cause nodes to drop out of the deployment at seemingly random times.
> * MCollective sets the keep-alive flag on its TCP connections, but most default OS configurations only send the first keep-alive packet after about two hours, so this doesn’t really fix the problem. Nodes may still disappear for an hour or so, then come back.
>
> We used to recommend using `registerinterval` for this, but the support for STOMP 1.1 heartbeats is now mature enough to use this is preference.  Heartbeats are also a good deal lighter in terms of network traffic and server load in comparison to sending a registration message.

#### RabbitMQ Connector Settings

The RabbitMQ connector uses very similar settings to the ActiveMQ connector, with the same `.pool.1.host` style of setting names.

[See the RabbitMQ connector documentation][rabbitmq_connector] for more complete details.


([↑ Back to top](#content))


### Security Plugin Settings

<pre><code><a href="#securityprovider">securityprovider</a> = ssl

# <a href="#ssl-plugin-settings">SSL plugin settings:</a>
plugin.ssl_client_cert_dir = /etc/mcollective/clients
plugin.ssl_server_private = /etc/mcollective/server_private.pem
plugin.ssl_server_public = /etc/mcollective/server_public.pem

# <a href="#psk-plugin-settings">PSK plugin settings:</a>
plugin.psk = j9q8kx7fnuied9e
</code>
</pre>

MCollective always requires a security plugin. (Although they're called security plugins, they actually handle more, including message serialization.) Each security plugin will have additional settings it requires.

> #### Shared Configuration
>
> All servers and clients must use the same security plugin, and its settings must be configured compatibly.

It's possible to write new security plugins, but most people use one of the three included in MCollective:

- **SSL:** The best choice for most users. Provides very good security when combined with TLS on the connector plugin (see above).
- **PSK:** Poor security, but easy to configure; fine for proof-of-concept deployments.
- **AES:** Complex to configure, and carries a noticable performance cost in large networks. Only suitable for certain use cases, like where TLS on the middleware is impossible.

For a full-system look at how security works in MCollective, see [Security Overview][security_overview].


#### `securityprovider`

Which security plugin to use.

- _Default:_ `psk`
- _Allowed values:_ `ssl`, `psk`, `aes_security`, or the name of a third-party security plugin. {{ pluginname }}

#### SSL Plugin Settings

> **Note:** This security plugin requires you to manage and distribute SSL credentials. [See the SSL security plugin page][ssl_plugin] for full details. In summary:
>
> * All servers share **one** "server" keypair. They must all have a copy of the public key and private key.
> * Every admin user must have a copy of the server public key.
> * Every admin user has their own "client" keypair.
> * Every server must have a copy of **every** authorized client public key.

All of these settings have **no default,** and must be set for the SSL plugin to work.

- **`plugin.ssl_server_private`** --- The path to the server private key file, which must be in `.pem` format.
- **`plugin.ssl_server_public`** --- The path to the server public key file, which must be in `.pem` format.
- **`plugin.ssl_client_cert_dir`** --- A directory containing every authorized client public key.

The client uses different settings, which are covered in the [client config reference][client_config_ssl_plugin]:

- `plugin.ssl_server_public`
- `plugin.ssl_client_private`
- `plugin.ssl_client_public`


#### PSK Plugin Settings

> **Note:** The only credential used by this plugin is a single shared password, which all servers and admin users have a copy of.

- **`plugin.psk`** --- The shared passphrase. If the `MCOLLECTIVE_PSK` environment variable is set, MCollective will use its value instead of this setting.


([↑ Back to top](#content))


Recommended Features
-----

### Facts, Identity, and Classes

<pre><code><a href="#factsource">factsource</a> = yaml
<a href="#pluginyaml">plugin.yaml</a> = /etc/mcollective/facts.yaml
<a href="#factcachetime">fact_cache_time</a> = 300

<a href="#identity">identity</a> = web01.example.com

<a href="#classesfile">classesfile</a> = /var/lib/puppet/state/classes.txt
</code>
</pre>

MCollective clients use filters to discover nodes and limit commands. (See [Discovery Filters][filters] for more details.) These filters can use a variety of per-server metadata, including **facts, identity,** and **classes.**

* **Facts:** A collection of key/value data about a server's hardware and software. (E.g. `memorytotal = 8.00 GB`, `kernel = Darwin`, etc.)
* **Identity:** The name of the node.
* **Classes:** The Puppet classes  applied to this node. Classes are useful as metadata because they describe what _roles_ a server fills at your site.

None of these settings are mandatory, but MCollective is less useful without them.

#### `identity`

The node's name or identity. This **should** be unique for each node, but does not **need** to be.

- _Default:_ The value of Ruby's `Socket.gethostname` method, which is usually the server's FQDN.
- _Sample value:_ `web01.example.com`
- _Allowed values:_ Any string containing only alphanumeric characters, hyphens, and dots --- i.e. matching the regular expression `/\A[\w\.\-]+\Z/`

#### `classesfile`

A file with a list of classes applied by your configuration management system. This should be a plain text file containing one class name per line.

Puppet automatically writes a class file, which can be found by running `sudo puppet apply --configprint classfile`. Other configuration tools may be able to write a similar file; see their documentation for details.

- _Default:_ `/var/lib/puppet/state/classes.txt`


#### `factsource`

Which fact plugin to use.

MCollective includes a fact plugin called `yaml`. Most users should use this default, set [the `plugin.yaml` setting (see below)](#pluginyaml), and arrange to fill the file it relies on.

Other fact plugins are available in the [plugin directory][plugin_directory]. These may require settings of their own.

- _Default:_ `yaml`
- _Allowed values:_ The name of any installed fact plugin, with the `_facts` suffix trimmed off. {{ pluginname }}

#### `plugin.yaml`

_When `factsource == yaml`_

The fact file(s) to load for [the default `yaml` fact plugin](#factsource).

- _Default:_ (nothing)
- _Sample value:_ `/etc/mcollective/facts.yaml`
- _Valid values:_ A single path, or a list of paths separated by the {{ path_separator }}.

**Notes:**

The default `yaml` fact plugin reads cached facts from a file, which should be a simple YAML hash. If multiple files are specified, they will be merged. (Later files override prior ones if there are conflicting values.)

**The user is responsible for populating the fact file;** by default it is empty, and MCollective has no facts.

If you are using Puppet and Facter, you can populate it by putting something like the following in your puppet master's `/etc/puppet/manifests/site.pp`, outside any node definition:

{% highlight ruby %}
    # /etc/puppet/manifests/site.pp
    file{"/etc/mcollective/facts.yaml":
      owner    => root,
      group    => root,
      mode     => 400,
      loglevel => debug, # reduce noise in Puppet reports
      content  => inline_template("<%= scope.to_hash.reject { |k,v| k.to_s =~ /(uptime_seconds|timestamp|free)/ }.to_yaml %>"), # exclude rapidly changing facts
    }
{% endhighlight %}

#### `fact_cache_time`

How long (in seconds) to cache fact results before refreshing from source. This can be ignored unless you're using a non-default `factsource`.

- _Default:_ `300`

([↑ Back to top](#content))


### Node Registration

<pre><code><a href="#registerinterval">registerinterval</a> = 600
<a href="#registration_splay">registration_splay</a> = true
<a href="#registration">registration</a> = agentlist
<a href="#registrationcollective">registration_collective</a> = mcollective
</code>
</pre>

By default, registration is disabled, due to [`registerinterval`](#registerinterval) being set to 0.

Optionally, MCollective servers can [send periodic heartbeat messages][registration] containing some inventory information. This can provide a central inventory at sites that don't already use something like [PuppetDB][], and can also be used as a simple passive monitoring system.

The default registration plugin, `agentlist`, sends a standard SimpleRPC command over the MCollective middleware, to be processed by some server with an agent called `registration` installed. You would need to ensure that the `registration` agent is extremely performant (due to the volume of message it will receive) and installed on a limited number of servers. If your [middleware][] supports detailed permissions, you must also ensure that it allows servers to send commands to the registration agent ([ActiveMQ instructions](/mcollective/deploy/middleware/activemq.html#detailed-restrictions)).

Some registration plugins (e.g. `redis`) can insert data directly into the inventory instead of sending an RPC message. This is a flexible system, and the user is in charge of deciding what to build with it, if anything. If all you need is a searchable inventory, [PuppetDB][] is probably closer to your needs.

#### `registerinterval`

How long (in seconds) to wait between registration messages. Setting this to 0 disables registration.

- _Default:_ `0`

#### `registration_splay`

Whether to delay up to `registerinterval` when sending the initial
registration message.  This can reduce load spikes on your middleware
if you choose to restart your agents in batches.

- _Default:_ false
- _Allowed values:_ A boolean value

#### `registration`

The [registration plugin][registration] to use.

This plugin must be installed on the server sending the message, and will dictate what the message contains. The default `agentlist` plugin will only send a list of the installed agents. See [Registration Plugins][registration] for more details.

- _Default:_ `agentlist`
- _Allowed values:_ The name of any installed registration plugin. {{ pluginname }}

#### `registration_collective`

Which subcollective to send registration messages to, when using a SimpleRPC-based registration plugin.

- _Default:_ (the value of [`main_collective`](#maincollective), usually `mcollective`)


([↑ Back to top](#content))



Optional Features
-----

### Subcollectives

<pre><code><a href="#collectives">collectives</a> = mcollective,uk_collective
<a href="#maincollective">main_collective</a> = mcollective
</code>
</pre>

Subcollectives provide an alternate way of dividing up the servers in a deployment. They are mostly useful because the middleware can be made aware of them, which enables traffic flow and access restrictions. In multi-datacenter deployments, this can save bandwidth costs and give some extra security.

* [See the Subcollectives and Partitioning page][subcollectives] for more details and an example of site partitioning.

Subcollective membership is managed **on the server side,** by each server's config file. A given server can join any number of collectives, and will respond to commands from any of them.

> #### Shared Configuration
>
> If you are using any additional collectives (besides the default `mcollective` collective), your middleware must be configured to permit traffic on those collectives. See the middleware deployment guide for your specific middleware to see how to do this:
>
> * ActiveMQ: [Subcollective topic/queue names](/mcollective/deploy/middleware/activemq.html#topic-and-queue-names) --- [Multi-subcollective authorization example](/mcollective/deploy/middleware/activemq.html#detailed-restrictions-with-multiple-subcollectives)


#### `collectives`

A comma-separated list (spaces OK) of [subcollectives][] this server should join.

- _Default:_ `mcollective`
- _Sample value:_ `mcollective,uk_collective`

#### `main_collective`

The main collective for this server. Currently, this is only used as the default value for the [`registration_collective`](#registrationcollective) setting.

- _Default:_ (the first value of [the `collectives` setting](#collectives), usually `mcollective`)


([↑ Back to top](#content))


### Auditing

<pre><code><a href="#rpcaudit">rpcaudit</a> = 1
<a href="#rpcauditprovider">rpcauditprovider</a> = logfile
<a href="#pluginrpcauditlogfile">plugin.rpcaudit.logfile</a> = /var/log/mcollective-audit.log
</code>
</pre>

Optionally, MCollective can log the SimpleRPC agent commands it receives from admin users, recording both the command itself and some identifying information about the user who issued it. The caller ID of a command is determined by the [security plugin][security_plugin] being used.

MCollective ships with a local logging audit plugin, called `Logfile`, which saves audit info to a local file (different from the daemon log file). Log lines look like this:

    2010-12-28T17:09:03.889113+0000: reqid=319719cc475f57fda3f734136a31e19b: reqtime=1293556143 caller=cert=nagios@monitor1 agent=nrpe action=runcommand data={:process_results=>true, :command=>"check_mailq"}

Tthere are central loggers available from [the plugin directory][plugin_directory], and you can also write your own audit plugins; see [Writing Auditing Plugins][auditing] for more information.


#### `rpcaudit`

Whether to enable [SimpleRPC auditing][Auditing] for all SimpleRPC agent commands.

- _Default:_ `0`
- _Allowed values:_ `1`, `0`, `y`, `n` --- {{ badbool }}

#### `rpcauditprovider`

The name of the audit plugin to use whenever SimpleRPC commands are received.

- _Default:_ (nothing)
- _Sample value:_ `logfile`
- _Allowed values:_ The name of any installed audit plugin. {{ pluginname }}


#### `plugin.rpcaudit.logfile`

_When `rpcauditprovider == logfile`_

The file to write to when using the `logfile` audit plugin. **Note:** this file is not automatically rotated.

- _Default:_ `/var/log/mcollective-audit.log`


([↑ Back to top](#content))


### Authorization

<pre><code><a href="#rpcauthorization">rpcauthorization</a> = 1
<a href="#rpcauthprovider">rpcauthprovider</a> = action_policy
</code>
</pre>

Optionally, MCollective can refuse to execute agent commands unless they meet some requirement. The exact requirement is defined by an [authorization plugin][authorization].

See [SimpleRPC Authorization][authorization] for more details, including how to enable authorization for only certain agents.

The [actionpolicy][] plugin, which is provided in the [plugin directory][plugin_directory], is fairly popular and seems to meet many users' needs, when combined with a [security plugin][security_plugin] that provides a verified caller ID (such as the SSL plugin). [See its documentation][actionpolicy] for details.

#### `rpcauthorization`

Whether to enable [SimpleRPC authorization][Authorization] globally.

- _Default:_ `0`
- _Allowed values:_ `1`, `0`, `y`, `n` --- {{ badbool }}

#### `rpcauthprovider`

The plugin to use when globally managing authorization. See [SimpleRPC Authorization][authorization] for more details.

- _Default:_ (nothing)
- _Sample value:_ `action_policy`
- _Allowed values:_ The name of any installed authorization plugin. This uses different capitalization/formatting rules from the other plugin settings: if the name of the plugin (in the code) has any interior capital letters (e.g. `ActionPolicy`), you should use a lowercase value for the setting but insert an underscore before the place where the interior capital letter(s) would have gone (e.g. `action_policy`). If the name contains no interior capital letters, simply use a lowercase value with no other changes.


([↑ Back to top](#content))


Advanced Settings
-----

### Logging

<pre><code><a href="#loggertype">logger_type</a> = file
<a href="#loglevel">loglevel</a> = info
<a href="#logfile">logfile</a> = /var/log/mcollective.log
<a href="#keeplogs">keeplogs</a> = 5
<a href="#maxlogsize">max_log_size</a> = 2097152
<a href="#logfacility">logfacility</a> = user
</code>
</pre>

The MCollective server daemon can log to its own log file (which it will automatically rotate), or to the syslog. It can also log directly to the console, if you are running it in the foreground instead of daemonized.

Some of the settings below only apply if you are using log files, and some only apply if you are using syslog.

#### `logger_type`

How the MCollective server daemon should log. You generally want to use a file or syslog.

- _Default:_ `file`
- _Allowed values:_ `file`, `syslog`, `console`

#### `loglevel`

How verbosely to log.

- _Default:_ `info`
- _Allowed values:_ In increasing order of verbosity: `fatal`, `error` , `warn`, `info`, `debug`

#### `logfile`

_When `logger_type == file`_

Where the log file should be stored.

- _Default:_ (nothing; the package's default config file usually sets a platform-appropriate value)
- _Sample value:_ `/var/log/mcollective.log`

#### `keeplogs`

_When `logger_type == file`_

The number of log files to keep when rotating.

- _Default:_ `5`

#### `max_log_size`

_When `logger_type == file`_

Max size in bytes for log files before rotation happens.

- _Default:_ `2097152`

#### `logfacility`

_When `logger_type == syslog`_

The syslog facility to use.

- _Default:_ `user`


([↑ Back to top](#content))


### Platform Defaults

<pre><code><a href="#daemonize">daemonize</a> = 1
<a href="#activate_agents">activate_agents</a> = true
<a href="#soft_shutdown">soft_shutdown</a> = false
<a href="#soft_shutdown_timeout">soft_shutdown_timeout</a> = 5
<a href="#libdir">libdir</a> = /usr/libexec/mcollective
<a href="#sslcipher">ssl_cipher</a> = aes-256-cbc
</code>
</pre>

These settings generally shouldn't be changed by the user, but their values may vary by platform. The package you used to install MCollective should have created a config file with platform-appropriate values for these settings.

#### `daemonize`

Whether to fork and run the MCollective server daemon in the background.

This depends on your platform's init system. For example, newer Ubuntu releases require this to be false, while RHEL-derived systems require it to be true.

- _Default:_ `0` <!-- Actually nil but acts like false -->
- _Allowed values:_ `1`, `0`, `y`, `n` --- {{ badbool }}

#### `activate_agents`

When set to false, requires each agent be enabled individually with
their `plugin.$plugin_name.activate_agent` setting.

- _Default:_ true
- _Allowed values:_ Any boolean value

#### `soft_shutdown`

When set to true, soft_shutdown will delay the exit of the daemon
until all running agents have either ran to completion or timed out.

- _Default:_ false
- _Allowed values:_ Any boolean value

#### `soft_shutdown_timeout`

When set, soft_shutdown will terminate outstanding agents after this
amount of time has elapsed.

- _Default:_ unset
- _Allowed values:_ A positive integer

#### `libdir`

Where to look for plugins. Should be a single path or a list of paths separated by the {{ path_separator }}.

This setting is optional from 2.8.0 onwards.

- _Default:_ None
- _Sample value:_ `/usr/libexec/mcollective:/opt/mcollective`

#### `ssl_cipher`

The cipher to use for encryption. This is currently only relevant if you are using the [AES security plugin][security_aes].

This setting should be a standard OpenSSL cipher string. See `man enc` for a list.

- _Default:_ `aes-256-cbc`
