---
layout: default
title: Message detail for PLMC19
toc: false
---

Example Message
---------------

    DDL requirements validation being skipped in development

Additional Information
----------------------

Usually when MCollective run it validates all requirements are met before publishing a request or processing a request against the DDL file for the agent.

This can be difficult to satisfy in development perhaps because you are still writing your DDL files or debugging issues.  

This message indicates that when MCollective detects it's running against an unreleased version of MCollective - like directly out of a Git clone - it will skip the DDL validation steps.  It is logged at a warning level as this significantly changes the behaviour of the client and server.
