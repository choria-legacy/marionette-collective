---
layout: mcollective
title: EC2 Demo
disqus: true
---
[Amazon Console]: https://console.aws.amazon.com/ec2/
[Puppet based Service]: http://code.google.com/p/mcollective-plugins/wiki/AgentService
[Puppet based Package]: http://code.google.com/p/mcollective-plugins/wiki/AgentPuppetPackage
[NRPE]: http://code.google.com/p/mcollective-plugins/wiki/AgentNRPE
[Meta Registration]: http://code.google.com/p/mcollective-plugins/wiki/RegistrationMetaData
[URL Tester]: http://code.google.com/p/mcollective-plugins/wiki/AgentUrltest
[Discovery Aware SSH]: http://code.google.com/p/mcollective-plugins/wiki/UtilitiesSSH
[Registration]: /reference/plugins/registration.html
[Registration Monitor]: http://code.google.com/p/mcollective-plugins/wiki/AgentRegistrationMonitor

# {{page.title}}
We've created an Amazon hosted demo of mcollective that can give you a quick feel 
for how things work without all the hassle of setting up from scratch.

It would also be a good test bed for new agents etc.

<embed src="http://blip.tv/play/hfMOgfSIRgA" type="application/x-shockwave-flash" width="640" 
height="385" allowscriptaccess="always" allowfullscreen="true"></embed>

## AMIs
The AMI is based in the *EU West* availability zone, we currently have just the one 
AMI id that is running mcollective 0.4.2.

| AMI ID | Description |
| ------ | ----------- |
| ami-21c8e355 | Server and Node for MCollective 0.4.2| 

The video shows you the basic steps to get it going using the [Amazon Console][].

We can create a copy of it in the US if there's demand for that.

## Security Groups 
Just in case it's not clear in the video you should open ports *22* and *6163* to make 
sure it all works, technically you only need to open 6163 on the main server only the 
rest only need it for outgoing.

## Starting main node
To start the main node you need to provide some user data:

{% highlight ini %}
    mcollective=server
{% endhighlight %}

and then once it's up you should run the *start-mcollective-demo.rb* 
as root to bootstrap the first node, it'll provide user data that you should then give 
to all the test nodes you want to boot.

## Agents 
The images all have the basic agents going as well as some community ones:

 * [Puppet based Service][]
 * [Puppet based Package][]
 * [NRPE][]
 * [Meta Registration][]
 * [URL Tester][]
 * [Discovery Aware SSH][]

## Registration
The main node will have [Registration] setup and the community [Registration Monitor] agent, 
look in */var/tmp/mcollective* for meta data from all your nodes.

The current AMI has 1 x left over file there from when I was building the AMI.
