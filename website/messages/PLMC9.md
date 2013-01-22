---
layout: default
title: Message detail for PLMC9
toc: false
---

Detail for Marionette Collective message PLMC9
===========================================

Example Message
---------------

    Expired Message: message 8b4fe522f0d0541dabe83ec10b7fa446 from cert=client@node created at 1358840888 is 653 seconds old, TTL is 60

Additional Information
----------------------

Requests sent from clients to servers all have a creation time and a maximum validity time called a TTL.

This message indicates that a message was received from the network but that it was determined to be too based on the TTL settings.

Usually this happens because your clocks are not in sync - something that can be fixed by rolling out a tool like ntp across your server estate.

It might also happen during very slow network conditions or when the TTL is set too low for your general network latency.
