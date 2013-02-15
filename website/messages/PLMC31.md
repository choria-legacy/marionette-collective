---
layout: default
title: Message detail for PLMC31
toc: false
---

Example Message
---------------

    No dataquery has been defined in the DDL for data plugin 'package'

Additional Information
----------------------

Each data plugin requires a DDL that has a 'dataquery' block in it.

    dataquery :description => "Agent Meta Data" do
        .
        .
    end

This error indicates that the DDL file for a specific data plugin did not contain this block.
