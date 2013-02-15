---
layout: default
title: Message detail for PLMC13
toc: false
---

Example Message
---------------

    Could not find a cache called 'my_cache'

Additional Information
----------------------

MCollective has an internal Cache used to speed up operations like parsing of DDL files.  The cache is also usable from the agents and other plugins you write.

The cache is made up of many named caches, this error indicates that a cache has not yet been setup prior to trying to use it.
