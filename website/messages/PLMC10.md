---
layout: default
title: Message detail for PLMC10
toc: false
---

Example Message
---------------

    Failed to handle message: RuntimeError: none.rb:15:in `decodemsg': Could not decrypt message 

Additional Information
----------------------

When a message arrives from the middleware it gets decoded, security validated and then dispatched to the agent code.

There exist a number of errors that can happen here, some are handled specifically others will be logged by this "catch all" handler.

Generally there should not be many messages logged here but we include a stack trace to assist with debugging these.

The messages here do not tend to originate from your Agents unless they are syntax error related but more likely to be situations like security failures due to incorrect SSL keys and so forth

Should you come across one that is a regular accorance in your logs please open a ticket including your backtrace and we will improve the handling of that situation
