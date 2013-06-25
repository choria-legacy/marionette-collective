---
layout: default
title: ActiveMQ Connector
toc: false
---

[STOMP]: http://stomp.codehaus.org/
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
plugin.activemq.timeout = -1
{% endhighlight %}

### Message Priority

ActiveMQ messages support priorities, you can pass in the needed priority header by setting:

{% highlight ini %}
plugin.activemq.priority = 4
{% endhighlight %}
