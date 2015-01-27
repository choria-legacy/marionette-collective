---
layout: normal
title: "MCollective Plugin: MongoDB Registration Agent"
---

A plugin to store data from the [registration metadata](registration_metadata.html) plugin in an instance of MongoDB as documents per node.

The intention is to put all the node data in a easily reusable place for web UI's or Puppet masters to be able to access a cached snapshot of your data

A prototype system exist that lets you query this data from Puppet, the code is on [GitHub](https://github.com/puppetlabs/mcollective-plugins/tree/master/agent/registration-mongodb/puppet) and I have a [Blog Post](http://www.devco.net/archives/2010/09/18/puppet_search_engine_with_mcollective.php) that shows how it is used.

Shortcomings
=============

 * It has no way to know when a node is not around anymore, so you need to delete old data yourself.  Will make scripts available that does this based on last seen time.

Installation
============

You need to have the following installed:

 * The [registration metadata](registration_metadata.html)  plugin and [Registration](http://docs.puppetlabs.com/mcollective/reference/plugins/registration.html) should be set up.
 * A copy of [MongoDB](http://mongodb.org/) up and running
 * The [Mongo Ruby](http://www.mongodb.org/display/DOCS/Ruby+Language+Center) extension
 * The source is on [GitHub](https://github.com/puppetlabs/mcollective-plugins/tree/master/agent/registration-mongodb/)

Configuration
=============

<pre>
plugin.registration.mongohost = localhost
plugin.registration.mongodb = puppet
plugin.registration.collection = nodes
plugin.registration.criticalage = 3600
</pre>

With this setup you should start seeing documents show up in your mongo instance, you can verify like this:

<pre>
$ mongo
> use puppet
switched to db puppet
> db.nodes.find().count()
47
> db.nodes.find({"fqdn": "your.box.net"})
{ "_id" : ObjectId("4c3f7fb0dc3ecb087d000049"), "agentlist" : [
&lt;snip&gt;
</pre>

Discovery
======

As of version 2.1.0 of MCollective discovery is pluggable, the GitHub repo for this registration receiver includes
a discovery plugin that supports class, fact, identity and agent filters with full sub collective support.

Copy the _discovery/*_ files into your client libdir and you should see them listed in the output from *mco plugin doc*:

<pre>
% mco plugin doc
.
.
.
Discovery Methods:
  flatfile        Flatfile based discovery for node identities
  mc              MCollective Broadcast based discovery
  mongo           MongoDB based discovery for databases built using registration
</pre>

The discovery plugin takes the same configuration options as above to locate the mongodb instance and you can 
set it to be the default discovery method in your client.cfg:

<pre>
default_discovery_method = mongo
</pre>

With this in place mcollective will default to discovering against this data:

<pre>
% mco rpc rpcutil ping -W country=fr
Discovering hosts using the mongo method .... 9
.
.
</pre>

You can revert to the old method of discovery by passing in *--dm mc* to the client or by using any *-S* filter.

It understands the criticalage configuration option and will not discover nodes that have not checked in for at least that long
