---
layout: default
title: Screen Casts
toc: false
---
[blip]: http://mcollective.blip.tv/
[slideshare]: http://www.slideshare.net/mcollective
[Terminology]: /mcollective/terminology.html
[SimpleRPCIntroduction]: /mcollective/simplerpc/
[DDL]: /mcollective/reference/plugins/ddl.html

We believe screen casts give the best introduction to new concepts, so we've recorded
several to complement the documentation.

There's a [blip] channel that has all the videos, you can subscribe and follow there.
There is also a [slideshare] site where presentations will go that we do at conferences and events.

## Introductions and Guides
<ol>
<li><a href="#introduction">Introducing MCollective</a></li>
<li><a href="#ec2_demo">EC2 Hosted Demo</a></li>
<li><a href="#message_flow">Message Flow, Terminology and Components</a></li>
<li><a href="#writing_agents">Writing Agents</a></li>
<li><a href="#simplerpc_ddl">Detailed information about the DDL</a></li>
</ol>

## Tools built using MCollective
<ol>
<li><a href="#simplerpc_ddl_irb">SimpleRPC DDL IRB</a></li>
<li><a href="#mcollective_deployer">Software Deployer used by developers</a></li>
<li><a href="#exim">Managing clusters of Exim Servers</a></li>
<li><a href="#server_provisioner">Bootstrapping Puppet on EC2</a></li>
</ol>

<a name="introduction">&nbsp;</a>

### Introduction
[This video](http://youtu.be/0i7VpvC2vMM) introduces the basic concepts behind MCollective.  It predates the
SimpleRPC framework but is still valid today.

<iframe width="640" height="360" src="http://www.youtube-nocookie.com/embed/0i7VpvC2vMM" frameborder="0" allowfullscreen></iframe>

<a name="ec2_demo">&nbsp;</a>

### Message Flow, Terminology and Components
This video introduces the messaging concepts you need to know about when using MCollective.
It shows how the components talk with each other and what software needs to be installed where
on your network.  Viewing this prior to starting your deployment is recommended.

We also have a page detailing the [Terminology]

<iframe width="640" height="480" src="http://www.youtube-nocookie.com/embed/fIHW41W8jas" frameborder="0" allowfullscreen></iframe>

View more <a href="http://www.slideshare.net/">webinars</a> from <a href="http://www.slideshare.net/mcollective">Marionette Collective</a>.
<a name="writing_agents">&nbsp;</a>

### How to write an Agent, DDL and Client
Writing agents are easy, we have good documentation that can be used as a reference, [this
video](http://youtu.be/2Xhq_UqnqRE) should show you how to tie it all together though.
See the [SimpleRPC Introduction][SimpleRPCIntroduction] for reference wiki pages after viewing this video.

<iframe width="640" height="480" src="http://www.youtube-nocookie.com/embed/2Xhq_UqnqRE" frameborder="0" allowfullscreen></iframe>

<a name="simplerpc_ddl">&nbsp;</a>

### The SimpleRPC DDL
The Data Definition Language helps your clients produce more user friendly output, it ensures
input gets validated while showing online help, and it enables dynamic generation of user interfaces.
After you have watched the video, you can refer to the [DDL] wiki page for more information.

<iframe width="640" height="480" src="http://www.youtube-nocookie.com/embed/xikjjXvN6nA" frameborder="0" allowfullscreen></iframe>

<a name="simplerpc_ddl_irb">&nbsp;</a>

### SimpleRPC DDL enhanced IRB
Based on the SimpleRPC DDL, this custom IRB shell supports command completion.

<iframe width="640" height="480" src="http://www.youtube-nocookie.com/embed/xikjjXvN6nA" frameborder="0" allowfullscreen></iframe>

<a name="mcollective_deployer"> </a>

### Software Deployer using MCollective
If you ever do commissioned work based on MCollective, this deployer written using SimpleRPC may be of use.
It can be used by developers to deploy applications live into production using a defined
API and process.

<object width="640" height="385"><param name="movie" value="http://www.youtube.com/v/Fqt2SgnQn3k&amp;hl=en_US&amp;fs=1?rel=0"></param><param name="allowFullScreen" value="true"></param><param name="allowscriptaccess" value="always"></param><embed src="http://www.youtube.com/v/Fqt2SgnQn3k&amp;hl=en_US&amp;fs=1?rel=0" type="application/x-shockwave-flash" allowscriptaccess="always" allowfullscreen="true" width="640" height="385"></embed></object>

<a name="exim">&nbsp; </a>

### Managing Exim Clusters
A command line and dialog-based UI written to manage clusters of Exim Servers.

The code for this is [open source](http://github.com/puppetlabs/mcollective-plugins/tree/master/agent/exim/).
Unfortunately it predates SimpleRPC; we hope to port it soon.

<object width="640" height="385"><param name="movie" value="http://www.youtube.com/v/kNvoQCpJ1V4&amp;hl=en_US&amp;fs=1?rel=0"></param><param name="allowFullScreen" value="true"></param><param name="allowscriptaccess" value="always"></param><embed src="http://www.youtube.com/v/kNvoQCpJ1V4&amp;hl=en_US&amp;fs=1?rel=0" type="application/x-shockwave-flash" allowscriptaccess="always" allowfullscreen="true" width="640" height="385"></embed></object>

<a name="server_provisioner">&nbsp;</a>

### Bootstrapping Puppet on EC2 with MCollective
Modern cloud environments present a lot of challenges to automation. However, with MCollective and
some existing open source agents and plugins you can completely automate the entire process
of provisioning EC2 nodes using Puppet.

More detail is available [on this blog post](http://www.devco.net/archives/2010/07/14/bootstrapping_puppet_on_ec2_with_mcollective.php)

<iframe width="640" height="480" src="http://www.youtube-nocookie.com/embed/-iEgz9MD3qA" frameborder="0" allowfullscreen></iframe>
