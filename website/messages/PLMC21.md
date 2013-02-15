---
layout: default
title: Message detail for PLMC21
toc: false
---

Example Message
---------------

    Cannot validate input 'service': Input string is longer than 40 character(s)

Additional Information
----------------------

Every input you provide to a RPC request is validated against it's DDL file. This error will be shown when the supplied data does not pass validation against the DDL.

Consult the 'mco plugin doc' command to view the DDL file for your action and input.
