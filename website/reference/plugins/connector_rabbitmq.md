---
layout: default
title: RabbitMQ Connector
toc: false
---
[STOMP]: http://stomp.codehaus.org/
[RabbitStomp]: http://www.rabbitmq.com/stomp.html
[RabbitCLI]: http://www.rabbitmq.com/management-cli.html
[RabbitClustering]: https://www.rabbitmq.com/clustering.html

The RabbitMQ connector uses the [STOMP] rubygem to connect to RabbitMQ servers.

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
