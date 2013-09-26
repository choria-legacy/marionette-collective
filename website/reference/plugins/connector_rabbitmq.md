---
layout: default
title: RabbitMQ Connector
toc: false
---
[STOMP]: http://stomp.codehaus.org/
[RabbitStomp]: http://www.rabbitmq.com/stomp.html
[RabbitCLI]: http://www.rabbitmq.com/management-cli.html

The RabbitMQ connector uses the [STOMP] rubygem to connect to RabbitMQ servers.

This code will only work with version _1.2.2_ or newer of the Stomp gem.

## Differences between RabbitMQ connector and Stomp Connector

The RabbitMQ connector requires MCollective 2.0.0 or newer.

While this plugin still uses the Stomp protocol to connect to RabbitMQ it does use a nubmer of
RabbitMQ specific optimizations to work well and as such is a Stomp connector specific to the
RabbitMQ broker.

## Configuring RabbitMQ

Basic installation of the RabbitMQ broker is out of scope for this document apart from the
basic broker you need to enable the [Stomp plugi][RabbitStomp] and the [CLI Management Tool][RabbitCLI].

With that in place you need to create a few exchanges, topics and queues for each of your
sub collectives.

First we create a virtual host, user and some permissions on the vhost:

{% highlight console %}
rabbitmqadmin declare vhost=/mcollective
rabbitmqadmin declare user=mcollective password=changeme
rabbitmqadmin declare permission vhost=/mcollective user=mcollective configure=.* write=.* read=.*
{% endhighlight %}

Next we create the exchanges that MCollective needs. One for broadcast requests, other for direct addressing:

{% highlight console %}
rabbitmqadmin declare exchange vhost=/mcollective name=mcollective_broadcast type=topic
rabbitmqadmin declare exchange vhost=/mcollective name=mcollective_direct type=direct
{% endhighlight %}

If you want to federate exchanges you will also need third one for sending replies, see 'Federation' section for configuration details.

{%

{% highlight console %}
rabbitmqadmin declare exchange vhost=/mcollective name=mcollective_reply type=direct
{% endhighlight %}

## Configuring MCollective

### Common Options

### Failover Pools
A sample configuration can be seen below.

{% highlight ini %}
direct_addressing = 1

connector = rabbitmq
plugin.rabbitmq.pool.size = 2
plugin.rabbitmq.pool.1.host = rabbit1
plugin.rabbitmq.pool.1.port = 6163
plugin.rabbitmq.pool.1.user = mcollective
plugin.rabbitmq.pool.1.password = changeme

plugin.rabbitmq.pool.2.host = rabbit2
plugin.rabbitmq.pool.2.port = 6163
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
plugin.rabbitmq.vhost = /mcollective
{% endhighlight %}

### Federation

RabbitMQ federation only mirrors exchanges between nodes so replies need to be sent to exchange instead of queue.
To enable that, specify:

{% highlight ini %}
plugin.rabbitmq.use_reply_exchange = true
{% endhighlight %}

in client/server config file and add exchange for replies:

{% highlight ini %}
rabbitmqadmin declare exchange vhost=/mcollective name=mcollective_reply type=direct
{% endhighlight %}

Note that this change in config is backward-incompatible so you should upgrade all your MColective installations to same version.
