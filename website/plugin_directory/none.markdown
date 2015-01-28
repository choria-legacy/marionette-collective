---
layout: default
title: "MCollective Plugin: No Security"
---

This plugin is very easy to use as it provides no security there are no certificates or pre shared keys to setup.  The intention is to use it in development and testing but **NOT IN PRODUCTION**

Installation
============

 * The source is on [GitHub](https://github.com/puppetlabs/mcollective-plugins/tree/master/security/none/).


Configuration
=============

Set the following in both server and client config files:

<pre>
securityprovider = none
</pre>

