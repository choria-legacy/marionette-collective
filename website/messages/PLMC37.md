---
layout: default
title: Message detail for PLMC37
toc: false
---

Detail for Marionette Collective message PLMC37
===========================================

Example Message
---------------

    Starting default activation checks for the 'rpcutil' agent

Additional Information
----------------------

Each time the MCollective daemon starts it loads each agent from disk.  It then tries to determine if the agent should start on this node by using the activate_when method or per-agent configuration.

This is a debug statement that shows you it is about to start interacting with the logic in the agent to determine if it should be made available or not.
