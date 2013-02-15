---
layout: default
title: Message detail for PLMC26
toc: false
---

Example Message
---------------

    Functions supplied to aggregate should be a hash

Additional Information
----------------------

Internally when MCollective parse the DDL it converts the aggregate functions into a hash with the function name and any arguments.

This error indicates that the internal translation failed, this is a critical error and would probably indicate a structure problem in your DDL or a bug in MCollective
