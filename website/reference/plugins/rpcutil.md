---
layout: default
title: The rpcutil Agent
toc: false
---

We include an agent with a few utilities and helpers there to assist in retrieving information about the running mcollectived.

We aim to add the ability to initiate reloads and so forth in this agent too in future, this
will require further internal refactoring though.

## _inventory_ Action

Retrieves an inventory of the facts, classes and agents and plugins on the system, takes no arguments
and returns a hash like this:

{% highlight ruby %}
{:agents   => ["rpcutil", "discovery"],
 :facts     => {"mcollective"=>1},
 :classes   => ["common::linux", "motd"],
 :data_plugins=>["sysctl_data", "fstat_data"],
 :collectives=>["mcollective"],
 :main_collective=>"mcollective",
 :version=>"2.0.0"}
{% endhighlight %}

## `daemon_stats` Action

Retrieves statistics about the running daemon, how many messages it's handled, passed, dropped etc.

See the DDL for the agent for a full reference

{% highlight ruby %}
{:configfile=>"/etc/mcollective/server.cfg",
 :validated=>46,
 :threads=>      ["#<Thread:0xb7dcf480 sleep>",
                  "#<Thread:0xb7fba704 sleep>",
                  "#<Thread:0xb7dcfb88 run>"],
 :starttime=>1284305683,
 :agents=>["rpcutil", "discovery"],
 :unvalidated=>0,
 :pid=>15499,
 :times=>{:cutime=>0.0, :utime=>0.15, :cstime=>0.0, :stime=>0.02},
 :passed=>46,
 :total=>46,
 :filtered=>0,
 :replies=>45}
{% endhighlight %}

Replies will always be less than received since the current message has not been sent yet when the stats are gathered.

## `get_fact` Action

Retrieves a single fact from the server

{% highlight ruby %}
{:fact   => "mcollective",
 :value  => 1}
{% endhighlight %}

## `agent_inventory` Action

Returns a list of all agents with their meta data like version, author, license etc

{% highlight ruby %}
{:agents=> [
              {:agent=>"discovery",
	       :license=>"Apache License, Version 2",
	       :author=>"R.I.Pienaar <rip@devco.net>"},

	      {:agent=>"rpcutil",
	       :license=>"Apache License, Version 2.0",
	       :name=>"Utilities and Helpers for SimpleRPC Agents",
	       :url=>"http://marionette-collective.org/",
	       :description=> "General helpful actions that expose stats and internals to SimpleRPC clients",
	       :version=>"1.0",
	       :author=>"R.I.Pienaar <rip@devco.net>",
	       :timeout=>3}
	   ]
}
{% endhighlight %}

## `get_config_item` Action

Retrieves the active value for any configuration item on a server

{% highlight ruby %}
{:item   => "loglevel",
 :value  => "debug"}
{% endhighlight %}

## _ping_ Action

A simple lightweight ping action that just returns each nodes local time

{% highlight ruby %}
{:pong   => 1295471526}
{% endhighlight %}

## `collective_info` Action

Retrieves the main and sub collectives configured

For a server configured with:

{% highlight ruby %}
collectives = mcollectivedev,subdev1
main_collective = mcollectivedev
{% endhighlight %}

The following structure gets returned:

{% highlight ruby %}
{:collectives=>["mcollectivedev", "subdev1"],
 :main_collective=>"mcollectivedev"}
{% endhighlight %}
