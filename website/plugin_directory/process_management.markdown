---
layout: normal
title: "MCollective Plugin: Process Management Agent"
---

An agent that can be used for process management like the Unix _pgrep_, _kill_ and _pkill_

**WARNING:** You should use the _kill_ and _pkill_ actions with extreme caution, you can do extensive damage to the availability of your infrastructure using these.

Installation
============

 * The source is on [GitHub](https://github.com/puppetlabs/mcollective-plugins/tree/master/agent/process/)
 * You need to have the [sys-proctable](http://raa.ruby-lang.org/project/sys-proctable/) Gem installed

Usage
=====

There is a bundled _pgrep_ utility:

<pre>
% mc-pgrep ruby

 * [ ============================================================> ] 48 / 48

node1.your.com
32470 root        92.805MB  ruby /usr/sbin/mcollectived --pid=/var/run/mcollectived.pid 

node2.your.com
 1997 root        40.539MB  /usr/bin/ruby /usr/sbin/puppetd --onetime
12316 root        25.676MB  ruby /usr/sbin/mcollectived --pid=/var/run/mcollectived.pid 

&lt;snip&gt;

   ---- process list stats ----
        Matched hosts: 48
    Matched processes: 111
        Resident Size: 771.502MB
         Virtual Size: 9.318GB
</pre>

The process agent can return vast amounts of information, here is init on one machine:

<pre>
    {:pslist=>
      [{:startcode=>134512640,
        :kstkeip=>12850178,
        :root=>"/",
        :euid=>0,
        :blocked=>0,
        :cminflt=>3341998871,
        :cutime=>6433066,
        :itrealvalue=>0,
        :tty_nr=>0,
        :majflt=>20,
        :wchan=>0,
        :utime=>6,
        :name=>"init",
        :uid=>0,
        :egid=>0,
        :cmajflt=>51118,
        :signal=>0,
        :cmdline=>"init [3]",
        :ppid=>0,
        :cstime=>3222029,
        :fd=>{"10"=>"/dev/initctl"},
        :sigignore=>1475401980,
        :cwd=>"/",
        :gid=>0,
        :vsize=>2224128,
        :processor=>0,
        :environ=>{"TERM"=>"linux", "HOME"=>"/"},
        :pid=>1,
        :nswap=>0,
        :rt_priority=>0,
        :flags=>4194560,
        :nice=>0,
        :cnswap=>0,
        :comm=>"init",
        :state=>"S",
        :endcode=>134544728,
        :username=>"root",
        :rss=>172,
        :startstack=>3216723968,
        :exe=>"/sbin/init",
        :rlim=>4294967295,
        :starttime=>63,
        :policy=>0,
        :tpgid=>-1,
        :exit_signal=>0,
        :pgrp=>1,
        :minflt=>699,
        :stime=>29,
        :priority=>15,
        :session=>1,
        :kstkesp=>3216722652,
        :sigcatch=>671819267}]},
</pre>

For this reason you need to be careful about large pgrep's over large infrastructures the resulting data that needs to be transfered and processed on your machine can be staggering, each node will return as much as half a MB of serialized data.

The kill and pkill commands are not documented here and is in general not recommended to use.
