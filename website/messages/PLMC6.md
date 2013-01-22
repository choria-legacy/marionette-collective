---
layout: default
title: Message detail for PLMC6
toc: false
---

Detail for Marionette Collective message PLMC6
===========================================

Example Message
---------------

    Message does not pass filters, ignoring

Additional Information
----------------------

When a specific MCollective daemon receives a message from a network it validates the filter before processing the message.  The filter is the list of classes, facts or other conditions that are associated with any message.

In the case where the filter does not match the specific host this line gets logged.

It's often the case for broadcast messages that all MCollective nodes will receive a message but only a subset of nodes are targetted using the filters, in that situation the nodes that received the request but should not respond to it will see this log line.

It does not indicate anything to be concerned about but if you find debugging a problem and expect a node to have responded when it shouldn't this log line will give you a hint that some condition specified in the filter did not match the local host
