---
layout: default
title: ActiveMQ Connector
toc: false
---
[STOMP]: http://stomp.codehaus.org/

The ActiveMQ connector uses the [STOMP] rubygem to connect to ActiveMQ servers.  It is specifically optimiszed for ActiveMQ
and uses features in ActiveMQ 5.5.0 and later.

This plugin requires version _1.2.2_ or newer of the Stomp gem. (Older versions don't properly support SSL. If you aren't securing traffic, you can use versions as old as 1.1.8, but no earlier.)

## Differences between ActiveMQ connector and Stomp Connector

The ActiveMQ connector requires MCollective 2.0.0 or newer and introduce a new structure to the middleware messsages.

 * Replies goes direct to clients using short lived queues
 * Agent topics are called */topic/&lt;collective&gt;.&lt;agent_name&gt;.agent*
 * Support for point to point messages are added by using _/queue/&lt;collective&gt;.nodes_ and using JMS selectors.

The use of short lived queues mean that replies are now going to go back only to the person who sent the request.
This has big impact on overall CPU usage by clients on busy networks but also optimize the traffic flow on
networks with many brokers.

Point to Point messages means each node has a unique subscription, the approach using JMS Selectors means
internally to ActiveMQ only a single thread will be dedicated to this rather than 1 per connected node.

Before using this plugin you will need to make appropriate adjustments to your ActiveMQ Access Control Lists.

## Configuring ActiveMQ
For best behavior there are a few settings you need in your _activemq.xml_

### Remove unused queues
We use uniquely named queues for replies.  As queues will live forever we need to get ActiveMQ to remove
queues we are done with else they will just add up and grow forever.

{% highlight xml %}
<destinationPolicy>
  <policyMap>
    <policyEntries>
      <policyEntry queue="*.reply.>" gcInactiveDestinations="true" inactiveTimoutBeforeGC="300000" />
    </policyEntries>
  </policyMap>
</destinationPolicy>
{% endhighlight %}

The above policy will instruct ActiveMQ to remove dead queues after 5 minutes.

### Optimize network usage for direct requests in a network of brokers
If you are using a network of brokers you will need to make a big change to how that works.
At present we tend to have 1 bi-directional connection for everything, with direct requests
we dedicate a bi-directional connection for these queues leaving the other just for topics.

{% highlight xml %}
<networkConnectors>
  <networkConnector
        name="stomp1-stomp2-topics"
        uri="static:(tcp://stomp2.xx.net:61616)"
        userName="amq"
        password="secret"
        duplex="true"
        decreaseNetworkConsumerPriority="true"
        networkTTL="2"
        dynamicOnly="true">
        <excludedDestinations>
                <queue physicalName=">" />
        </excludedDestinations>
  </networkConnector>
  <networkConnector
        name="stomp1-stomp2-queues"
        uri="static:(tcp://stomp2.xx.net:61616)"
        userName="amq"
        password="secret"
        duplex="true"
        decreaseNetworkConsumerPriority="true"
        networkTTL="2"
        dynamicOnly="true"
        conduitSubscriptions="false">
        <excludedDestinations>
                <topic physicalName=">" />
        </excludedDestinations>
  </networkConnector>
</networkConnectors>
{% endhighlight %}

You will need to adjust the TTL for your network.  Note the queue connection has a different
_conduitSubscriptions_ policy than the topic one, you have to create these different connections
and set this policy for everything to work correctly.

## Configuring MCollective

### Common Options
The most basic configuration method is supported in all versions of the gem:

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
with the environment variables STOMP_USER, STOMP_PASSWORD.

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
