---
layout: default
title: Message detail for PLMC35
toc: false
---

Detail for Marionette Collective message PLMC35
===========================================

Example Message
---------------

    Client did not request a response, surpressing reply

Additional Information
----------------------

The MCollective client can ask that the agent just performs the action and never respond.  Like when supplying the --no-results option to the 'mco rpc' application.

This log line indicates that the request was received and interpreted as such and no reply will be sent.  This does not indicate a problem generally it's just there to assist with debugging of problems.
