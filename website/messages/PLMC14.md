---
layout: default
title: Message detail for PLMC14
toc: false
---

Example Message
---------------

    No block supplied to synchronize on cache 'my_cache'

Additional Information
----------------------

When using the Cache to synchronize your own code across agents or other plugins you have to supply a block to synchronise.

Correct usage would be:

    Cache.setup(:customer, 600)
    Cache(:customer).synchronize do
       # update customer record
    end

This error is raise when the logic to update the customer record is not in a block as in the example
