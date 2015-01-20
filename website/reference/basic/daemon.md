---
layout: default
title: Controlling the Daemon
---

The main daemon that runs on nodes keeps internal stats and supports reloading of agents and changing
logging level without restarting.

If you want to reload all the agents without restarting the daemon you can just send it signal *USR1*
and it will reload its agents.

You can send *USR2* to cycle the log level through DEBUG to FATAL and back again, just keep sending
the signal and look at the logs.

You can send *WINCH* to flush and reopen logfiles, for logrotation purposes.

Reloading agents work in most cases though we recommend a full daemon restart in production use
due to the nature of the ruby class loading system.  If you are changing agent contents and relying
on the reload behavior you might end up with agents not being in a consistent state.

## Obtaining daemon statistics

The daemon keeps a number of statistics about its operation, you can view these using the _inventory_
application:

{% highlight console %}
% mco inventory example.com
   Server Statistics:
                      Version: 2.2.0
                   Start Time: Mon Sep 24 17:37:28 +0100 2012
                  Config File: /etc/puppetlabs/agent/mcollective/server.cfg
                  Collectives: mcollective, fr_collective
              Main Collective: mcollective
                   Process ID: 24473
               Total Messages: 52339
      Messages Passed Filters: 44118
            Messages Filtered: 8221
             Expired Messages: 0
                 Replies Sent: 29850
         Total Processor Time: 527.06 seconds
                  System Time: 349.32 seconds

.
.
.
{% endhighlight %}

The statistics mean:

|Statistic   |Meaning                                    |
|------------|-------------------------------------------|
|Start Time             |Local time on the node when the daemon started|
|Collectives            |All known collectives this agent responds on|
|Main Collective        |The primary collective|
|Process ID             |The process ID of the mcollectived|
|Total Messages         |Total messages received from the middleware|
|Messages Passed Filters|Amount of messages that was determined to be applicable to this node based on filters|
|Messages Filtered      |Messages that did not apply to this node|
|Expired Messages       |Received messages that had expired their TTL values|
|Replies Sent           |Not all received messages result in replies, this counts the actual replies sent|
|Total Processor Time   |Processor time including user and system time consumed since start|
|System Time            |System Processor time only|

You can get the raw values using the *rpcutil* agent using the *daemon_stats* action.

{% highlight console %}
% mco rpc rpcutil daemon_stats
Discovering hosts using the mongo method .... 26

 * [ ============================================================> ] 26 / 26

.
.
.

example.com
               Agents: ["stomputil",
                        "nrpe",
                        "package",
                        "rpcutil",
                        "rndc",
                        "urltest",
                        "iptables",
                        "puppetd",
                        "discovery",
                        "service",
                        "eximng",
                        "filemgr",
                        "process"]
          Config File: /etc/puppetlabs/agent/mcollective/server.cfg
        Failed Filter: 168432
        Passed Filter: 91231
                  PID: 1418
              Replies: 91127
           Start Time: 1347545937
              Threads: ["#<Thread:0x7f44350964f8 sleep>",
                        "#<Thread:0x7f4434f7f538 sleep>",
                        "#<Thread:0x7f44390ce368 sleep>",
                        "#<Thread:0x7f44350981b8 run>"]
                Times: {:cutime=>1111.13, :utime=>3539.21, :cstime=>1243.64, :stime=>5045.21}
       Total Messages: 259842
          TTL Expired: 179
      Failed Security: 0
   Security Validated: 259842
              Version: 2.2.0


Summary of Agents:

          package = 26
          process = 26
        discovery = 26
          service = 26
          puppetd = 26
          filemgr = 26
             nrpe = 26
          rpcutil = 26
        stomputil = 26
         iptables = 11
          urltest = 7
          libvirt = 4
           eximng = 4
     registration = 3
             rndc = 3
    angelianotify = 2

Summary of Version:

    2.2.0 = 26

Finished processing 26 / 26 hosts in 289.20 ms
{% endhighlight %}

## Obtaining running configuration settings

All configuration settings of any mcollective daemon can be retrieved using the *get_config_item*
action of the *rpcutil* agent:

{% highlight console %}
% mco rpc rpcutil get_config_item item=collectives -I example.com
Discovering hosts using the mongo method .... 1

 * [ ============================================================> ] 1 / 1


example.com:
   Property: collectives
      Value: ["mcollective", "fr_collective"]


Summary of Value:

      mcollective = 1
    fr_collective = 1


Finished processing 1 / 1 hosts in 59.05 ms
{% endhighlight %}
