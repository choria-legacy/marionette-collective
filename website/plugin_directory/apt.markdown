---
layout: default
title: "MCollective Plugin: AgentApt"
---

Introduction
------------

An agent to handle apt/dpkg tasks such as finding the total number of upgrades available, listing the total number of packages installed, or executing an 'apt-get clean' or 'apt-get update'.

Installation
------------

 * The source for the plugin is [GitHub](https://github.com/mstanislav/mCollective-Agents/tree/master/apt)

Usage
-----
### Update

<pre>
# mc-apt update
Do you really want to operate on services unfiltered? (y/n): y
server01.example.com                                : OK
server02.example.com                                : OK
server03.example.com                                : OK
server04.example.com                                : OK
server05.example.com                                : OK
</pre>

### Clean

<pre>
# mc-apt clean
Do you really want to operate on services unfiltered? (y/n): y
server01.example.com                                : OK
server02.example.com                                : OK
server03.example.com                                : OK
server04.example.com                                : OK
server05.example.com                                : OK
</pre>

### Installed

<pre>
# mc-apt installed
Do you really want to operate on services unfiltered? (y/n): y
server01.example.com                                : 755
server02.example.com                                : 832
server03.example.com                                : 744
server04.example.com                                : 755
server05.example.com                                : 832
</pre>

</pre>

### Upgrades

<pre>
# mc-apt upgrades
Do you really want to operate on services unfiltered? (y/n): y
server01.example.com                                : 57
server02.example.com                                : 19
server03.example.com                                : 0
server04.example.com                                : 0
server05.example.com                                : 0
</pre>
