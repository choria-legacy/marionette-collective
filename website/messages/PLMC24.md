---
layout: default
title: Message detail for PLMC24
toc: false
---

Example Message
---------------

    Failed to load DDL for the 'rpcutil' agent, DDLs are required: RuntimeError: failed to parse DDL file

Additional Information
----------------------

As of version 2.0.0 DDL files are required by the MCollective server.  This server indicates that it either could not find the DDL for the rpcutil agent or that there was a syntax error.

Confirm that the DDL file is installed in the agent directory and that it parses correctly using the 'mco plugin doc' command.
