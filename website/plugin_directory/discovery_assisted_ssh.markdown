---
layout: default
title: "MCollective Plugin: Discovery-Assisted SSH"
toc: false
---


If you're using the discovery filters heavily, you might also want to use SSH based on these filters. We have 2 client scripts that help you do this at [GitHub](https://github.com/puppetlabs/mcollective-plugins/tree/master/utilities/mc-ssh).

The first uses the [Highline](http://highline.rubyforge.org/) gem and looks something like this:

<pre>
% mc-ssh -W country=za -- -l root
1. node1.your.com
2. node2.your.com
3. Exit
1
Running: ssh node1.your.com -l root
Last login: Sat Dec 18 17:01:35 2010 from nephilim.ml.org
</pre>

The second uses the [RDialog](http://rdialog.rubyforge.org/) gem to display the menu using a curses UI.
