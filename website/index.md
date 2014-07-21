---
layout: default
title: Marionette Collective
toc: false
---

[pubsub]: http://en.wikipedia.org/wiki/Publish/subscribe
[Screencasts]: /mcollective/screencasts.html
[Amazon EC2 based demo]: /mcollective/ec2demo.html
[broadcast paradigm]: /mcollective/reference/basic/messageflow.html
[UsingWithPuppet]: /mcollective/reference/integration/puppet.html
[Facter]: http://projects.puppetlabs.com/projects/mcollective-plugins/wiki/FactsFacterYAML
[WritingFactsPlugins]: /mcollective/reference/plugins/facts.html
[NodeReports]: /mcollective/reference/ui/nodereports.html
[PluginsSite]: http://projects.puppetlabs.com/projects/mcollective-plugins/wiki
[SimpleRPCIntroduction]: /mcollective/simplerpc/
[SecurityOverview]: /mcollective/security.html
[SecurityWithActiveMQ]: /mcollective/reference/integration/activemq_security.html
[SSLSecurityPlugin]: /mcollective/reference/plugins/security_ssl.html
[AESSecurityPlugin]: /mcollective/reference/plugins/security_aes.html
[SimpleRPCAuthorization]: /mcollective/simplerpc/authorization.html
[SimpleRPCAuditing]: /mcollective/simplerpc/auditing.html
[ActiveMQClusters]: /mcollective/reference/integration/activemq_clusters.html
[JSONSchema]: http://json-schema.org/
[Registration]: /mcollective/reference/plugins/registration.html
[GettingStarted]: /mcollective/reference/basic/gettingstarted.html
[Configuration]: /mcollective/reference/basic/configuration.html
[Terminology]: /mcollective/terminology.html
[devco]: http://www.devco.net/archives/tag/mcollective
[mcollective-users]: http://groups.google.com/group/mcollective-users
[WritingAgents]: /mcollective/reference/basic/basic_agent_and_client.html
[ActiveMQ]: /mcollective/reference/integration/activemq_security.html
[MessageFormat]: /mcollective/reference/basic/messageformat.html
[ChangeLog]: /mcollective/changelog.html
[server_config]: /mcollective/configure/server.html

The Marionette Collective, also known as **MCollective,** is a framework for building server
orchestration or parallel job execution systems. Most people use it to programmatically execute administrative tasks on clusters of servers.

MCollective has some unique strengths for working with large numbers of servers:

* Instead of relying on a static list of hosts to command, it uses metadata-based discovery and filtering. It can use a rich data source like [PuppetDB](/puppetdb/), or can do real-time discovery across the network.
* Instead of directly connecting to each host (which can be resource-intensive and slow), it uses [publish/subscribe middleware][pubsub] to communicate in parallel with many hosts at once.

To get an immediate feel for what this means, check out the videos on the [Screencasts][] page. Then, keep reading below for further info and links.

We've also created a [Vagrant-based demo](/mcollective/deploy/demo.html), where you can easily experiment with MCollective.

## What is MCollective and what does it allow you to do

* Interact with small to very large clusters of servers
* Use a [broadcast paradigm][] for request distribution.  All servers get all requests at the same time, requests have
  filters attached and only servers matching the filter will act on requests.  There is no central asset database to
  go out of sync, the network is the only source of truth.
* Break free from ever more complex naming conventions for hostnames as a means of identity.  Use a very
  rich set of meta data provided by each machine to address them.  Meta data comes from
  [Puppet][UsingWithPuppet], [Facter][], or other sources.
* Comes with simple to use command line tools to call remote agents.
* Ability to write [custom reports][NodeReports] about your infrastructure.
* A number of agents to manage packages, services and other common components are [available from
  the community][PluginsSite].
* Allows you to write [simple RPC style agents, clients][SimpleRPCIntroduction] and Web UIs in an easy to understand language - Ruby
* Extremely pluggable and adaptable to local needs
* Middleware systems already have rich [authentication and authorization models][SecurityWithActiveMQ], leverage these as a first
  line of control.  Include fine grained Authentication using [SSL][SSLSecurityPlugin] or [RSA][AESSecurityPlugin], [Authorization][SimpleRPCAuthorization] and
  [Auditing][SimpleRPCAuditing] of requests.  You can see more details in the [Security Overview][SecurityOverview].
* Re-use the ability of middleware to do [clustering, routing and network isolation][ActiveMQClusters]
  to realize secure and scalable setups.

## Pluggable Core

We aim to provide a stable core framework that allows you to build it out into a system that meets
your own needs, we are pluggable in the following areas:

* Replace our choice of middleware - STOMP compliant middleware - with your own like AMQP based.
* Replace our authorization system with one that suits your local needs
* Replace our serialization - Ruby Marshal and YAML based - with your own like [JSONSchema][] that is cross language.
* Add sources of data - using [Puppet][UsingWithPuppet]'s data is easy, and you can configure or build plugins for other data sources.
* Create a central inventory of services [leveraging MCollective as transport][Registration]
  that can run and distribute inventory data on a regular basis.

MCollective is licensed under the Apache 2 license.

## Next Steps and Further Reading

### Introductory and Tutorial Pages

* See it in action in our [Screencasts][]
* Read the [Overview of Components](./overview_components.html) to understand MCollective's basic structure
* Use the [Vagrant Demo Environment](/mcollective/deploy/demo.html) to try MCollective today
* See the [Standard Deployment Getting Started Guide](/mcollective/deploy/standard.html) to install and deploy MCollective in your own infrastructure
* Read the [Terminology][] page if you see any words where the meaning in the context of MCollective is not clear
* Read the [ChangeLog][] page to see how MCollective has developed
* Learn how to write basic reports for your servers - [NodeReports][]
* Learn how to write simple Agents and Clients using our [Simple RPC Framework][SimpleRPCIntroduction]
* The author maintains some agents and clients on another project [here][PluginsSite].
* The author has written [several blog posts][devco] about mcollective.
* Subscribe and post questions to the [mailing list][mcollective-users].

### Internal References and Developer Docs

* Finding it hard to do something complex with Simple RPC? See [WritingAgents][] for what lies underneath
* Role based security, authentication and authorization using [ActiveMQ][]
* Structure of [Request and Reply][MessageFormat] messages

