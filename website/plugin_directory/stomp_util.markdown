---
layout: default
title: "MCollective Plugin: STOMP Utilities"
---

*NOTE:* This plugin will be removed when MCollective 2.2.x comes to an end due to the deprecation of the STOMP connector.

Helpers and utilities for the MCollective STOMP connector

Installation
============

The source is on [GitHub](https://github.com/puppetlabs/mcollective-plugins/tree/master/agent/stomputil/)

Usage
=====

Connection Information:
-----------------------
The idea is that if you have a network with failover STOMP servers you might need some visibility about what is connected where, this agent and bundled utility will help you with that.

<pre>
% mco rpc stomputil peer_info
Determining the amount of hosts matching filter for 2 seconds .... 1

 * [ ============================================================> ] 1 / 1


node1.your.net                          
       Host: stomp1.your.net
    Address: 192.168.1.10
   Protocol: AF_INET
       Port: 6163

Finished processing 1 / 1 hosts in 71.25 ms
</pre>

You can also view all the nodes using the peer map utility.

<pre>
$ mc-peermap country
stomp1.your.net -+ 22 nodes with 16.08ms average ping [de] 
                 |-node1.your.net
                 &lt;snip&gt;

stomp3.your.net -+ 19 nodes with 123.07ms average ping [uk] 
                 |-node10.your.net
                 &lt;snip&gt;


stomp2.your.net -+ 7 nodes with 363.30ms average ping [us] 
                 |-node20.your.net
                 &lt;snip&gt;

</pre>

Notice that I specified _country_ on the command line this causes the fact country for each STOMP server to be displayed in the output.

Reconnect:
----------

If you determined with the command above that you have nodes you'd rather reconnect to their primary STOMP server use this to disconnect and reconnect to the middleware, recreating all subscriptions and reloading all agents.

**NOTE:** You do not want to run this against all your machines at once, take them in batches.

<pre>
% mco rpc -I your.node.com stomputil reconnect
Determining the amount of hosts matching filter for 2 seconds .... 1

 * [ ============================================================> ] 1 / 1


nod1.your.net                          
   Restarted: 1


Finished processing 1 / 1 hosts in 591.50 ms
</pre>


