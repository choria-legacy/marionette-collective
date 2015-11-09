---
layout: default
title: Discovery Plugins
---
[DDL]: /mcollective/reference/plugins/ddl.html

## Overview
Up to MCollective 2.0.0 the discovery system could only discover against
the network by doing broadcasts over the middleware.

The _direct addressing_ capability introduced in 2.0.0 enables users to
communicate with a node without doing broadcast if they know the
configured identity of that node.

In version 2.1.0 we are introducing a new kind of plugin that works on
the client system to do discovery against any data source that can
return a list of identities such as flatfiles or databases.

## Configuring and using discovery plugins
Your mcollective client has a setting called *default_discovery_method*
that defaults to *mc*, if you change this in your _client.cfg_ to
another known plugin you can use that instead.

To get a list of known discovery plugins use the _mco plugin_
application:

{% highlight console %}
% mco plugin doc
Please specify a plugin. Available plugins are:

Discovery Methods:
  flatfile        Flatfile based discovery for node identities
	mc              MCollective Broadcast based discovery
	mongo           MongoDB based discovery for databases built using registration
{% endhighlight %}

Each plugin can have a different set of capabilities, for example a
flatfile with only hostnames cannot do class or fact based filters and
you will receive an error if you tried to do so.  You can see the
capabilities of each plugin using the _mco plugin_ application:

{% highlight console %}
$ mco plugin doc flatfile
flatfile
========

Flatfile based discovery for node identities

      Author: R.I.Pienaar <rip@devco.net>
     Version: 0.1
     License: ASL 2.0
     Timeout: 0
   Home Page: https://docs.puppetlabs.com/mcollective/

DISCOVERY METHOD CAPABILITIES:
      Filter based on mcollective identity
{% endhighlight %}

Here you can see the only capability that this plugin has is to filter
against identities.

These plugins require DDL files to be written and distributed when
installing each plugin.

When using the mcollective CLI you can choose which plugin to use per
request, some plugins require arguments like the file to discover
against:

{% highlight console %}
$ mco rpc rpcutil ping --dm flatfile --do /some/text/file
{% endhighlight %}

In the case of the flatfile plugin there is a convenient shortcut
available on all client applications that has the same effect as above:

{% highlight console %}
$ mco rpc rpcutil ping --nodes /some/text/file
{% endhighlight %}

Any request that uses the compound filters using *-S* will be forced to
use the network broadcast discovery method.

## Writing a discovery plugin
Writing your own discovery plugin is very simple, you need to provide
one method that returns an array of node names.

The plugins only need to be present on the client machines but no harm
in installing them on all machines.  They need to be installed into the
*discovery* directory in the usual plugin directory.  You can use the
*mco plugin package* command to create RPM or DEB packages for these
plugins.

{% highlight ruby linenos %}
module MCollective
  class Discovery
    class Flatfile
      def self.discover(filter, timeout, limit=0, client=nil)
        unless client.options[:discovery_options].empty?
          file = client.options[:discovery_options].first
        else
          raise "The flatfile discovery method needs a path to a text file"
        end

        raise "Cannot read the file %s specified as discovery source" % file unless File.readable?(file)

        discovered = []

        hosts = File.readlines(file).map{|l| l.chomp}

        unless filter["identity"].empty?
          filter["identity"].each do |identity|
            identity = Regexp.new(identity.gsub("\/", "")) if identity.match("^/")

            if identity.is_a?(Regexp)
              discovered = hosts.grep(identity)
            elsif hosts.include?(identity)
              discovered << identity
            end
          end
        else
          discovered = hosts
        end

        discovered
      end
    end
  end
end
{% endhighlight %}

This is the *flatfile* plugin that is included in the distribution.  You
can see it using the *client.options\[:discovery_options\]* array to get
access to the file supplied using the *--do* command line argument,
reading that file and doing either string or Regular Expression matching
against it finally returning the list of nodes.

As mentioned each plugin needs a DDL, the DDL for this plugin is very
simple:

{% highlight ruby linenos %}
metadata    :name        => "flatfile",
            :description => "Flatfile based discovery for node identities",
            :author      => "R.I.Pienaar <rip@devco.net>",
            :license     => "ASL 2.0",
            :version     => "0.1",
            :url         => "https://docs.puppetlabs.com/mcollective/",
            :timeout     => 0

discovery do
    capabilities :identity
end
{% endhighlight %}

Here we expose just the one capability, valid capabilities would be
*:classes*, *:facts*, *:identity*, *:agents* and *:compound*.  In
practise you cannot create a plugin that supports the *:compound*
capability as mcollective will force the use of the *mc* plugin if you
use those.
