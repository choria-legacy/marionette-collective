---
layout: default
title: "MCollective Plugin: Registration Metadata"
---

Sends all available metadata via the registration mechanism, at present this is:

 * All facts
 * All agents
 * List of all classes

Installation
-----

 * The source is on [GitHub](https://github.com/puppetlabs/mcollective-plugins/tree/master/registration/).


Configuration
-----

For full details about the registration system see [Registration](http://docs.puppetlabs.com/mcollective/reference/plugins/registration.html)

The simplest configuration for this plugin is:

<pre>
registerinterval = 300
registration = Meta
</pre>

You should also set up a receiver, such as [agent registration monitor](agent_registration_monitor.html) or [agent registration for MongoDB](agent_registration_mongodb.html).
