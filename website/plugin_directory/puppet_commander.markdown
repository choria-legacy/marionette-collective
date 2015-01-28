---
layout: normal
title: "MCollective Plugin: Puppet Commander"
---

The Puppet Commander solves the problem where at times even when using splay you will find a large amount of checkins hitting your master and overwhelming it.

The basic theory is that using the [Puppet Agent plugin](puppet_agent.html) we can figure out how many machines are currently running and we can schedule runs.  We can thus ensure that at any given time we only schedule a certain amount of current runs.  This will help you with capacity planning of your masters.

As a side effect it also means if you are busy managing servers and running _puppetd --test_ runs or some other scheduled runs the commander will back down and not schedule runs, leaving the resources of the master free for your interactive use.

Installation
------------

 * You need to have [Puppet Agent](puppet_agent.html) installed and working.
 * You should not be running the Puppet Daemons, shut those services down.
 * Get the code from [GitHub](https://github.com/puppetlabs/mcollective-plugins/tree/master/agent/puppetd/commander/).
 * Place the _puppetcommanderd_ script in _/usr/sbin_.
 * Place the _puppetcommander.init_ in your rc directory, often that is _/etc/init.d/puppetcommander_ and enable it.
 * Create _/etc/sysconfig/puppetcommanderd_ and set any settings like those for security plugins or MCOLLECTIVE_EXTRA_OPTS.
 * Create _/etc/puppetcommander.cfg_ from the provided template.

Configuration
-------------

A sample config file can be seen below:

<pre>
---
:filter: "country=/de|uk|za/"
:interval: 30
:concurrency: 2
:randomize: true
:logfile: /var/log/puppetcommander.log
:daemonize: true
</pre>

It runs my nodes in _de_, _uk_ and _za_ in 30 minutes, never more than 2 at a time.  It will shuffle the nodes it discovered and log to the given log file.

The filter option above is quite limiting, from MCollective 1.1.0 and newer to supply filters do the following in _/etc/sysconfig/puppetcommanderd_, this lets you supply a much richer set of filters than before.

<pre>
export MCOLLECTIVE_EXTRA_OPTS="-W country=/de|uk|za/"
</pre>

And set the filter in the YAML above to:

<pre>
:filter: ""
</pre>
