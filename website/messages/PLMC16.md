---
layout: default
title: Message detail for PLMC16
toc: false
---

Detail for Marionette Collective message PLMC16
===========================================

Example Message
---------------

    'hello' does not look like a numeric value

Additional Information
----------------------

When MCollective receives an argument from the command line like port=fello it consults the DDL file to determine the desired type of this parameter, it then tries to convert the input string into the correct numeric value.

This error indicates the input you provided could not be converted into the desired format.

You'll usually see this when using the 'mco rpc' command to interact with an agent.  This is usually a fatal error, the request will not be sent if it does not validate against the DDL.
