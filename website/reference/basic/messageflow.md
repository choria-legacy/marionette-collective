---
layout: mcollective
title: Message Flow
disqus: true
---
[MessageFormat]: /reference/basic/messageformat.html
[ActiveMQClusters]: /reference/integration/activemq_clusters.html
[SecurityWithActiveMQ]: /reference/integration/activemq_security.html
[ScreenCast]: /introduction/screencasts.html#message_flow

## {{page.title}}

The diagram below shows basic message flow on a MCollective system.  There is also a [screencast][ScreenCast] that shows this process, recommend you watch that.

The key thing to take away from this diagram is the broadcast paradigm that is in use, one message only leaves the client and gets broadcast to all nodes.  We'll walk you through each point below.

![Message Flow](/images/message-flow-diagram.png)

<table>
<tr><th>Step</th><th>Description</th></tr>
<tr><td>A</td><td>A single messages gets sent from the workstation of the administrator to the middleware.  The message has a filter attached saying only machines with the fact <em>cluster=c</em> should perform an action.</td></tr>
<tr><td>B</td><td>The middleware network broadcasts the message to all nodes.  The middleware network can be a <a href="http://code.google.com/p/mcollective/wiki/ActiveMQClusters">cluster of multiple servers in multiple locations, networks and data centers</a>.</td></tr>
<tr><td>C</td><td>Every node gets the message and validates the filter</td></tr>
<tr><td>D</td><td>Only machines in <em>cluster=c</em> act on the message and sends a reply, depending on your middleware only the workstation will get the reply.</td></tr>
</table>

For further information see:
 
 * [Messages and their contents][MessageFormat]
 * [Clustering ActiveMQ brokers][ActiveMQClusters]
 * [Security, authentication and authorization][SecurityWithActiveMQ]
