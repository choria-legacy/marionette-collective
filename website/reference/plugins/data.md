---
layout: default
title: Data Plugins
---
[DDL]: /mcollective/reference/plugins/ddl.html
[DiscoveryPlugins]: /mcollective/reference/plugins/discovery.html

## Overview
Up to MCollective 2.0 the discovery system could only discover against
installed agents, configuration management classes or facts and the node
identities. We're extending this to support discovery against many
sources through a simple plugin system.

*NOTE:* This feature is available since version 2.1.0

The basic idea is that you could do discovery statements like the ones
below:

{% highlight console %}
% mco find -S "fstat('/etc/rsyslog.conf').md5=/4edff591f6e38/"
{% endhighlight %}

{% highlight console %}
% mco find -S "sysctl('net.ipv4.conf.all.forwarding').value=1"
{% endhighlight %}

{% highlight console %}
% mco find -S "sysctl('net.ipv4.conf.all.forwarding').value=1 and % location=dc1"
{% endhighlight %}

You could also use these data sources in your own agents or other
plugins:

{% highlight ruby %}
action "query" do
   reply[:value] = Data.sysctl(request[:sysctl_name]).value
end
{% endhighlight %}

*NOTE:* As opposed to the [DiscoveryPlugins] which are used by the client   
to communicate to the nodes using direct addressing, data plugins on the other   
hand refer to data that the nodes can provide, and hence this uses the normal  
broadcast discovery paradigm.   

These new data sources are plugins so you can provide via the plugin
system and they require DDL documents.  The DDL will be used on both the
client and the server to provide strict validation and configuration.


The DDL for these plugins will affect the client libraries in the
following ways:

 * You will get errors if you try to discover using unknown functions
 * Your input argument values will be validated against the DDL
 * You will only be able to use output properties that are known in the DDL
 * If a plugin DDL says it needs 5 seconds to run your discovery and maximum run times will increase by 5 seconds automatically

On the servers the DDL will:

 * be used to validate known plugins
 * be used to validate input arguments
 * be used to validate requests for known output values

## Viewing or retrieving results from a data plugin

You can view the output from a data plugin using the *rpcutil* agent:

{% highlight console %}
% mco rpc rpcutil get_data source=fstat query=/etc/hosts
.
.
your.node.net
           atime: 2012-06-14 21:41:54
       atime_age: 54128
   atime_seconds: 1339706514
           ctime: 2012-01-18 20:28:34
       ctime_age: 12842128
   ctime_seconds: 1326918514
             gid: 0
             md5: 54fb6627dbaa37721048e4549db3224d
            mode: 100644
           mtime: 2010-01-12 13:28:22
       mtime_age: 76457740
   mtime_seconds: 1263302902
            name: /etc/hosts
          output: present
         present: 1
            size: 158
            type: file
             uid: 0
{% endhighlight %}

The same action can be used to retrieve data programatically.

## Writing a data plugin

### The Ruby logic for the plugin
The data plugins should not change the system in anyway, you should take
care to create plugins that only reads the state of the system.  If you
want to affect the status of the system you should write Agents.

These plugins are kept simple as they will be typed on the command line
so the following restrictions are present:

 * They can only take 1 input argument
 * They can only return simple String, Numeric or Booleans no Hashes or complex data types
 * They should be fast as these will impact discovery times and agent run times.

Writing data plugins is easy and mimic the basics of writing agents,
below we have a simple *sysctl* plugin that was used in the examples
earlier:

{% highlight ruby linenos %}
module MCollective
  module Data
    class Sysctl_data<Base
      activate_when { File.executable?("/sbin/sysctl") && Facter["kernel"] == "Linux" }

      query do |sysctl|
        shell = Shell.new("/sbin/sysctl %s" % sysctl)
        shell.runcommand

        if shell.status.exitstatus == 0
          value = shell.stdout.chomp.split(/\s*=\s*/)[1]

          if value
            value = Integer(value) if value =~ /^\d+$/
            value = Float(value) if value =~ /^\d+\.\d+$/
          end

          result[:value] = value
        end
      end
    end
  end
end
{% endhighlight %}

The class names have to be *Something_data* and they must inherit from
*Base* as in the example here. The file would be saved in the *libdir*
as *data/sysctl_data.rb* and *data/sysctl_data.ddl*.

This plugin will only be activated if the file */sbin/sysctl* exist, is
executable and if the system is a Linux server. This allow us to install
it on a Windows machine where it will just be disabled and those
machines will never be discovered using this function.

We then create a block that would be the main body of the query.  We use
the *MCollective::Shell* class to run sysctl, parse the output and save
it into the *result* hash.

The result hash is the only way to return values from these plugins. You
can only save simple strings, numbers or booleans in the result.

### The DDL for the plugin
As mentioned every data plugin requires a DDL.  These DDL files mimic
those of the [SimpleRPC Agents][DDL].

Below you'll find a DDL for the above sysctl data plugin:

{% highlight ruby linenos %}
metadata    :name        => "Sysctl values",
            :description => "Retrieve values for a given sysctl",
            :author      => "R.I.Pienaar <rip@devco.net>",
            :license     => "ASL 2.0",
            :version     => "1.0",
            :url         => "http://marionette-collective.org/",
            :timeout     => 1

dataquery :description => "Sysctl values" do
    input :query,
          :prompt => "Variable Name",
          :description => "Valid Variable Name",
          :type => :string,
          :validation => /^[\w\-\.]+$/,
          :maxlength => 120

    output :value,
           :description => "Kernel Parameter Value",
           :display_as => "Value"
end
{% endhighlight %}

The *timeout* must be set correctly, if your data source is slow you
need to reflect that in the timeout here.  The timeout will be used on
the clients to decide how long to wait for discovery responses from the
network so getting this wrong will result in nodes not being discovered.

Each data plugin can only have one *dataquery* block with exactly 1
*input* block but could have multiple *output* blocks.

It's important to get the validation correct, here we only accept the
characters we know are legal in sysctl variables on Linux.  We will
specifically never allow backticks to be used in arguments to avoid
accidental shell exploits.

Note the correlation between output names and the use in discovery and
agents here we create an output called *value* this means we would use
it in discovery as:

{% highlight console %}
% mco find -S "sysctl('net.ipv4.conf.all.forwarding').value=1"
{% endhighlight %}

And we would output the result from our plugin code as:

{% highlight ruby linenos %}
result[:value] = value
{% endhighlight %}

And in any agent where we might use the data source:

{% highlight ruby linenos %}
something = Data.sysctl('net.ipv4.conf.all.forwarding').value
{% endhighlight %}

These have to match everywhere, you cannot reference undeclared data and
you cannot use input that does not validate against the DDL declared
validations.

Refer to the full [DDL] documentation for details on all possible values
of the *metadata*, *input* and *output* blocks.

## Auto generated documentation
As with agents the DDL can be used to generate documentation, if you
wanted to know what the input and output values are for a specific
plugin you can use *mco plugin doc* to see generated documentation.

{% highlight console %}
% mco plugin doc sysctl
Sysctl values
=============

Retrieve values for a given sysctl

      Author: R.I.Pienaar <rip@devco.net>
     Version: 1.0
     License: ASL 2.0
     Timeout: 1
   Home Page: http://marionette-collective.org/

QUERY FUNCTION INPUT:

              Description: Valid Variable Name
                   Prompt: Variable Name
                     Type: string
               Validation: (?-mix:^[\w\-\.]+$)
                   Length: 120

QUERY FUNCTION OUTPUT:

           value:
              Description: Kernel Parameter Value
               Display As: Value

{% endhighlight %}

## Available plugins for a node You can use the *mco inventory*
application to see remotely what plugins a node has available:

{% highlight console %}
% mco inventory your.node
Inventory for your.node:

   .
   .
   .

   Data Plugins:
      fstat           sysctl

{% endhighlight %}
