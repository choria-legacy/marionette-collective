---
title: "MCollective » Deployment » Overview of Components and Configuration"
subtitle: "Overview of MCollective Components and Configuration"
layout: default
---

[ddl]: /mcollective/reference/plugins/ddl.html
[middleware]: /mcollective/deploy/middleware/
[standard_deploy]: /mcollective/deploy/standard.html
[agents]: /mcollective/simplerpc/agents.html
[subcollectives]: /mcollective/reference/basic/subcollectives.html
[actionpolicy]: https://docs.puppetlabs.com/mcollective/plugin_directory/authorization_action_policy.html
[ssl_plugin]: /mcollective/reference/plugins/security_ssl.html
[psk_plugin]: /mcollective/configure/server.html#psk-plugin-settings
[aes_plugin]: /mcollective/reference/plugins/security_aes.html

> This page describes MCollective's components and global configuration.
>
> * For an overview of deployment topics, see [the deployment index page](/mcollective/deploy/index.html).
> * To try MCollective now, see the [Vagrant demo toolkit](/mcollective/deploy/demo.html).
> * To deploy MCollective into your production environment, see the [standard deployment getting started guide](/mcollective/deploy/standard.html).

## The MCollective Components

The architecture of MCollective is based around three main components: **servers,** **clients,** and the **middleware.** Servers and clients also use various sub-components, which are mentioned in their respective sections.

![Diagram: A simplified drawing of MCollective's architecture. Connections between a few clients and many servers are mediated by the middleware.](./images/deployment.gif)

> **Terminology notes:** If you're familiar with Puppet, note that MCollective uses the term "server" a bit differently.
>
> * Instead of thinking "web server" or "puppet master server," think "SSH server." These are machines that mainly perform some other business purpose, but are also listening for MCollective requests.
> * From the user's perspective, servers accept inbound requests and react to them. From the middleware's perspective, servers are just another kind of client --- they proactively initiate a connection and subscribe to the types of messages they care about.
>
> The term "agent" is also different. In Puppet, the agent is a daemon that fetches and applies configurations --- the equivalent of the `mcollectived` server daemon. In MCollective, an agent is just a **bundle of actions** distributed as a plugin.
>
> Thing                                         | Puppet              | MCollective
> ----------------------------------------------|---------------------|-----------------------------
> Service that makes changes to the system      | puppet agent        | `mcollectived` server daemon
> Plugins that enable new actions/functionality | types and providers | agent plugins

### Servers

An MCollective server (often just called a "node") is a computer that **can be controlled via MCollective.** Servers run the MCollective daemon (`mcollectived`), and have any number of **agent plugins** installed.

![Diagram of the server. The connector plugin pulls requests, the security plugin validates them, and actions are executed by triggering agent plugins.](./images/server.gif)

The `mcollectived` service uses several kinds of plugin:

* A **connector plugin** to connect to the middleware, poll it for requests, and send replies
* A **security plugin** to validate and filter those requests, and encode replies
* Several **agent plugins** to execute actions from requests

The connector and security plugins are mandatory, and the clients must use the same plugins as the servers.

Servers can also use:

* A **registration plugin** to send a heartbeat and metadata to some kind of inventory database
* **Data plugins** to enable more complicated request filtering
* An **authorization plugin** to authorize requests on a per-action basis
* An **audit plugin** to log all requests, centrally or locally

### Clients

An MCollective client can send requests to any number of servers, use a security plugin to encode and sign the request, and use a connector plugin to publish it. These plugins must match the security and connector used by the servers. The client can also receive replies from servers and format the response for a user or some other system.

![Diagram of the client. The client application uses discovery plugins and agent Data Definition Language (DDL) files to construct requests, which are encoded in the security plugin and sent by the connector plugin.](./images/client.gif)

The most common client is the `mco` command-line client, which can be used interactively or in scripts. You can also write clients in Ruby, such as backends for GUI apps or glue in a reactive infrastructure.

Like servers, clients use several kinds of plugin:

* A **connector plugin** to connect to the middleware and send requests (and subscribe to replies)
* A **security plugin** to validate and filter those requests (and encode replies)
* Several **agent plugin Data Definition Language (DDL) files** for constructing valid requests

(As mentioned above, servers use **agent plugins** to execute actions. Since clients request these actions, they need to know which actions are available and what kinds of arguments they require. To do this, they use the [DDL file][ddl] from each agent they care about. These files describe actions and their inputs to enable early validation, and also tell the client how to format and summarize responses for the user.)

Clients can also use:

* Extra **discovery plugins** to get lists of which server nodes will respond to a request. The default discovery method uses empty MCollective messages to find nodes, and querying a central database can sometimes be faster.
* **Validator** and **aggregate** plugins to check and format data. These can be referenced by the agent DDL files.
* **Application plugins** to add custom subcommands to the `mco` command.

### Middleware

MCollective clients and servers don't communicate directly. They expect to be connected to some middleware system that knows how to route messages, and they publish messages to the middleware and subscribe to messages they need to receive.

This middleware system is external to MCollective, and everything that interacts directly with it is implemented in a **connector plugin** that needs some information about the middleware's topology and configuration. As far as everything but the connector is concerned, the middleware is an abstract cloud of magic:

![Diagram: The connector plugin interfaces with the middleware.](./images/middleware-magic.gif)

The connector and middleware handle three main kinds of messages:

* **Broadcast** requests (client-to-server)
* **Directed** requests (client-to-server)
* **Replies** (server-to-client)

![Diagram of kinds of traffic handled by the middleware. Clients send broadcast requests, which get routed to many servers, and directed requests, which get routed to a single server. Servers send replies, which are intended to go only to the client that initiated the original request.](./images/middleware.gif)

[See the middleware overview page][middleware] for info about the most common middleware options.

## Global Configuration and Deployment Decisions

Some MCollective configuration is global, and must match for all components. Deploying will be easier if you figure this configuration out first.

The [standard deployment guide][standard_deploy] makes several of these decisions for you, and goes into greater detail about the rest.

The main kinds of shared configuration are:

* [Middleware type and connector](#middleware-type-and-connector)
* [Security plugin](#security-plugin)
* [Agent plugins](#agent-plugins)
* [Subcollectives](#subcollectives)
* [Authorization policies](#authorization-policies)

### Middleware Type and Connector

All servers and clients must be using the same connector plugin, and it must match the middleware type you've chosen for the deployment.

* [Middleware Options][middleware]

Additionally, the way your middleware is configured will usually dictate some extra settings for the connector plugin. These generally include:

* Hostname(s) and port(s)
* Username and password
* Whether to use SSL
* SSL credentials (if using CA verification)

### Security Plugin

All servers and clients must be using the same security plugin. If it requires credentials for authentication, the servers will have to be configured to accept the clients' credentials (and vice-versa). Each security plugin has its own requirements re: credentials and their distribution.

* [The SSL security plugin (recommended)][ssl_plugin]
* [The PSK security plugin (only recommended for demo environments)][psk_plugin]
* [The AES security plugin (only recommended in special cases)][aes_plugin]

### Agent Plugins

MCollective servers must have [agent plugins][agents] in order to do anything. Not every server needs the same set of agents, but clients need the agent DDL files for any agent from which they'll trigger actions. You need to track what agents are in use.

### Subcollectives

If you divide your site into [subcollectives][] for security or traffic reduction, you must globally configure the list of collectives and determine which business rules are assigned to specific nodes.

Servers and clients need to know which collectives to which they should subscribe and send requests, and their expectations must be aligned. (If you send requests on a subcollective no one else knows about, you won't get anything interesting back.)

The middleware needs to know about them as well, since subcollectives are implemented in the connector plugin. See [the configuration help for your specific middleware][middleware] --- either limit certain users from accessing some collectives, or prevent certain traffic from crossing inter-datacenter connections. You must configure these restrictions in the middleware  rather than in MCollective.

### Authorization Policies

If you are using an authorization plugin like [ActionPolicy][], you'll need to configure its policies appropriately on every server. The rules for the policies must match the unique identities of the clients that will be sending requests, so the policies will be tied to your central knowledge of who and what the clients are.

With the ActionPolicy plugin, all policy files can safely be distributed to all servers, since each one defines which servers its rules apply to based on facts and other metadata.
