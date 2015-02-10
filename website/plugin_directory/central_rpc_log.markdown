---
layout: default
title: "MCollective Plugin: Central RPC Audit Log"
---


This is a [SimpleRPC Audit Plugin](http://docs.puppetlabs.com/mcollective/simplerpc/auditing.html) and Agent that sends all SimpleRPC audit events to a central point for logging.

You'd run the audit plugin on every node and designate one node as the receiver of audit logs.  The receiver will have a detailed log of every SimpleRPC request processed on your entire server estate.

There are 2 receiving agents, one that writes a log file:

<pre>
01/22/10 12:57:34 dev2.foo.net> b10c1a33ad5e8cfaf5f564afa9957c32: 01/22/10 12:57:34 caller=uid=500@devel.your.com agent=iptables action=block
01/22/10 12:57:34 dev2.foo.net> b10c1a33ad5e8cfaf5f564afa9957c32: {:ipaddr=>"62.x.x.242"}
01/22/10 12:57:34 dev1.foo.net> b10c1a33ad5e8cfaf5f564afa9957c32: 01/22/10 12:57:34 caller=uid=500@devel.your.com agent=iptables action=block
01/22/10 12:57:34 dev2.foo.net> b10c1a33ad5e8cfaf5f564afa9957c32: {:ipaddr=>"62.x.x.242"}
</pre>

The example log file is from a remote node _devel.your.com_ it is for a message with the ID _b10c1a33ad5e8cfaf5f564afa9957c32_, the caller ran as unix process id _500_.

It sent a request to the _iptables_ agent with the action _block_ and the parameter _ipaddr = 62.x.x.242_.

The other plugin will write to MongoDB:

<pre>
$ mongo
MongoDB shell version: 1.4.4
> use mcollective
switched to db mcollective
> db.rpclog.find()
{ "_id" : ObjectId("4c5975e2dc3ecb0c3b000001"), "agent" : "nrpe", "senderid" : "monitor1.xxx.net", "requestid" : "6c311d786b2d187b231d41f14cbb03ce", "action" : "runcommand", "data" : { "command" : "check_bacula-fd", "process_results" : true }, "caller" : "cert=nagios@monitor1.xxx.net" }
</pre>

There are some limitations to the design of this plugin, I suspect it will be affective to only a few 100 machines.  This is due to RPC requests being used to create the audit entries.  If the central host isn't fast there might be some overflow and discarding happening.

I'd be interested in working with someone to improve this, we'd essentially write audit log entries to a Queue and have a daemon that consumes the queue, this will ensure that all logs get saved to the DB.

Installation
-----

### Every Node

 * The source is on [GitHub](https://github.com/puppetlabs/mcollective-plugins/tree/master/audit/centralrpclog/audit/).


Add to the configuration:

<pre>
rpcaudit = 1
rpcauditprovider = centralrpclog
</pre>

Since version _1.1.3_ of MCollective we support sub collective, you can specify which collective to use:

<pre>
plugin.centralrpclog.collective = audit
</pre>

And restart

### Central Audit Node

#### File logging agent

 * The source is on [GitHub](https://github.com/puppetlabs/mcollective-plugins/tree/master/audit/centralrpclog/agent/).


Add to the configuration:

<pre>
plugin.centralrpclog.logfile = /var/log/mcollective-rpcaudit.log
</pre>

 * Set up log rotation for _/var/log/mcollective-rpcaudit.log_ using your Operating Systems log rotation system.

#### MongoDB agent

 * The source is on [GitHub](https://github.com/puppetlabs/mcollective-plugins/tree/master/audit/centralrpclog/agent/).


Add to your configuration, these are the defaults so you can just keep it like this if its ok:

<pre>
plugin.centralrpclog.mongohost = localhost
plugin.centralrpclog.mongodb = mcollective
plugin.centralrpclog.collection = rpclog
</pre>
