---
layout: default
title: "MCollective Plugin: Packages Agent"
---

Packages agent for MCollective - a agent to install/upgrade/downgrade
multiple packages at a time.

When using MCollective to roll-out changes in a Continuous Delivery
environment, the included has some shortcomings, the main one being
that it does not support multiple packages in one run, which adds
overhead.

Packages agent tackles the following requirements
1. The client does not know wether a package is already installed or not.
1. Allow install, update and downgrade.
1. Handle multiple packages in one operation.
1. Respond with a list of packages and their exact version/revision installed.
1. Re-try operations when they fail.
1. Include "yum clean expire-cache"

Limitations
-----

Mainly tested on Scientific Linux 6.1.

Installation
-----

The source is on [GitHub](https://github.com/jbraeuer/mcollective-plugins/tree/packages/agent/packages/)

Usage
-----

Install multiple packages at a time:

<pre>
% mco packages uptodate htop iotop
Do you really want to operate on packages unfiltered? (y/n): y

 * [ ============================================================> ] 5 / 5

ip-10-56-51-48                           = OK ::: [{"name":"htop","tries":1,"version":"0.8.3","status":0,"release":"2.el6"},{"name":"iotop","tries":1,"version":"0.3.2","status":0,"release":"3.el6"}] :::
ip-10-56-5-253                           = OK ::: [{"name":"htop","tries":1,"version":"0.8.3","status":0,"release":"2.el6"},{"name":"iotop","tries":1,"version":"0.3.2","status":0,"release":"3.el6"}] :::
ip-10-250-141-198                        = OK ::: [{"name":"htop","tries":1,"version":"0.8.3","status":0,"release":"2.el6"},{"name":"iotop","tries":1,"version":"0.3.2","status":0,"release":"3.el6"}] :::
ip-10-56-46-219                          = OK ::: [{"name":"htop","tries":1,"version":"0.8.3","status":0,"release":"2.el6"},{"name":"iotop","tries":1,"version":"0.3.2","status":0,"release":"3.el6"}] :::
ip-10-250-126-24                         = OK ::: [{"name":"htop","tries":1,"version":"0.8.3","status":0,"release":"2.el6"},{"name":"iotop","tries":1,"version":"0.3.2","status":0,"release":"3.el6"}] :::

</pre>

Request installation of specific version (and disable y/n for automated deployments):

<pre>
# mco packages --batch uptodate htop/0.8.3/2.el6 iotop/0.3.2/3.el6

 * [ ============================================================> ] 5 / 5

ip-10-56-46-219                          = OK ::: [{"name":"htop","tries":1,"version":"0.8.3","status":0,"release":"2.el6"},{"name":"iotop","tries":1,"version":"0.3.2","status":0,"release":"3.el6"}] :::
ip-10-56-5-253                           = OK ::: [{"name":"htop","tries":1,"version":"0.8.3","status":0,"release":"2.el6"},{"name":"iotop","tries":1,"version":"0.3.2","status":0,"release":"3.el6"}] :::
ip-10-250-126-24                         = OK ::: [{"name":"htop","tries":1,"version":"0.8.3","status":0,"release":"2.el6"},{"name":"iotop","tries":1,"version":"0.3.2","status":0,"release":"3.el6"}] :::
ip-10-56-51-48                           = OK ::: [{"name":"htop","tries":1,"version":"0.8.3","status":0,"release":"2.el6"},{"name":"iotop","tries":1,"version":"0.3.2","status":0,"release":"3.el6"}] :::
ip-10-250-141-198                        = OK ::: [{"name":"htop","tries":1,"version":"0.8.3","status":0,"release":"2.el6"},{"name":"iotop","tries":1,"version":"0.3.2","status":0,"release":"3.el6"}] :::
</pre>
