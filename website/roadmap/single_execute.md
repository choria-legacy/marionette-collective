---
layout: mcollective
title: Single Node Execution
disqus: true
---

# {{page.title}}

|                    |         |
|--------------------|---------|
|Target release cycle|**1.0.x**|

## Overview

With agents like the naggernotify agent you want to be able to use the MC API
but only have 1 of the machines in your cluster that runs the agent actually
react on this.  The middleware systems support this with typical Queues, it
should be possible to add a mode to the RPC requests that allow this:

{% highlight ruby %}
nagger = rpcclient("naggernotify")

nagger.sendmsg(:subject=>"foo", :recipent=>"boxcar://rip...", :message => "hello world", :single_delivery => true)
{% endhighlight %}

The effect of the _:single`_`delivery_ option would be that if there are 50
machines with this agent on, 1 and only 1 of them will actually react to the
request.  This will be a cheap way to get resiliant services on your network.

The API should handle the single delivery argument on any RPC request and in
that case put the request in a queue with a short timeout rather than on a topic
for broadcasting.

This will mean all agents would need to additionally listen on a queue but this
is not a big deal
