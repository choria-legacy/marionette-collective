---
layout: default
title: ActiveMQ Security
toc: false
---

[Security]: http://activemq.apache.org/security.html
[Wildcard]: http://activemq.apache.org/wildcards.html
[activemq_config]: /mcollective/deploy/middleware/activemq.html
[mcollective_username]: /mcollective/reference/plugins/connector_activemq.html#configuring-mcollective
[mcollective_tls]: ./activemq_ssl.html#step-2-configure-mcollective-servers

As part of rolling out MCollective you need to think about security. The various examples in the quick start guide and on this blog has allowed all agents to talk to all nodes all agents. The problem with this approach is that should you have untrusted users on a node they can install the client applications and read the username/password from the server config file and thus control your entire architecture.

The default format for message topics is compatible with [ActiveMQ wildcard patterns][Wildcard] and so we can now do fine grained controls over who can speak to what.

General information about [ActiveMQ Security can be found on their wiki][Security].

## Configuring Security in activemq.xml

[The ActiveMQ config reference][activemq_config] contains all relevant info for configuring security is activemq.xml. The most relevant sections are:

* [Topic and Queue Names](/mcollective/deploy/middleware/activemq.html#topic-and-queue-names) --- Info about the destinations that MCollective uses.
* [Transport Connectors](/mcollective/deploy/middleware/activemq.html#transport-connectors) --- URL structure for insecure and TLS transports.
* [TLS Credentials](/mcollective/deploy/middleware/activemq.html#tls-credentials) --- For use with TLS transports.
* [Authentication](/mcollective/deploy/middleware/activemq.html#authentication-users-and-groups) --- Establishing user accounts and groups.
* [Authorization](/mcollective/deploy/middleware/activemq.html#authorization-group-permissions) --- Limiting access to destinations based on group membership.
* [Destination Filtering](/mcollective/deploy/middleware/activemq.html#destination-filtering) --- Preventing certain messages from crossing between datacenters.



## Configuring Security in MCollective

MCollective clients and servers need security credentials that line up with ActiveMQ's expectations. Specifically:

* [An ActiveMQ username and password][mcollective_username]
* [TLS credentials, if necessary][mcollective_tls]

