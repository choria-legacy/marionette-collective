---
layout: default
title: Message detail for PLMC17
toc: false
---

Detail for Marionette Collective message PLMC17
===========================================

Example Message
---------------

    'flase' does not look like a boolean value

Additional Information
----------------------

When MCollective receives an argument from the command line like force=true it consults the DDL file to determine the desired type of this parameter, it then tries to convert the input string into the correct boolean value.

This error indicates the input you provided could not be converted into the desired boolean format.  It wil accept "true", "t", "yes", "y" and "1" as being true.  It will accept "false", "f", "no", "n", "0" as being false.

You'll usually see this when using the 'mco rpc' command to interact with an agent.  This is usually a fatal error, the request will not be sent if it does not validate against the DDL.
