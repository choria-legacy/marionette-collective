---
layout: default
title: Message detail for PLMC27
toc: false
---

Example Message
---------------

    Formats supplied to aggregation functions must have a :format key

Additional Information
----------------------

DDL aggregate functions can take a custom format as in the example below:

    aggregate average(:total_resources, :format => "Average: %d")

This error indicate that the :format above could not be correctly parsed.
