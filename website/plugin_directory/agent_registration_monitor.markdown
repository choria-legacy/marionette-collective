---
layout: default
title: "MCollective Plugin: Agent Registration Monitor"
---

MCollective supports sending [registration messages](https://docs.puppetlabs.com/mcollective/reference/plugins/registration.html) at set intervals. This is an agent to receive those messages and simply write the content to a file per sender.

It includes a Nagios check that monitors the directory with these files for any that has not checked in for some time.

You can use this agent as well as other types of registration agents, just not more than one per server.  So you can inventory your machines as well as monitor them on your Nagios server by just enabling registration on the mcollectived servers.

Installation
-----

 * The source is on [GitHub](https://github.com/puppetlabs/mcollective-plugins/tree/master/agent/registration-monitor/).


Configuration
-----

By default the plugin will create _/var/tmp/mcollective_ and create files in there per sender id.

You can configure the directory used using the setting _plugin.registration.directory_ in the server config.

You'd install this agent in just one of your nodes and then install the included Nagios check onto the same machine.

The nagios check should be invoked like:

<pre>
check_mcollective --directory /var/tmp/mcollective --interval 300
OK: 50 / 50 hosts checked in within 300 seconds| totalhosts=50 oldhosts=0 currenthosts=50
</pre>

It includes performance data for Nagios.
