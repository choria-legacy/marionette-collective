---
layout: default
title: ActiveMQ Connector
toc: false
---

[STOMP]: http://stomp.codehaus.org/
[heartbeat]: http://stomp.github.io/stomp-specification-1.1.html#Heart-beating
[cipherstrings]: https://www.openssl.org/docs/apps/ciphers.html#CIPHER_STRINGS
[wildcard]: http://activemq.apache.org/wildcards.html
[subcollectives]: /mcollective/reference/basic/subcollectives.html
[activemq_config]: /mcollective/deploy/middleware/activemq.html


The ActiveMQ connector uses the [STOMP][] rubygem to connect to ActiveMQ servers.  It is specifically optimized for ActiveMQ
and uses features in ActiveMQ 5.5.0 and later.

This plugin requires version _1.2.2_ or newer of the Stomp gem.

## Differences between ActiveMQ connector and Stomp Connector

### Topic and Queue Names

The new connector uses different destination names from the old stomp connector.

MCollective uses the following destination names. This list uses standard [ActiveMQ destination wildcards][wildcard]. "COLLECTIVE" is the name of the collective being used; by default, this is `mcollective`, but if you are using [subcollectives][], each one is implemented as an equal peer of the default collective.

Topics:

- `ActiveMQ.Advisory.>` (built-in topics that all ActiveMQ producers and consumers need all permissions on)
- `COLLECTIVE.*.agent` (for each agent plugin, where the `*` is the name of the plugin)

Queues:

- `COLLECTIVE.nodes` (used for direct addressing; this is a single destination that uses JMS selectors, rather than a group of destinations)
- `COLLECTIVE.reply.>` (where the continued portion is a request ID)

Note especially that:

* We can now do direct addressing to specific nodes.
* Replies now go directly to the instigating client instead of being brodcast on a topic.

This has big impact on overall CPU usage by clients on busy networks, and also optimizes the traffic flow on
networks with many brokers.


## Configuring ActiveMQ

See [the ActiveMQ config reference][activemq_config] for details on configuring ActiveMQ for this connector. As recommended at the top of the reference, you should skim the sections you care about and edit an example config file while reading.


## Configuring MCollective

MCollective clients and servers use the same connector settings, although the value of settings involving credentials will vary.

### Failover Pools

A sample configuration can be seen below.  Note this plugin does not support the old style config of the Stomp connector.

{% highlight ini %}
connector = activemq
plugin.activemq.pool.size = 2
plugin.activemq.pool.1.host = stomp1
plugin.activemq.pool.1.port = 61613
plugin.activemq.pool.1.user = me
plugin.activemq.pool.1.password = secret

plugin.activemq.pool.2.host = stomp2
plugin.activemq.pool.2.port = 61613
plugin.activemq.pool.2.user = me
plugin.activemq.pool.2.password = secret
{% endhighlight %}

This gives it 2 servers to attempt to connect to, if the first one fails it will use the second.  Usernames and passwords can be set
with the environment variables `STOMP_USER`, `STOMP_PASSWORD`.

If you do not specify a port it will default to _61613_

You can also specify the following options for the Stomp gem, these are the defaults in the Stomp gem: <!-- last checked: v. 1.1.6 of the gem -->

{% highlight ini %}
plugin.activemq.initial_reconnect_delay = 0.01
plugin.activemq.max_reconnect_delay = 30.0
plugin.activemq.use_exponential_back_off = true
plugin.activemq.back_off_multiplier = 2
plugin.activemq.max_reconnect_attempts = 0
plugin.activemq.randomize = false
plugin.activemq.connect_timeout = 30
{% endhighlight %}

### Message Priority

ActiveMQ messages support priorities, you can pass in the needed priority header by setting:

{% highlight ini %}
plugin.activemq.priority = 4
{% endhighlight %}

### STOMP 1.1 Heartbeats

A common problem is that idle STOMP connections get expired by session
tracking firewalls and NAT devices.  Version 1.1 of the STOMP protocol
combats this with protocol level heartbeats, which can be configured
with these settings:

{% highlight ini %}
# Send heartbeats in 30 second intervals. This is the shortest supported period.
plugin.activemq.heartbeat_interval = 30

# By default if heartbeat_interval is set it will request STOMP 1.1 but support fallback
# to 1.0, but you can enable strict STOMP 1.1 only operation by disabling 1.0 fallback
plugin.activemq.stomp_1_0_fallback = 0

# Maximum amount of heartbeat read failures before retrying. 0 means never retry.
plugin.activemq.max_hbread_fails = 2

# Maximum amount of heartbeat lock obtain failures before retrying. 0 means never retry.
plugin.activemq.max_hbrlck_fails = 2
{% endhighlight %}

This feature is avaiable from version 2.4.0 and requires version
1.2.10 or newer of the stomp gem.

More information about STOMP heartbeats can be found [in the STOMP specification][heartbeat]

### Parameter reference

#### `plugin.activemq.connect_timeout`

Specify the timeout for the TCP+SSL connection to the middleware.

- _Default:_ 30
- _Allowed values:_ Any integer

#### `plugin.activemq.use_exponential_back_off`

Whether to use exponential backoff when reconnecting to the
middleware.

- _Default:_ true
- _Allowed values:_ A boolean value

#### `plugin.activemq.initial_reconnect_delay`

When `use_exponential_back_off` is set, the initial delay to use when
reconnecting to the middleware.

- _Default:_ 0.01
- _Allowed values:_ A positive number expressing time in seconds

#### `plugin.activemq.max_reconnect_delay`

When `use_exponential_back_off` is set, the maximum delay to use when
reconnecting to the middleware.

- _Default:_ 30
- _Allowed values:_ A number integer expressing time in seconds

#### `plugin.activemq.back_off_multiplier`

When `use_exponential_back_off` is set, the amount to increase the
delay by (up to `max_reconnect_delay`).

- _Default:_ 2
- _Allowed values:_ A positive integer

#### `plugin.activemq.max_reconnect_attempts`

The number of times to attempt to connect to the middleware.  0 means
no limit (retry forever).

- _Default:_ 0
- _Allowed values:_ Any integer

#### `plugin.activemq.heartbeat_interval`

Setting this value enables STOMP 1.1 heartbeats, and sets the interval
to send/receive heartbeat messages to that number of seconds.

- _Default:_ (no value)
- _Allowed values:_ An integer >= 30 (smaller values will be padded)

#### `plugin.activemq.stomp_1_0_fallback`

When `heartbeat_interval` is set it will request STOMP 1.1 but support fallback
to 1.0.  You can force STOMP 1.1 only operation by setting this to false.

- _Default:_ false
- _Allowed values:_ A boolean

#### `plugin.activemq.max_hbread_fails`

Maximum amount of heartbeat read failures to allow before assuming the
connection is dead and reconnecting.

- _Default:_ 2
- _Allowed values:_ Any integer

#### `plugin.activemq.max_hbrlck_fails`

Maximum amount of heartbeat lock obtain failures before assuming the
connection is dead and reconnecting.

- _Default:_ 2
- _Allowed values:_ Any integer

#### `plugin.activemq.priority`

Specifies the priority of the messages sent to ActiveMQ.  1 is the
lowest priority, 9 is the highest, and unspecified is the same as the
default value (4).

- _Default:_ no default
- _Allowed values:_ An integer in the range 1..9

#### `plugin.activemq.randomize`

Whether to randomize the order of the connection pool before connecting.

- _Default:_ false
- _Allowed values:_ A boolean value

#### `plugin.activemq.pool.size`

Specifies the size of the connector pool.

- _Default:_ no default
- _Allowed values:_ Any positive integer

#### `plugin.activemq.pool.1.host`

The hostname of this middleware server.

- _Default:_ no default
- _Allowed values:_ Any string value

#### `plugin.activemq.pool.1.port`

The port number to connect to for this middleware server.

- _Default:_ 61613
- _Allowed values:_ Any positive integer

#### `plugin.activemq.pool.1.user`

The username to connect with to this middleware server.  If the
`STOMP_USER` environment variable is set this value will be used
instead.

- _Default:_ The empty string ""
- _Allowed values:_ Any string value

#### `plugin.activemq.pool.1.password`

The password to connect with to this middleware server.  If the
`STOMP_PASSWORD` environment variable is set this value will be used
instead.

- _Default:_ The empty string ""
- _Allowed values:_ Any string value

#### `plugin.activemq.pool.1.ssl`

Whether to use TLS when connecting to this middleware server.

- _Default:_ false
- _Allowed values:_ Any boolean value

#### `plugin.activemq.pool.ssl.fallback`

Whether to allow unverified TLS if the ca/cert/key settings aren't set.

- _Default:_ false
- _Allowed values:_ Any boolean value

#### `plugin.activemq.pool.1.ssl.ca`

The CA certificate to use when verifying the middlewares
certificate.  Must be the fully-qualified path to a `.pem` file.

- _Default:_ (nothing)
- _Allowed values:_ A fully-qualified path

#### `plugin.activemq.pool.1.ssl.cert`

The certificate to present when connecting to the middleware.  Must be
the fully-qualified path to a `.pem` file.  MCollective will also
check the environment variable `MCOLLECTIVE_ACTIVEMQ_POOL1_SSL_CERT`
for the client's ssl cert.

- _Default:_ (nothing)
- _Allowed values:_ A fully-qualified path

#### `plugin.activemq.pool.1.ssl.key`

The private key corresponding to this node's certificate.  Must be the
fully-qualified path to a `.pem` file.  MCollective will also check
the environment variable `MCOLLECTIVE_ACTIVEMQ_POOL1_SSL_KEY` for the
client's ssl key.

- _Default:_ (nothing)
- _Allowed values:_ A fully-qualified path

#### `plugin.activemq.pool.1.ssl.ciphers`

The SSL ciphers to use when communicating with this middleware server.

- _Default:_ no default
- _Allowed values:_ A string supplying an [OpenSSL cipher suite][cipherstrings]
