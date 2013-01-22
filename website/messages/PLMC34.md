---
layout: default
title: Message detail for PLMC34
toc: false
---

Detail for Marionette Collective message PLMC34
===========================================

Example Message
---------------

    setting meta data in agents have been deprecated, DDL files are now being used for this information. Please update the 'package' agent

Additional Information
----------------------

In the past each MCollective agent had a metadata section containing information like the timeout.

As of 2.2.0 the agents will now consult the DDL files that ship with each agent for this purpose so the metadata in agents are not used at all.

In order to remove confusing duplication setting metadata in agents have been deprecated and from version 2.4.0 will not be supported at all.

Please update your agent by removing the metadata section from it and make sure the DDL file has the correct information instead.
