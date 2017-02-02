---
layout: default
title: RabbitMQ Connector
toc: false
---
[STOMP]: http://stomp.codehaus.org/
[heartbeat]: http://stomp.github.io/stomp-specification-1.1.html#Heart-beating
[RabbitStomp]: http://www.rabbitmq.com/stomp.html
[RabbitCLI]: http://www.rabbitmq.com/management-cli.html
[RabbitClustering]: https://www.rabbitmq.com/clustering.html
[cipherstrings]: https://www.openssl.org/docs/apps/ciphers.html#CIPHER_STRINGS

The RabbitMQ connector uses the [STOMP][] rubygem to connect to RabbitMQ servers.

This code will only work with version _1.2.2_ or newer of the Stomp gem.

## Differences between RabbitMQ connector and Stomp Connector

The RabbitMQ connector requires MCollective 2.0.0 or newer.

While this plugin still uses the Stomp protocol to connect to RabbitMQ it does use a nubmer of
RabbitMQ specific optimizations to work well and as such is a Stomp connector specific to the
RabbitMQ broker.

## Configuring RabbitMQ

Basic installation of the RabbitMQ broker is out of scope for this document apart from the
basic broker you need to enable the [Stomp plugin][RabbitStomp] and the [CLI Management Tool][RabbitCLI].

With that in place you need to create a few exchanges, topics and queues for each of your
sub collectives.

First we create a virtual host, two users (one to act as an administrator who
will create the exchanges we need later) and some permissions on the vhost:

{% highlight console %}
rabbitmqadmin declare vhost name=/mcollective
rabbitmqadmin declare user name=mcollective password=changeme tags=
rabbitmqadmin declare user name=admin password=changeme tags=administrator
rabbitmqadmin declare permission vhost=/mcollective user=mcollective configure='.*' write='.*' read='.*'
rabbitmqadmin declare permission vhost=/mcollective user=admin configure='.*' write='.*' read='.*'
{% endhighlight %}

(Note that a `tags=` declaration may be required for the mcollective user, although it's allowed to be empty. Also note that your shell probably requires quotes to protect the `*` from glob expansion.)

And then we need to create the exchanges that are needed for each collective:

{% highlight console %}
for collective in mcollective ; do
  rabbitmqadmin declare exchange --user=admin --password=changeme --vhost=/mcollective name=${collective}_broadcast type=topic
  rabbitmqadmin declare exchange --user=admin --password=changeme --vhost=/mcollective name=${collective}_directed type=direct
done
{% endhighlight %}

### Clustering
If you want to run multiple RabbitMQ's, say one per datacenter perhaps, you'll need to set them up as a cluster. If you don't you'll only receive the replies from the RabbitMQ that the broker you're talking to is connected to, instead of the whole network. Effectively, if you don't cluster you create a split-brain situation.

If you're using the [puppetlabs-mcollective](https://github.com/puppetlabs/puppetlabs-mcollective) module see its documentation on how to configure RabbitMQ for clustering. Otherwise you'll have to make the following changes yourself:

* Shutdown the RabbitMQ nodes;
* Modify the Erlang cookie at ``/var/lib/rabbitmq/.erlang.cookie``. It needs to be identical for all the nodes in a cluster;
* Wipe the database: ``rm -rf /var/lib/rabbitmq/mnesia``;
* Add an entry to ``/etc/rabbitmq/rabbitmq.config`` in the ``rabit`` section:
  {% highlight erlang %}
  {cluster_nodes, {['rabbit@rabbitmq1.example.com', 'rabbit2@rabbitmq2.example.com'], disc}},
  {cluster_partition_handling, ignore},
  {% endhighlight %}
* Start up the nodes.

Once these configuration changes are made you still need to join the nodes together. To do this follow the instructions on clustering [here][RabbitClustering].

## Configuring MCollective

### Common Options

### Failover Pools
A sample configuration can be seen below.

{% highlight ini %}
direct_addressing = 1

connector = rabbitmq
plugin.rabbitmq.vhost = /mcollective
plugin.rabbitmq.pool.size = 2
plugin.rabbitmq.pool.1.host = rabbit1
plugin.rabbitmq.pool.1.port = 61613
plugin.rabbitmq.pool.1.user = mcollective
plugin.rabbitmq.pool.1.password = changeme

plugin.rabbitmq.pool.2.host = rabbit2
plugin.rabbitmq.pool.2.port = 61613
plugin.rabbitmq.pool.2.user = mcollective
plugin.rabbitmq.pool.2.password = changeme
{% endhighlight %}

This gives it 2 servers to attempt to connect to, if the first one fails it will use the second.  Usernames and passwords can be set
with the environment variables STOMP_USER, STOMP_PASSWORD.

If you do not specify a port it will default to _61613_

You can also specify the following options for the Stomp gem, these are the defaults in the Stomp 1.2.2 gem:

{% highlight ini %}
plugin.rabbitmq.initial_reconnect_delay = 0.01
plugin.rabbitmq.max_reconnect_delay = 30.0
plugin.rabbitmq.use_exponential_back_off = true
plugin.rabbitmq.back_off_multiplier = 2
plugin.rabbitmq.max_reconnect_attempts = 0
plugin.rabbitmq.randomize = false
plugin.rabbitmq.timeout = -1
{% endhighlight %}

### Federation

RabbitMQ federation only mirrors exchanges between nodes so replies need to be
sent to an exchange instead of a queue.  In order to enable that add the
following snippet to your client configuration:

{% highlight ini %}
plugin.rabbitmq.use_reply_exchange = true
{% endhighlight %}

You will also need to create an exchange called `mcollective_reply` in your
rabbitmq vhost.  Assuming you are using the same vhost names from earlier in this
guide you can create this with.

{% highlight console %}
rabbitmqadmin declare exchange --user=admin --password=changeme --vhost=/mcollective name=mcollective_reply type=direct
{% endhighlight %}

Note: the `rabbitmq.use_reply_exchange` feature is available from version 2.4.1.

### STOMP 1.1 Heartbeats

A common problem is that idle STOMP connections get expired by session
tracking firewalls and NAT devices.  Version 1.1 of the STOMP protocol
combats this with protocol level heartbeats, which can be configured
with these settings:

{% highlight ini %}
# Send heartbeats in 30 second intervals. This is the shortest supported period.
plugin.rabbitmq.heartbeat_interval = 30

# By default if heartbeat_interval is set it will request STOMP 1.1 but support fallback
# to 1.0, but you can enable strict STOMP 1.1 only operation by disabling 1.0 fallback
plugin.rabbitmq.stomp_1_0_fallback = 0

# Maximum amount of heartbeat read failures before retrying. 0 means never retry.
plugin.rabbitmq.max_hbread_fails = 2

# Maxium amount of heartbeat lock obtain failures before retrying. 0 means never retry.
plugin.rabbitmq.max_hbrlck_fails = 0
{% endhighlight %}

This feature is avaiable from version 2.4.0 and requires version
1.2.10 or newer of the stomp gem.

More information about STOMP heartbeats can be found [in the STOMP specification][heartbeat]

### Parameter reference

#### `plugin.rabbitmq.connect_timeout`

Specify the timeout for the TCP+SSL connection to the middleware.

- _Default:_ 30
- _Allowed values:_ Any integer

#### `plugin.rabbitmq.use_exponential_back_off`

Whether to use exponential backoff when reconnecting to the
middleware.

- _Default:_ true
- _Allowed values:_ A boolean value

#### `plugin.rabbitmq.initial_reconnect_delay`

When `use_exponential_back_off` is set, the initial delay to use when
reconnecting to the middleware.

- _Default:_ 0.01
- _Allowed values:_ A positive number expressing time in seconds

#### `plugin.rabbitmq.max_reconnect_delay`

When `use_exponential_back_off` is set, the maximum delay to use when
reconnecting to the middleware.

- _Default:_ 30
- _Allowed values:_ A number integer expressing time in seconds

#### `plugin.rabbitmq.back_off_multiplier`

When `use_exponential_back_off` is set, the amount to increase the
delay by (up to `max_reconnect_delay`).

- _Default:_ 2
- _Allowed values:_ A positive integer

#### `plugin.rabbitmq.max_reconnect_attempts`

The number of times to attempt to connect to the middleware.  0 means
no limit (retry forever).

- _Default:_ 0
- _Allowed values:_ Any integer

#### `plugin.rabbitmq.heartbeat_interval`

Setting this value enables STOMP 1.1 heartbeats, and sets the interval
to send/receive heartbeat messages to that number of seconds.

- _Default:_ (no value)
- _Allowed values:_ An integer >= 30 (smaller values will be padded)

#### `plugin.rabbitmq.stomp_1_0_fallback`

When `heartbeat_interval` is set it will request STOMP 1.1 but support fallback
to 1.0.  You can force STOMP 1.1 only operation by setting this to false.

- _Default:_ false
- _Allowed values:_ A boolean

#### `plugin.rabbitmq.max_hbread_fails`

Maximum amount of heartbeat read failures to allow before assuming the
connection is dead and reconnecting.

- _Default:_ 2
- _Allowed values:_ Any integer

#### `plugin.rabbitmq.max_hbrlck_fails`

Maximum amount of heartbeat lock obtain failures before assuming the
connection is dead and reconnecting.  This setting is best left at 0
due to MCollective's usage patterns.

- _Default:_ 0
- _Allowed values:_ Any integer

#### `plugin.rabbitmq.randomize`

Whether to randomize the order of the connection pool before connecting.

- _Default:_ false
- _Allowed values:_ A boolean value

#### `plugin.rabbitmq.pool.size`

Specifies the size of the connector pool.

- _Default:_ no default
- _Allowed values:_ Any positive integer

#### `plugin.rabbitmq.pool.1.host`

The hostname of this middleware server.

- _Default:_ no default
- _Allowed values:_ Any string value

#### `plugin.rabbitmq.pool.1.port`

The port number to connect to for this middleware server.

- _Default:_ 61613
- _Allowed values:_ Any positive integer

#### `plugin.rabbitmq.pool.1.user`

The username to connect with to this middleware server.  If the
`STOMP_USER` environment variable is set this value will be used
instead.

- _Default:_ The empty string ""
- _Allowed values:_ Any string value

#### `plugin.rabbitmq.pool.1.password`

The password to connect with to this middleware server.  If the
`STOMP_PASSWORD` environment variable is set this value will be used
instead.

- _Default:_ The empty string ""
- _Allowed values:_ Any string value

#### `plugin.rabbitmq.pool.1.ssl`

Whether to use TLS when connecting to this middleware.

- _Default:_ false
- _Allowed values:_ Any boolean value

#### `plugin.rabbitmq.pool.ssl.fallback`

Whether to allow unverified TLS if the ca/cert/key settings aren't set.

- _Default:_ false
- _Allowed values:_ Any boolean value

#### `plugin.rabbitmq.pool.1.ssl.ca`

The CA certificate to use when verifying the middleware's
certificate.  Must be the fully-qualified path to a `.pem` file.

- _Default:_ (nothing)
- _Allowed values:_ A fully-qualified path

#### `plugin.rabbitmq.pool.1.ssl.cert`

The certificate to present when connecting to the middleware. Must be the
fully-qualified path to a `.pem` file.  MCollective will also check
the environment variable `MCOLLECTIVE_RABBITMQ_POOL1_SSL_CERT` for the
client's ssl cert.

- _Default:_ (nothing)
- _Allowed values:_ A fully-qualified path

#### `plugin.rabbitmq.pool.1.ssl.key`

The private key corresponding to this node's certificate.  Must be the
fully-qualified path to a `.pem` file.  MCollective will also check
the environment variable `MCOLLECTIVE_RABBITMQ_POOL1_SSL_KEY` for the
client's ssl key.

- _Default:_ (nothing)
- _Allowed values:_ A fully-qualified path

#### `plugin.rabbitmq.pool.1.ssl.ciphers`

The SSL ciphers to use when communicating with the middleware.

- _Default:_ no default
- _Allowed values:_ A string supplying an [OpenSSL cipher suite][cipherstrings]

#### `plugin.rabbitmq.agents_multiplex`

Whether to use a single target for all agents in a node. This is an optimization that may make sense when running collectives with several thousands of nodes in order to reduce the number of subscriptions in the message broker.
This is a trade-off between increasing network traffic by delivering messages to all nodes - and letting them select messages they care about - versus increasing work in the message broker to handle large numbers of subscriptions.

- _Default:_ false
- _Allowed values:_ A boolean value

