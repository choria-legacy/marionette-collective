---
title: "MCollective » Configure » Clients"
layout: default
---

[server_config_ssl_plugin]: ./server.html#ssl-plugin-settings
[discovery]: /mcollective/reference/ui/filters.html
[middleware]: /mcollective/deploy/middleware/
[activemq_tls_verified]: /mcollective/deploy/middleware/activemq.html#tls-credentials
[activemq_connector]: /mcollective/reference/plugins/connector_activemq.html
[rabbitmq_connector]: /mcollective/reference/plugins/connector_rabbitmq.html
[security_overview]: /mcollective/security.html
[ssl_plugin]: /mcollective/reference/plugins/security_ssl.html
[discovery_plugins]: /mcollective/reference/plugins/discovery.html
[subcollectives]: /mcollective/reference/basic/subcollectives.html
[security_aes]: /mcollective/reference/plugins/security_aes.html

{% capture badbool %}**Note:** Use these exact values only; do not use "true" or "false."{% endcapture %}

{% capture pluginname %}**Note:** Capitalization of plugin names doesn't matter; MCollective normalizes it before loading the plugin.{% endcapture %}

{% capture path_separator %}system path separator (colon \[`:`\] on \*nix, semicolon \[`;`\] on Windows){% endcapture %}



This document describes MCollective client configuration in MCollective 2.0.0 and higher. Older versions may lack certain features.


Example / Index
-----

The following is an example MCollective client config file showing all of the major groups of settings. All of the setting names styled as links can be clicked, and will take you down the page to a full description of that setting.

[See below the example for a full description of the config file location and format.](#the-client-config-files)

<pre><code># ~/.mcollective
# or
# /etc/mcollective/client.cfg

# <a href="#connector-settings">Connector settings (required):</a>
# -----------------------------

<a href="#connector">connector</a> = activemq
<a href="#directaddressing">direct_addressing</a> = 1

# <a href="#activemq-connector-settings">ActiveMQ connector settings:</a>
plugin.activemq.max_reconnect_attempts = 5
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

# <a href="#rabbitmq-connector-settings">RabbitMQ connector settings:</a>
plugin.rabbitmq.vhost = /mcollective
plugin.rabbitmq.pool.size = 1
plugin.rabbitmq.pool.1.host = middleware.example.net
plugin.rabbitmq.pool.1.port = 61613
# ... etc., similar to activemq settings

# <a href="#security-plugin-settings">Security plugin settings (required):</a>
# -----------------------------------

<a href="#securityprovider">securityprovider</a> = ssl

# <a href="#ssl-plugin-settings">SSL plugin settings:</a>
plugin.ssl_server_public = /Users/nick/mcollective.d/credentials/certs/mcollective-servers.pem
plugin.ssl_client_private = /Users/nick/mcollective.d/credentials/private_keys/nick-mco.pem
plugin.ssl_client_public = /Users/nick/mcollective.d/credentials/certs/nick-mco.pem

# <a href="#psk-plugin-settings">PSK plugin settings:</a>
plugin.psk = j9q8kx7fnuied9e

# <a href="#interface-settings">Interface settings (optional):</a>
# ------------------------------

# <a href="#discovery">Discovery settings:</a>

<a href="#defaultdiscoverymethod">default_discovery_method</a> = mc
# <a href="#defaultdiscoveryoptions">default_discovery_options</a> = /etc/mcollective/nodes.txt

# <a href="#performance">Performance settings:</a>

<a href="#directaddressingthreshold">direct_addressing_threshold</a> = 10
<a href="#ttl">ttl</a> = 60
<a href="#discovery_timeout">discovery_timeout</a> = 2
<a href="#publish_timeout">publish_timeout</a> = 2
<a href="#threaded">threaded</a> = false
<a href="#connectiontimeout">connection_timeout</a> = 3

# <a href="#miscellaneous">Miscellaneous settings:</a>

<a href="#color">color</a> = 1
<a href="#rpclimitmethod">rpclimitmethod</a> = first

# <a href="#subcollectives">Subcollectives (optional):</a>
# -----------------------------------

<a href="#collectives">collectives</a> = mcollective,uk_collective
<a href="#maincollective">main_collective</a> = mcollective

# <a href="#advanced-settings">Advanced settings and platform defaults:</a>
# -----------------------------------

<a href="#loggertype">logger_type</a> = console
<a href="#loglevel">loglevel</a> = warn
<a href="#logfile">logfile</a> = /var/log/mcollective.log
<a href="#keeplogs">keeplogs</a> = 5
<a href="#maxlogsize">max_log_size</a> = 2097152
<a href="#logfacility">logfacility</a> = user
<a href="#libdir">libdir</a> = /usr/libexec/mcollective
<a href="#rpchelptemplate">rpchelptemplate</a> = /etc/mcollective/rpc-help.erb
<a href="#helptemplatedir">helptemplatedir</a> = /etc/mcollective
<a href="#sslcipher">ssl_cipher</a> = aes-256-cbc
</code>
</pre>


The Client Config File(s)
-----

The `mco` client is usually run interactively from an admin workstation, but can also be run by scripts on a server.

These cases have different needs. In the first, the configuration and credentials should be per-user; in the second, they should be at the system level with restricted visibility of the credentials. MCollective solves this by having two locations for the client configuration:

* `~/.mcollective` --- A `.mcollective` file in the current user's home directory. If this file exists, `mco` will use it instead of the global config file.
* `/etc/mcollective/client.cfg` --- A global client config file, which will be used if `~/.mcollective` doesn't exist. If you are using this file, read access to it and the external credentials it refers to should be strictly controlled, probably limited to the root user.

### File Format

Each line consists of a setting, an equals sign, and a value:

    # setting = value
    connector = activemq

The spaces on either side of the equals sign are optional. Lines starting with a `#` are comments.

> **Note on Boolean Values:** MCollective's config code does not have consistent handling of boolean values. Many of the core settings will accept values of `1/0` and `y/n`, but will fail to handle `true/false`; additionally, each plugin can handle boolean values differently, and some of them do not properly handle the `y/n` values accepted by the core settings.
>
> Nearly all known plugins and core settings accept `1` and `0`. Until further notice, you should always use these for all boolean settings, as no other values are universally safe.

### Plugin Config Directory (Optional)

Many of MCollective's settings are named with the format `plugin.<NAME>.<SETTING_NAME>`. These settings can optionally be put in separate files, in the `/etc/mcollective/plugin.d/` directory. If you are using the mco client in system-level scripts, this can let the client and the server daemon share some settings, but it isn't particularly useful when you're doing per-user client configuration, and there's no equivalent `plugin.d` directory in the user's home directory.

To move a `plugin.<NAME>.<SETTING_NAME>` setting to an external file, put it in `/etc/mcollective/plugin.d/<NAME>.cfg`, and use only the `<SETTING_NAME>` segment of the setting. So this:

    # /etc/mcollective/server.cfg
    plugin.puppet.splay = true

...is equivalent to:

    # /etc/mcollective/plugin.d/puppet.cfg
    splay = true

Note that this doesn't work for settings like `plugin.psk`, since they have no `<SETTING_NAME>` segment; a setting must have at least three segments to go in a plugin.cfg file.

### Best Practices

Due to the user-centric nature of client configuration and the need to keep client private keys secure and isolated, it doesn't make as much sense to manage client config files with Puppet (or other config management software). In fact, creating a Puppet-based client configuration toolkit is likely to be a non-trivial effort.

Instead, we recommend manually distributing a partial configuration file with most of the connector settings filled out, and allowing your admin users to finish their configuration based on their own credentials. Include hints for the settings they'll need to fill in:

    plugin.ssl_client_private = <YOUR PRIVATE KEY FILE>


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
- **`plugin.activemq.pool.1.ssl.ca`** --- _(When `ssl == 1`)_ The CA certificate to use when verifying ActiveMQ's certificate. Must be the fully-qualified path to a `.pem` file. _Default:_ (nothing)
- **`plugin.activemq.pool.1.ssl.cert`** --- _(When `ssl == 1`)_ The certificate to present when connecting to ActiveMQ. Must be the fully-qualified path to a `.pem` file. As of version 2.3.2 MCollective will also check the environment variable `MCOLLECTIVE_ACTIVEMQ_POOL1_SSL_CERT` for
the client's ssl cert. _Default:_ (nothing)
- **`plugin.activemq.pool.1.ssl.key`** --- _(When `ssl == 1`)_ The private key corresponding to this node's certificate. Must be the fully-qualified path to a `.pem` file. As of version 2.3.2 MCollective will also check the environment variable `MCOLLECTIVE_ACTIVEMQ_POOL1_SSL_KEY` for
the client's ssl key. _Default:_ (nothing)

#### RabbitMQ Connector Settings

The RabbitMQ connector uses very similar settings to the ActiveMQ connector, with the same `.pool.1.host` style of setting names.

[See the RabbitMQ connector documentation][rabbitmq_connector] for more complete details.


([↑ Back to top](#content))


### Security Plugin Settings

<pre><code><a href="#securityprovider">securityprovider</a> = ssl

# <a href="#ssl-plugin-settings">SSL plugin settings:</a>
plugin.ssl_server_public = /Users/nick/mcollective.d/credentials/certs/mcollective-servers.pem
plugin.ssl_client_private = /Users/nick/mcollective.d/credentials/private_keys/nick-mco.pem
plugin.ssl_client_public = /Users/nick/mcollective.d/credentials/certs/nick-mco.pem

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

- **`plugin.ssl_server_public`** --- The fully-qualified path to the server public key file, which must be in `.pem` format.
- **`plugin.ssl_client_private`** --- The fully-qualified path to the client private key file, which must be in `.pem` format.
- **`plugin.ssl_client_public`** --- The fully-qualified path to the client public key file, which must be in `.pem` format.

The server uses different settings, which are covered in the [server config reference][server_config_ssl_plugin]:

- `plugin.ssl_server_private`
- `plugin.ssl_server_public`
- `plugin.ssl_client_cert_dir`


#### PSK Plugin Settings

> **Note:** The only credential used by this plugin is a single shared password, which all servers and admin users have a copy of.

- **`plugin.psk`** --- The shared passphrase. If the `MCOLLECTIVE_PSK` environment variable is set, MCollective will use its value instead of this setting.


([↑ Back to top](#content))




Interface Settings
-----

<pre><code># <a href="#discovery">Discovery settings:</a>

<a href="#defaultdiscoverymethod">default_discovery_method</a> = mc
# <a href="#defaultdiscoveryoptions">default_discovery_options</a> = /etc/mcollective/nodes.txt

# <a href="#performance">Performance settings:</a>

<a href="#directaddressingthreshold">direct_addressing_threshold</a> = 10
<a href="#ttl">ttl</a> = 60

# <a href="#miscellaneous">Miscellaneous settings:</a>

<a href="#color">color</a> = 1
<a href="#rpclimitmethod">rpclimitmethod</a> = first
</code>
</pre>


These settings affect the user-facing behavior of the `mco` client. They generally have sensible defaults and can be ignored, but you can also modify them to match your day-to-day usage.

### Discovery

The mco client always "discovers" a list of nodes before issuing requests. For broadcast requests, this is the list of expected responses to the request, and the client will stop waiting once every node has replied. For directed requests, the list is used as the list of destinations as well as the list of expected responses.

Discovery is [performed with command-line filters][discovery], which can operate on identity, facts, classes, agent plugins, or custom data plugins.

The default `mc` discovery method uses dummy MCollective messages; this is maximally versatile and requires no central inventory, but entails a wait for responses before mco can send the request. There are other discovery plugins available, all of which trade features for speed.


#### `default_discovery_method`

The default method to use for [discovery][]; you can specify discovery methods per command with the `--dm METHOD` option.

Discovery methods are provided by [discovery plugins][discovery_plugins]; run `mco plugin doc` and see the "Discovery Methods" section to see a list of available discovery plugins on your system.

- _Default:_ `mc`
- _Allowed values:_ Any installed discovery plugin

#### `default_discovery_options`

Options to pass to the discovery plugin. This acts as a default value for the `--do OPTIONS` command-line flag.

**Most discovery methods do not use this,** and there isn't a common format for its value; it's parsed independently by each discovery plugin.

The only common discovery method that uses this setting is `flatfile`, where it should be the filename of a list of nodes (with one node identity per line). Setting the following options:

    default_discovery_method = flatfile
    default_discovery_options = /etc/mcollective/nodes.txt

...is the equivalent of specifying the option `--nodes /etc/mcollective/nodes.txt` (or the pair `--dm flatfile --do /etc/mcollective/nodes.txt`) for every command, except those where you explicitly specify something like `--dm mc`.

- _Default:_ (nothing)


### Performance

#### `direct_addressing_threshold`

If [direct addressing](#directaddressing) is enabled and [discovery][] returns few nodes --- less than or equal to the value of this setting --- `mco` will automatically translate a broadcast request into several direct requests. This saves load on your whole infrastructure, since uninvolved servers will not have to deserialize and validate the message.

- _Default:_ `10`
- _Allowed values:_ Any positive integer


#### `ttl`

The default TTL for requests. You can specify TTL per command with the `--ttl` option.

Any server that receives a request after its TTL has expired will reject it. Since the recommend SSL security plugin signs the TTL, it cannot be altered or spoofed; this provides some protection from replay attacks.

- _Default:_ `60`
- _Allowed values:_ Any positive integer

#### `discovery_timeout`

Control the timeout for how long to discover nodes.  This can be
useful to increase for larger environments.

- _Default:_ `2`
- _Allowed values:_ Any positive integer

#### `publish_timeout`

Increase the timeout for how long the request publishing step can
take.  This can be useful to increase for larger environments.

- _Default:_ `2`
- _Allowed values:_ Any positive integer

#### `threaded`

If [threaded](#threaded) mode is enabled, the client will spawn a
receiving thread independent of the thread that sends requests,
allowing responses to be handled as the are available, rather than
after making the requests.  This can greatly increase the number of
nodes that can be addressed at one time when using direct addressing.

- _Default_: `false`
- _Allowed values:_ Any boolean value

#### `connection_timeout`

If specified, the client will abort if the connection has not been
established after `connection_timeout` seconds.

- _Default_: unspecified (no timeout)
- _Allowed values:_ Any positive integer

### Miscellaneous

#### `color`

Whether to use color when displaying text on the console.

- _Default:_ `1` on \*nix systems; `0` on Windows
- _Allowed values:_ `1`, `0`, `y`, `n` --- {{ badbool }}

#### `rpclimitmethod`

How `mco` should choose which nodes to message, when using the `--limit-nodes` option.

- _Default:_ `first`
- _Allowed values:_ `first`, `random`


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

On the client side, mco will only send requests to subcollectives that are mentioned in its config file. It will default to sending requests to its `main_collective`.

> #### Shared Configuration
>
> If you are using any additional collectives (besides the default `mcollective` collective), your middleware must be configured to permit traffic on those collectives. See the middleware deployment guide for your specific middleware to see how to do this:
>
> * ActiveMQ: [Subcollective topic/queue names](/mcollective/deploy/middleware/activemq.html#topic-and-queue-names) --- [Multi-subcollective authorization example](/mcollective/deploy/middleware/activemq.html#detailed-restrictions-with-multiple-subcollectives)


#### `collectives`

A comma-separated list (spaces OK) of [subcollectives][] mco can send requests to.

- _Default:_ `mcollective`
- _Sample value:_ `mcollective,uk_collective`

#### `main_collective`

The default collective to send requests to; requests without an explicit collective will go here. You can specify another collective on the command line with the `--target` option.

- _Default:_ (the first value of [the `collectives` setting](#collectives), usually `mcollective`)


([↑ Back to top](#content))



Advanced Settings
-----

These settings can generally be ignored, as appropriate values should have been set by the package you installed MCollective with.

### Logging

<pre><code><a href="#loggertype">logger_type</a> = console
<a href="#loglevel">loglevel</a> = warn
<a href="#logfile">logfile</a> = /var/log/mcollective.log
<a href="#keeplogs">keeplogs</a> = 5
<a href="#maxlogsize">max_log_size</a> = 2097152
<a href="#logfacility">logfacility</a> = user
</code>
</pre>

By default, the `mco` client logs directly to the console with a loglevel of `warn`. This is generally what you want. You can get more information by setting the `loglevel` to `info` or `debug`, and you can redirect the log to a file by changing the `logger_type`.

The other log settings are mostly applicable to the server daemon, rather than the client. Some settings only apply if you are using log files, and some only apply if you are using syslog.

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

<pre><code><a href="#libdir">libdir</a> = /usr/libexec/mcollective
<a href="#rpchelptemplate">rpchelptemplate</a> = /etc/mcollective/rpc-help.erb
<a href="#helptemplatedir">helptemplatedir</a> = /etc/mcollective
<a href="#sslcipher">ssl_cipher</a> = aes-256-cbc
</code>
</pre>

#### `libdir`

Where to look for plugins. Should be a single path or a list of paths separated by the {{ path_separator }}.

By default, this setting is blank, but the package you installed MCollective with should supply a default server.cfg file with a platform-appropriate value for this setting. **If server.cfg has no value for this setting, MCollective will not work.**

- _Default:_ (nothing; the package's default config file usually sets a platform-appropriate value)
- _Sample value:_ `/usr/libexec/mcollective:/opt/mcollective`


#### `rpchelptemplate`

The path to one particular ERB template used for part of MCollective's interactive help.

- _Default:_ If it exists, `rpc-help.erb` in the same directory as the current config file; otherwise, `/etc/mcollective/rpc-help.erb`

#### `helptemplatedir`

The path to a directory containing all of MCollective's ERB help templates.

This setting is generally only useful if you installed MCollective without a package, in which case the help templates may be stored with the source instead of installed in the `/etc/mcollective` directory.

- _Default:_ The directory containing the `rpchelptemplate` file, usually `/etc/mcollective`
- _Allowed values:_ Any fully qualified path on disk

#### `ssl_cipher`

The cipher to use for encryption. This is currently only relevant if you are using the [AES security plugin][security_aes].

This setting should be a standard OpenSSL cipher string. See `man enc` for a list.

- _Default:_ `aes-256-cbc`
