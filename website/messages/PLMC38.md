---
layout: default
title: Message detail for PLMC38
toc: false
---

Detail for Marionette Collective message PLMC38
===========================================

Example Message
---------------

    Found plugin configuration 'exim.activate_agent' with value 'y'

Additional Information
----------------------

The administrator can choose that a certain agent that is deployed on this machine should not be made available to the network.

To do this you would add a configuration value like this example to the mcollective server.cfg:

    plugin.exim.activate_agent = n

If this value is "1", "y" or "true" the agent will be activated else it will be disabled.
