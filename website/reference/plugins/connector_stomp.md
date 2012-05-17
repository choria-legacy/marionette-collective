---
layout: default
title: STOMP Connector
disqus: true
---
[STOMP]: http://stomp.codehaus.org/

# {{page.title}}

The stomp connector uses the [STOMP] rubygem to connect to compatible servers.  This is known to work with ActiveMQ and Stompserver.  Anecdotal evidence suggests it works with RabbitMQ's Stomp plugin.

This code will only work with version _1.1_ and _1.1.6_ or newer of the Stomp gem, the in between versions have threading issues.

As this connector tries to be as generic as possible it is hard to support all the advanced features of MCollective using it.  We do not recommend you use the directed mode
using this plugin, instead look towards specific ones written for ActiveMQ or your chosen middleware.

## Middleware Layout

For broadcast messages this connector will create _topics_ with names like _/topic/&lt;collective&gt;.&lt;agent&gt;.command_ and replies will go to
_/topic/&lt;collective&gt;.&lt;agent&gt;.reply_

For directed messages it will create queues with names like _/queue/&lt;collective&gt;.mcollective.&lt;md5 hash of identity&gt;_.

You should configure appropriate ACLs on your middleware to allow this scheme

## Configuring

### Common Options
The most basic configuration method is supported in all versions of the gem:

{% highlight ini %}
connector = stomp
plugin.stomp.base64 = false
plugin.stomp.host = stomp.my.net
plugin.stomp.port = 6163
plugin.stomp.user = me
plugin.stomp.password = secret
{% endhighlight %}

You can override all of these settings using environment variables STOMP_SERVER, STOMP_PORT, STOMP_USER, STOMP_PASSWORD.  It is recommended that your _client.cfg_ do not have usernames and passwords in it, users should set their own in the environment.

If you are seeing issues with the Stomp gem logging protocol errors and resetting your connections, especially if you are using Ruby on Rails then set the _plugin.stomp.base64_ to true, this adds an additional layer of encoding on packets to make sure they don't interfere with UTF8 encoding used in Rails.

### Failover Pools
Newer versions of the Stomp gem supports failover between multiple Stomp servers, you need at least _1.1.6_ to use this.

If you are using version _1.1.9_ and newer of the Stomp Gem and this method of configuration you will also receive more detailed
logging about connections, failures and other significant events.

{% highlight ini %}
connector = stomp
plugin.stomp.pool.size = 2
plugin.stomp.pool.host1 = stomp1
plugin.stomp.pool.port1 = 6163
plugin.stomp.pool.user1 = me
plugin.stomp.pool.password1 = secret

plugin.stomp.pool.host2 = stomp2
plugin.stomp.pool.port2 = 6163
plugin.stomp.pool.user2 = me
plugin.stomp.pool.password2 = secret
{% endhighlight %}

This gives it 2 servers to attempt to connect to, if the first one fails it will use the second.  As before usernames and passwords can be set with STOMP_USER, STOMP_PASSWORD.

If you do not specify a port it will default to _6163_

When using pools you can also specify the following options, these are the defaults in the Stomp 1.1.6 gem:

{% highlight ini %}
plugin.stomp.pool.initial_reconnect_delay = 0.01
plugin.stomp.pool.max_reconnect_delay = 30.0
plugin.stomp.pool.use_exponential_back_off = true
plugin.stomp.pool.back_off_multiplier = 2
plugin.stomp.pool.max_reconnect_attempts = 0
plugin.stomp.pool.randomize = false
plugin.stomp.pool.timeout = -1
plugin.stomp.pool.connect_timeout = 30
{% endhighlight %}

### Message Priority

As of version 5.4 of ActiveMQ messages support priorities, you can pass in the needed
priority header by setting:

{% highlight ini %}
plugin.stomp.priority = 4
{% endhighlight %}
