---
layout: default
title: Message detail for PLMC4
toc: false
---

Detail for Marionette Collective message PLMC4
===========================================

Example Message
---------------

    Failed to start registration plugin: ArgumentError: meta.rb:6:in `gsub': wrong number of arguments (0 for 2)

Additional Information
----------------------

Registration plugins are loaded into the MCollective daemon at startup and ran on a regular interval.

This message indicate that on first start this plugin failed to run, it will show the exception class, line and exception message to assist with debugging
