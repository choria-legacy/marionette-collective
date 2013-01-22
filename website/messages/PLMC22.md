---
layout: default
title: Message detail for PLMC22
toc: false
---

Detail for Marionette Collective message PLMC22
===========================================

Example Message
---------------

    Cannot determine what entity input 'port' belongs to

Additional Information
----------------------

When writing a DDL you declare inputs into plugins using the input keyword.  Each input has to belong to a wrapping entity like in the example below:

    action "get_data", :description => "Get data from a data plugin" do
        input :source,
              :prompt      => "Data Source",
              :description => "The data plugin to retrieve information from",
              :type        => :string,
              :validation  => '^\w+$',
              :optional    => false,
              :maxlength   => 50
    end

Here the input belongs to the action entity "get_data", this error indicates that an input were found without it belonging to any specific entity
