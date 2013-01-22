---
layout: default
title: Message detail for PLMC8
toc: false
---

Detail for Marionette Collective message PLMC8
===========================================

Example Message
---------------

    Handling message for agent 'rpcutil' on collective 'eu_collective' with requestid 'a8a78d0ff555c931f045b6f448129846'

Additional Information
----------------------

After receiving a message from the middleware, decoding it, validating it's security credentials and doing other checks on it the MCollective daemon will pass it off to the actual agent code for processing.

Prior to doing so it will log this line indicating the agent name and sub-collective and other information that will assist in correlating the message sent from the client with those in the server logs being processed.
