---
layout: default
title: Validator Plugins
---
[DDL]: /mcollective/reference/plugins/ddl.html

## Overview
MCollective provides extensive input data validation to prevent attacks and
injections into your agents preventing attack vectors like Shell Injection
Attacks.

Traditionally we shipped a number of pre-made validator plugins that could be
used in agents and DDL files but you were not capable fo adding your own easily.

As of version 2.2.0 you can write new Validator plugins that allow you to extend
the DDL and Agent validation methods.

## Writing A New Validator
We'll write a new validator plugin that can validate a string matches valid Exim
message IDs like *1Svk5S-0001AW-I5*.

Validator plugins and their DDL files goes in the libdir in the *validator*
directory on both the servers and the clients.

### The Ruby Plugin
The basic validator plugin that will validate any data against this regular
expression can be seen here:

{% highlight ruby %}
module MCollective
  module Validator
    class Exim_msgidValidator
      def self.validate(msgid)
        Validator.typecheck(msgid, :string)

        raise "Not a valid Exim Message ID" unless msgid.match(/(?:[+-]\d{4} )?(?:\[\d+\] )?(\w{6}\-\w{6}\-\w{2})/)
      end
    end
  end
end
{% endhighlight %}

All you need to do is provide a *self.validate* method that takes 1 argument and
do whatever validation you want to do against the input data.

Here we first confirm it is a string and then we do the regular expression match
against that.  Any Exception that gets raised will result in validation failing.

### The DDL
As with other plugins these plugins need a DDL file, all they support is the
metadata section.

{% highlight ruby %}
metadata    :name        => "Exim Message ID",
            :description => "Validates that a string is a Exim Message ID",
            :author      => "R.I.Pienaar <rip@devco.net>",
            :license     => "ASL 2.0",
            :version     => "1.0",
            :url         => "http://devco.net/",
            :timeout     => 1
{% endhighlight %}

## Using the Validator in a DDL
You can use the validator in any DDL file, here is a snippet matching an input
using the new *exim_msgid* validator:

{% highlight ruby %}
action "retrymsg", :description => "Retries a specific message" do
    display :ok

    input :msgid,
          :prompt      => "Message ID",
          :description => "Valid message id currently in the mail queue",
          :type        => :string,
          :validation  => :exim_msgid,
          :optional    => false,
          :maxlength   => 16

    output :status,
           :description => "Status Message",
           :display_as  => "Status"
end
{% endhighlight %}

Note here we are using our new validator to validate the *msgid* input.

## Using the Validator in an Agent
Agents can also have validation, traditionally this included the normal things
like regular expressions but now here you can also use the validator plugins:

{% highlight ruby %}
action "retrymsg" do
  validate :msgid, :exim_msgid

  # call out to exim to retry the message
end
{% endhighlight %}

Here we've extended the basic *validate* helper of the RPC Agent with our own
plugin and used it to validate a specific input.

## Listing available Validators
You can obtain a list of validators using the *plugin* application:

{% highlight ruby %}
% mco plugin doc

Please specify a plugin. Available plugins are:

.
.
.

Validator Plugins:
  array                     Validates that a value is included in a list
  exim_msgid                Validates that a string is a Exim Message ID
  ipv4address               Validates that a value is an ipv4 address
  ipv6address               Validates that a value is an ipv6 address
  length                    Validates that the length of a string is less or equal to a specified value
  regex                     Validates that a string matches a supplied regular expression
  shellsafe                 Validates that a string is shellsafe
  typecheck                 Validates that a value is of a certain type

{% endhighlight %}

Note our new *exim_msgid* plugin appears in this list.

