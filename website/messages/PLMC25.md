---
layout: default
title: Message detail for PLMC25
toc: false
---

Detail for Marionette Collective message PLMC25
===========================================

Example Message
---------------

    aggregate method for action 'rpcutil' is missing a function parameter

Additional Information
----------------------

DDL files can declare aggregation rules for the data returned by actions as seen below:

         summarize do
            aggregate summary(:collectives)
         end

This error indicates that you did not supply the argument - :collectives in this example.
