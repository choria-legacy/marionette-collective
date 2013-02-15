---
layout: default
title: Message detail for PLMC12
toc: false
---

Example Message
---------------

    Cache hit on 'ddl' key 'agent/nrpe'

Additional Information
----------------------

MCollective has an internal Cache used to speed up operations like parsing of DDL files.  The cache is also usable from the agents and other plugins you write.

Each entry in the cache has an associated TTL or maximum life time, once the maximum time on an item is reached it is considered expired.  

This log line indicates that a request for a cache entry was made, the entry had not yet expired and so the cached data is being returned.  

It does not indicate a problem, it's just a debugging aid
