---
title: "MCollective » Deploy » Middleware"
subtitle: "MCollective: Middleware Options"
layout: default
---

[redis_security]: http://redis.io/topics/security
[deploy]: ../index.html
[standard]: ../standard.html
[activemq]: http://activemq.apache.org/
[activemq_config]: /mcollective/deploy/middleware/activemq.html
[activemq_example_links]: /mcollective/deploy/middleware/activemq.html#example-config-files
[server_config]: /mcollective/configure/server.html
[client_config]: /mcollective/configure/client.html
[activemq_connector]: /mcollective/reference/plugins/connector_activemq.html
[rabbitmq]: http://www.rabbitmq.com/
[rabbitmq_connector]: /mcollective/reference/plugins/connector_rabbitmq.html
[redis]: http://redis.io/
[security_overview]: /mcollective/security.html
[redis_connector]: https://github.com/ripienaar/mc-plugins/tree/master/connector/redis
[redis_comments]: https://github.com/ripienaar/mc-plugins/blob/master/connector/redis/redis.rb
[stomp_connector]: /mcollective/reference/plugins/connector_stomp.html
[overview]: /mcollective/overview_components.html

Summary
-----

MCollective needs a publish/subscribe middleware system of some kind for all communications. When deploying MCollective, you need to:

* Pick a **middleware type**
* Get a **connector plugin** that supports it (note that ActiveMQ and RabbitMQ plugins are already included with MCollective's core install)
* **Deploy and configure** the middleware server(s)
* **Configure the connector plugin** on all MCollective servers and clients

> **Note:** Configuring the middleware and connector is only one step of a many-step deployment process. See [the deployment index][deploy] for a map of our deployment documentation, [the overview of components and configuration][overview] for a summary of the components and roles in an MCollective deployment, and [the standard deployment getting started guide][standard] for a walkthrough of the deployment process.

MCollective supports the following middleware systems:


ActiveMQ
-----

[Apache ActiveMQ][activemq] is an open-source message broker that runs on the JVM; typically it's installed with a wrapper script and init script that allow it to be managed as a normal OS service. MCollective talks to ActiveMQ using the Stomp protocol.

**This is the main middleware recommended for use with MCollective:** it performs extremely well, it's the most well-tested option, its security features are powerful and flexible enough to suit nearly all needs, and it can scale by clustering once a deployment gets too big (we recommend ~800 nodes per ActiveMQ server as a maximum). Its main drawback is that it can be frustrating to configure; to help mitigate that, we provide a detailed ActiveMQ config reference in our own docs (see below).

The ActiveMQ connector ships with MCollective's core and is available by default.

* See [the MCollective ActiveMQ Config Reference][activemq_config] for information about configuring ActiveMQ to suit MCollective's needs. The best way to use this page is to grab an example config file (see the [links near the top of the reference][activemq_example_links]) and change settings as needed.
* See the [Server Config Reference][server_config] and [Client Config Reference][client_config] for general information about configuring connector plugins.
* See the [ActiveMQ Connector Plugin Reference][activemq_connector] for detailed info on the ActiveMQ connector's settings.

RabbitMQ
-----

[RabbitMQ][] is an open-source message broker written in Erlang; MCollective talks to RabbitMQ using the Stomp protocol. Although it works well with MCollective, it isn't as thoroughly tested with it as ActiveMQ is, so if your site has no preference, you should default to ActiveMQ.

The RabbitMQ connector ships with MCollective's core and is available by default.

* We do not provide information on deploying and configuring RabbitMQ itself.
* See the [Server Config Reference][server_config] and [Client Config Reference][client_config] for general information about configuring connector plugins.
* See the [RabbitMQ Connector Plugin Reference][rabbitmq_connector] for detailed info on the RabbitMQ connector's settings.


Generic Stomp Connector (Deprecated)
-----

MCollective 2.2 and earlier include a generic Stomp connector, which was the predecessor of the ActiveMQ and RabbitMQ connectors. Its performance and capabilities are fairly outdated at this point, and it was deprecated during the 2.2 series and removed in the 2.3 series. Use the ActiveMQ or RabbitMQ connector instead.

For older versions where the Stomp connector is still necessary, see the archived [Stomp Connector Plugin Reference][stomp_connector] for config details.

Custom Connector Plugins
-----

Creating custom connector plugins is not currently documented, but it's very possible. We suggest reading the code of both the ActiveMQ connector and the Redis connector, to get decent parallax on how to accomplish similar tasks with very different systems.

