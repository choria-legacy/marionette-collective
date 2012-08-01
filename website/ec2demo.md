---
layout: default
title: EC2 Demo
toc: false
---
[Amazon Console]: https://console.aws.amazon.com/ec2/
[Puppet based Service]: http://projects.puppetlabs.com/projects/mcollective-plugins/wiki/AgentService
[Puppet based Package]: http://projects.puppetlabs.com/projects/mcollective-plugins/wiki/AgentPackage
[NRPE]: http://projects.puppetlabs.com/projects/mcollective-plugins/wiki/AgentNRPE
[Meta Registration]: http://projects.puppetlabs.com/projects/mcollective-plugins/wiki/RegistrationMetaData
[URL Tester]: https://github.com/ripienaar/mc-plugins/tree/master/agent/urltest
[Registration]: /mcollective/reference/plugins/registration.html
[Registration Monitor]: http://projects.puppetlabs.com/projects/mcollective-plugins/wiki/AgentRegistrationMonitor

We've created an Amazon hosted demo of mcollective that can give you a quick feel
for how things work without all the hassle of setting up from scratch.

The demo uses the new Amazon CloudFormation technology that you can access using the [Amazon Console].
To access the AMI you must select the 'EU - West' Region. Also, prior to following the steps in the demo
please create a SSH keypair and register it under the EC2 tab in the console for that region.

The video below shows how to get going with the demo and runs through a few of the availbable options.
For best experience please maximise the video.

The two passwords requested during creation is completely arbitrary you can provide anything there and
past entering them on the creation page you don't need to know them again later.  They are used internally
to the demo without you being aware of them.

You'll need to enter the url _http://mcollective-120-demo.s3.amazonaws.com/cloudfront`_`demo.json_ into the
creation step.

<iframe width="640" height="360" src="http://www.youtube-nocookie.com/embed/Hw0Z1xfg050" frameborder="0" allowfullscreen></iframe>

## Agents
The images all have the basic agents going as well as some community ones:

 * [Puppet based Service]
 * [Puppet based Package]
 * [NRPE]
 * [Meta Registration]
 * [URL Tester]

## Registration
The main node will have [Registration] setup and the community [Registration Monitor] agent,
look in */var/tmp/mcollective* for meta data from all your nodes.
