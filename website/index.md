---
layout: mcollective
title: Overview
---
[Introduction]: /introduction/

# {{page.title}}

The Marionette Collective aka. mcollective is a framework to build server orchestration
or parallel job execution systems.

Mcollective's primary use is to programmatically execute actions on clusters of servers.
In this regard it operates in the same space as tools like Func, Fabric or Capistrano.

By not relying on central inventories and tools like SSH, it's not simply a fancy SSH
"for loop". MCollective uses modern tools like Publish Subscribe Middleware and modern
philosophies like real time discovery of network resources using meta data and not
hostnames. Delivering a very scalable and very fast parallel execution
environment.

The focus is on catering to the needs of enterprises and large deploys.  Pluggable Authentication,
Authorization and Auditing capabilities sets it apart from other tools in this space.

Read the [Introduction][] page for a full
introduction about what you can do with mcollective and some of our goals and approaches.

Below is a quick screencast that introduces the main elements - maximise it for best viewing.

<embed src="http://blip.tv/play/hfMOgenPYQA" type="application/x-shockwave-flash" width="600" height="301"
allowscriptaccess="always" allowfullscreen="true"></embed>
