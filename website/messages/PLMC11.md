---
layout: default
title: Message detail for PLMC11
toc: false
---

Example Message
---------------

    Cache expired on 'ddl' key 'agent/nrpe'

Additional Information
----------------------

MCollective has an internal Cache used to speed up operations like parsing of DDL files.  The cache is also usable from the agents and other plugins you write.

Each entry in the cache has an associated TTL or maximum life time, once the maximum time on an item is reached it is considered expired.  Next time anything attempts to read this entry from the cache this log line will be logged.

This is part of the normal operations of MCollective and doesn't indicate any problem.  We log this debug message to help you debug your own use of the cache.
