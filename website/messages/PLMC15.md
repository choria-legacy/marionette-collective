---
layout: default
title: Message detail for PLMC15
toc: false
---

Detail for Marionette Collective message PLMC15
===========================================

Example Message
---------------

    No item called 'nrpe_agent' for cache 'ddl'

Additional Information
----------------------

MCollective has an internal Cache used to speed up operations like parsing of DDL files.  The cache is also usable from the agents and other plugins you write.

The cache stored items using a key, this error will be logged and raised when you try to access a item that does not yet exist in the cache.
