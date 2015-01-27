Introduction
------------

This plugin can retrive a value from a Linux sysctl variable to be used in agents and discovery.

Sample usage to select all machines where ipv4 forwarding is enabled:

<pre>
$ mco find -S "sysctl('net.ipv4.conf.all.forwarding').value=1"
</pre>


Installation
=======

 * The source is on [GitHub](https://github.com/puppetlabs/mcollective-plugins/tree/master/data/sysctl/).

