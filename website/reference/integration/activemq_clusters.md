---
layout: default
title: ActiveMQ Clustering
toc: false
---
[MessageFlow]: /mcollective/reference/basic/messageflow.html
[NetworksOfBrokers]: http://activemq.apache.org/networks-of-brokers.html
[SampleConfig]: http://github.com/puppetlabs/marionette-collective/tree/master/ext/activemq/
[fuse_cluster]: https://access.redhat.com/documentation/en-US/Fuse_Message_Broker/5.5/html/Using_Networks_of_Brokers/files/front.html
[activemq_network]: /mcollective/deploy/middleware/activemq.html#settings-for-networks-of-brokers

Relying on existing middleware tools and not re-inventing the transport wheel ourselves means we can take advantage of a lot of the built in features they provide.  One such feature is clustering in ActiveMQ that allows for highly scalable and flexible network layouts.

We'll cover here how to build a multi data center network of ActiveMQ servers with a NOC, the NOC computers would not need to send any packets direct to the nodes they manage and thanks to our meta data based approach to addressing machines they do not even need to know IPs or hostnames.

There is an example of a 3 node cluster in the [ext/activemq directory of the MCollective source][SampleConfig].

## Network Design

### Network Layout

![ActiveMQ Cluster](/mcollective/images/activemq-multi-locations.png)

The diagram above shows our sample network, I am using the same techniques to put an ActiveMQ in each of 4 countries and then having local nodes communicate to in-country ActiveMQ nodes.

* These are the terminals of your NOC staff, they run the client code, these could also be isolated web servers for running admin tools etc.
* Each location has its own instance of ActiveMQ and nodes would only need to communicate to their local ActiveMQ.  This greatly enhances security in a setup like this.
* The ActiveMQ instances speak to each other using a protocol called OpenWire, you can run this over IPSec or you could use the native support for SSL.
* These are the servers being managed, they run the server code.  No direct communications needs to be in place between NOC and managed servers.

Refer to the [MessageFlow][] document to see how messages would traverse the middleware in a setup like this.

### General Observations
The main design goal here is to promote network isolation, the staff in your NOC are often high churn people, you'll get replacement staff relatively often and it's a struggle to secure what information they carry and how and when you can trust them.

Our model of using middleware and off-loading authentication and authorization onto the middleware layer means you only need to give NOC people appropriate access to the middleware and not to each individual machine.

Our usage of meta data to address machines rather than hostnames or ip address means you do not need to divulge this information to NOC staff, from their point of view they access machines like this:

* All machines in _datacenter=a_
* AND all machines with puppet class _/webserver/_
* AND all machines with Facter fact _customer=acmeinc_

In the end they can target the machines they need to target for maintenance commands as above without the need for any info about hostnames, ips, or even what/where data center A is.

This model works particularly well in a Cloud environment where hostnames are dynamic and not under your control, in a cloud like Amazon S3 machines are better identified by what AMI they have booted and in what availability zones they are rather than what their hostnames are.

## ActiveMQ Configuration

ActiveMQ supports many types of cluster; we think their Network of Brokers model works best for MCollective.

You will need to configure your ActiveMQ servers with everything from the ["Settings for Networks of Brokers" section of the ActiveMQ config reference][activemq_network]. Note the comments about the bi-directional connections: In the example network described above, you could either configure a pair of connectors on each datacenter broker to connect them to the NOC, or configure several pairs of connectors on the NOC broker to connect it to every datacenter. Do whichever makes sense for your own convenience and security needs.

There is also a set of example config files in the [ext/activemq directory of the MCollective source][SampleConfig]; refer to these while reading the config reference. 

See [the ActiveMQ docs][NetworksOfBrokers] or [the Fuse docs][fuse_cluster] for more detailed info about networks of brokers.

