---
layout: default
title: Message detail for PLMC36
toc: false
---

Example Message
---------------

    Unknown action 'png' for agent 'rpcutil'

Additional Information
----------------------

Agents are made up of a number of named actions.  When the MCollective Server receives a request it double checks if the agent in question actually implements the logic for a specific action.

When it cannot find the implementation this error will be raised.  This is an unusual situation since at this point on both the client and the server the DDL will already have been used to validate the request and the DDL would have indicated that the action is valid. 

Check your agent code and make sure you have code like:

    action "the_action" do
        .
        .
    end
