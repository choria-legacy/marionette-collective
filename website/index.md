---
layout: default
title: Marionette Collective
toc: false
---

[pubsub]: https://en.wikipedia.org/wiki/Publish/subscribe
[Screencasts]: /mcollective/screencasts.html
[Amazon EC2 based demo]: /mcollective/ec2demo.html
[broadcast paradigm]: /mcollective/reference/basic/messageflow.html
[UsingWithPuppet]: /mcollective/reference/integration/puppet.html
[Facter]: /mcollective/plugin_directory/facter_via_yaml.html
[WritingFactsPlugins]: /mcollective/reference/plugins/facts.html
[NodeReports]: /mcollective/reference/ui/nodereports.html
[PluginsSite]: /mcollective/plugin_directory/
[SimpleRPCIntroduction]: /mcollective/simplerpc/
[SecurityOverview]: /mcollective/security.html
[SecurityWithActiveMQ]: /mcollective/reference/integration/activemq_security.html
[SSLSecurityPlugin]: /mcollective/reference/plugins/security_ssl.html
[AESSecurityPlugin]: /mcollective/reference/plugins/security_aes.html
[SimpleRPCAuthorization]: /mcollective/simplerpc/authorization.html
[SimpleRPCAuditing]: /mcollective/simplerpc/auditing.html
[ActiveMQClusters]: /mcollective/reference/integration/activemq_clusters.html
[JSON Schema]: http://json-schema.org/
[Registration]: /mcollective/reference/plugins/registration.html
[GettingStarted]: /mcollective/reference/basic/gettingstarted.html
[Configuration]: /mcollective/reference/basic/configuration.html
[Terminology]: /mcollective/terminology.html
[devco]: https://www.devco.net/archives/tag/mcollective
[mcollective-users]: https://groups.google.com/group/mcollective-users
[WritingAgents]: /mcollective/reference/basic/basic_agent_and_client.html
[ActiveMQ]: /mcollective/reference/integration/activemq_security.html
[MessageFormat]: /mcollective/reference/basic/messageformat.html
[ChangeLog]: /mcollective/changelog.html
[server_config]: /mcollective/configure/server.html
[Vagrant]: /mcollective/deploy/demo.html

The Marionette Collective, also known as **MCollective,** is a framework for building server orchestration or parallel job-execution systems. Most users programmatically execute administrative tasks on clusters of servers.

> **Deprecation Note:** As of Puppet agent 5.5.4, MCollective is deprecated and will be removed in a future version of Puppet agent. If you use MCollective with Puppet Enterprise, consider [moving from MCollective to Puppet orchestrator](/docs/pe/2018.1/migrating_from_mcollective_to_orchestrator.html). If you use MCollective with open source Puppet, consider migrating MCollective agents and filters using tools like [Bolt](/docs/bolt/) and PuppetDB's [Puppet Query Language](/docs/puppetdb/latest/api/query/tutorial-pql.html).

MCollective has some unique strengths for working with large numbers of servers:

* Instead of relying on a static list of hosts to command, it uses metadata-based discovery and filtering. It can use a rich data source like [PuppetDB](/puppetdb/), or can perform real-time discovery across the network.
* Instead of directly connecting to each host (which can be resource-intensive and slow), it uses [publish/subscribe middleware][pubsub] to communicate in parallel with many hosts at once.

To get an immediate feel for what this means, check out the videos on the [Screencasts][] page. Then, keep reading below for further information and links.

We've also created a [Vagrant-based demo][Vagrant], where you can easily experiment with MCollective.

## What is MCollective, and What Does It Allow You to Do?

* Interact with clusters of servers, whether in small groups or very large deployments.
* Use a [broadcast paradigm][] to distribute requests. All servers receive all requests at the same time, requests have filters attached, and only servers matching the filter will act on requests. There is no central asset database to go out of sync, because the network is the only true source.
* Break free from identifying devices through complex host-naming conventions, and instead use a rich set of metadata provided by each machine --- from [Puppet][UsingWithPuppet], [Facter][], or other sources --- to address them.
* Use simple command-line tools to call remote agents.
* Write [custom reports][NodeReports] about your infrastructure.
* Use agent plugins to manage packages, services, and other common components [created by the community][PluginsSite].
* Write [simple RPC style agents, clients][SimpleRPCIntroduction], and web UIs in Ruby.
* Extremely pluggable and adaptable to local needs.
* Leverage rich [authentication and authorization models][SecurityWithActiveMQ] in middleware systems as a first line of control.
* Include fine-grained authentication using [SSL][SSLSecurityPlugin] or [RSA][AESSecurityPlugin], [authorization][SimpleRPCAuthorization], and [request auditing][SimpleRPCAuditing]. For more information, see the [Security Overview][SecurityOverview].
* Re-use middleware features for [clustering, routing, and network isolation][ActiveMQClusters] to realize secure and scalable configurations.

## Pluggable Core

MCollective provides a stable core framework that you can build into a system to meet your own needs. MCollective is pluggable in the following areas:

* Replace our STOMP-compliant middleware with your own, such as something AMQP-based.
* Replace our authorization system with one that suits your local needs.
* Replace our Ruby Marshal and YAML-based serialization with your own, such as cross-language [JSON Schema][].
* Add data sources. It's easy to use [Puppet's][UsingWithPuppet] data, and you can configure or build plugins for other data sources.
* Create a central inventory of services [leveraging MCollective as transport][Registration] that can regularly run and distribute inventory data.

MCollective is licensed under the [Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0).

## Next Steps and Further Reading

### Introductory and Tutorial Pages

* See it in action in our [Screencasts][].
* Read the [Overview of Components](./overview_components.html) to understand MCollective's basic structure.
* Use the [Vagrant Demo Environment][Vagrant] to try MCollective.
* See the [Standard Deployment Getting Started Guide](/mcollective/deploy/standard.html) to install and deploy MCollective in your own infrastructure.
* Read the [Terminology][] page if you see any words where the meaning in the context of MCollective is not clear.
* Read the [change log][ChangeLog] and [release notes](./releasenotes.html) to see how MCollective has developed.
* Learn how to write basic [node reports][NodeReports] for your servers.
* Learn how to write simple agents and clients using our [Simple RPC Framework][SimpleRPCIntroduction].
* MCollective's author has [several blog posts][devco] about MCollective.
* Subscribe and post questions to the [mailing list][mcollective-users].

### Internal References and Developer Docs

* Finding it hard to do something complex with Simple RPC? See [Writing Agents][WritingAgents] for what lies underneath.
* Role based security, authentication and authorization using [ActiveMQ][].
* Structure of [Request and Reply][MessageFormat] messages.
