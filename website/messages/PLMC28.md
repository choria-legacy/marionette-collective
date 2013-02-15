---
layout: default
title: Message detail for PLMC28
toc: false
---

Example Message
---------------

    Formats supplied to aggregation functions should be a hash

Additional Information
----------------------

DDL aggregate functions can take a custom format as in the example below:

    aggregate average(:total_resources, :format => "Average: %d")

This error indicate that the :format above was not supplied as a hash as in the above example
