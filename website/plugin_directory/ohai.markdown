---
layout: normal
title: "MCollective Plugin: Ohai"
---


# Overview

The Ohai plugin enables mcollective to use [OpsCode Ohai](http://wiki.opscode.com/display/chef/Ohai) as a source for facts about your system.

This plugin uses a 3000 second cache for facts, after that it will reset Ohai and regenerate all the facts, this adds a few seconds or so overhead to discovery. 

This plugin is released as Apache License v2 same as the license of Ohai. 

# Installation 


If you are using MCollective 1.1.0 or newer you need the file `opscodeohai_facts.rb`. Otherwise, use `opscodeohai.rb`.

 * The source for the plugin is [GitHub](https://github.com/puppetlabs/mcollective-plugins/tree/master/facts/ohai/)

# Configuration


You can set the following config options in the <em>server.cfg</em>

 * You have to set _factsource = opscodeohai_ in _server.cfg_ to tell it to load this plugin

If you have MCollective 1.0.x and older:

 * plugin.facter.cache_time - how long to cache for, defaults to 300

If you have Mcollective 1.1.x and newer:

 * fact\_cache\_time - how long to cache for, defaults to 300


# Usage

You should now be able to do use all your ohai facts in discovery and fact reporting.

<pre>
$ mc-facts platform_version
Report for fact: platform_version                            

        5.3                                     found 3 times
        5.4                                     found 10 times

Finished processing 13 hosts in 5007.51 ms
</pre>

You can also use all these facts in your usual discovery lookups etc. 
