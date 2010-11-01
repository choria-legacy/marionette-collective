---
layout: default
title: Security Overview
disqus: true
---
[broadcast paradigm]: /mcollective/reference/basic/messageflow.html
[SimpleRPC]: /mcollective/simplerpc/
[Authorization]: /mcollective/simplerpc/authorization.html
[Auditing]: /mcollective/simplerpc/auditing.html
[SSL security plugin]: /mcollective/reference/plugins/security_ssl.html
[ActiveMQ Security]: /mcollective/reference/integration/activemq_security.html
[ActiveMQ TLS]: http://activemq.apache.org/how-do-i-use-ssl.html
[ActiveMQ SSL]: /mcollective/reference/integration/activemq_ssl.html
[ActiveMQ STOMP]: http://activemq.apache.org/stomp.html
[MCollective STOMP Connector]: /mcollective/reference/plugins/connector_stomp.html
[ActionPolicy]: http://code.google.com/p/mcollective-plugins/wiki/ActionPolicy
[CentralAudit]: http://code.google.com/p/mcollective-plugins/wiki/AuditCentralRPCLog


# {{page.title}}

Due to the [broadcast paradigm] of mcollective security is a complex topic to
discuss.

This discussion will focus on strong SSL base security, this is not the default
or only option but is currently the most secure.  The [SSL security plugin]
provides strong caller identification, this is used by the [SimpleRPC]
framework for [Authorization] and [Auditing].

As every organisation has its own needs almost all aspects of the security
system is pluggable.  This is an overview of the current state of SSL based
Authentication, Authorization and Auditing.

<center><img src="/mcollective/images/mcollective-aaa.png"></center>

The image above is a reference to use in the following pages, it shows a
MCollective Setup and indicates the areas of discussion.

The focus here is on ActiveMQ, some of the details and capabilities will
differ between middleware systems.

 * TOC Placeholder
 {:toc}

## Client Connections and Credentials

Every STOMP connection has a username and password, this is used to gain basic
access to the ActiveMQ system.  We have a [ActiveMQ Security] sample setup
documented.

ActiveMQ can use LDAP and other security providers, details of this is out of
scope here, you should use their documentation or the recently released book
for details of that.

When using the [SSL security plugin] each user also gets a private and public
certificate, like with SSH you need to ensure that the private keys remain
private and not be shared between users.  The public part needs to be
distributed to all nodes.

The private key is used to cryptographically sign each request being made by a
client, later the public key will be used to validate the signature for
authenticity.

The client embeds a _caller_ structure in each request, if SSL signature
validation pass the rest of the MCollective agents, auditing etc can securely
know who initiated a request.

This caller is used later during Authorization and Auditing.

## Connection to Middleware

By default the connections between Middleware and Nodes are not encrypted, just
signed using the SSL keys above.  [ActiveMQ supports TLS][ActiveMQ TLS] and the
[stomp connector][ActiveMQ STOMP] supports this.

The [MCollective STOMP Connector] also supports TLS, to configure MCollective
to speak TLS to your nodes please follow our notes about [ActiveMQ SSL].

Enabling TLS throughout will secure your connections from any kind of sniffing
and Man in The Middle attacks.  Unfortunately the Rubygem we use do not provide
options for enforcing a specific CA etc.  The authors are willing to extend it
to support these based on requests, file support tickets if you need our help
in working with them as we already have a good working relationship.

## Middleware Authorization and Authentication

As mentioned above ActiveMQ has it's own users and every node and client
authenticates using these.

In addition to this you can on the middleware layer restrict access to topics,
you can for example run a development and production collective on the same
ActiveMQ infrastructure and allow your developers access to just the development
collective using these controls.  They are not very fine grained but should be a
import step to configure for any real setup.

We have a sample [ActiveMQ Security] setup documented that has this kind of
control.

## Node connections and credentials

As with the client the node needs a username and password to connect to the
middleware and can also use TLS.

It's not a problem if all the nodes share a username and password for the
connection since generally nodes do not make new requests.  You can enable
registration features that will see your nodes make connections, you should
restrict this as outlined in the previous section.

All the nodes share a same SSL private and public key, all replies are signed
using this key.  It would not be impossible to add a per node certificate setup
but I do not think this will add a significant level of security over what we
have today.

## SimpleRPC Authorization

The RPC framework has a pluggable [Authorization] system, you can create very
fine grain control over requests, for example using the [ActionPolicy] setup you
can create a policy like this:

{% highlight text %}
policy default deny
allow   cert=rip      *                       *                *
allow   cert=john     *                       customer=acme    acme::devserver
allow   cert=john     enable disable status   customer=acme    *
{% endhighlight %}

This applied to the service agent will allow different level of access to
actions to different people.  The caller id is based directly on the SSL Private
Key in use and subject to validation on every node.

As with other aspects of mcollective authorization is tied closely with meta
data like facts and classes so you can use these to structure your authorization
as can be seen above.

You can provide your own authorization layers to fit your ogranizational needs,
they can be specific to an agent or apply to the entire collective.

## SimpleRPC Auditing

The RPC layer can keep detailed [Auditing] records of every request received,
the audit log shows the - SSL signature verified - caller, what agent, action
and any arguments that was sent for every request.

The audit layer is a plugin based system, we provide one that logs to a file on
every node and there are [community plugins][CentralAudit] that keeps a centralized
log both in log files and in MongoDB NoSQL database.

Which to use depends on your usecase, obviously a centralized auditing system
for thousands of nodes is very complex and will require a special plugin to be
developed the community centralized audit log is ok for roughly 100 nodes or
so.
