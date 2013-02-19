---
layout: default
title: Getting Started
---
[Screencasts]: /mcollective/screencasts.html
[ActiveMQ]: http://activemq.apache.org/
[ActiveMQ Getting Started]: http://activemq.apache.org/getting-started.html
[EC2Demo]: /mcollective/ec2demo.html
[Stomp]: http://stomp.codehaus.org/Ruby+Client
[DepRPMs]: http://www.marionette-collective.org/activemq/
[DebianBug]: http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=562954
[SecurityWithActiveMQ]: /mcollective/reference/integration/activemq_security.html
[ActiveMQClustering]: /mcollective/reference/integration/activemq_clusters.html
[ActiveMQSamples]: http://github.com/puppetlabs/marionette-collective/tree/master/ext/activemq/examples/
[ActiveMQSingleBrokerSample]: http://github.com/puppetlabs/marionette-collective/raw/master/ext/activemq/examples/single-broker/activemq.xml
[ConfigurationReference]: /mcollective/reference/basic/configuration.html
[Terminology]: /mcollective/terminology.html
[SimpleRPCIntroduction]: /mcollective/simplerpc/
[ControllingTheDaemon]: /mcollective/reference/basic/daemon.html
[SSLSecurityPlugin]: /mcollective/reference/plugins/security_ssl.html
[AESSecurityPlugin]: /mcollective/reference/plugins/security_aes.html
[ConnectorActiveMQ]: /mcollective/reference/plugins/connector_activemq.html
[ConnectorRabbitMQ]: /mcollective/reference/plugins/connector_rabbitmq.html
[MessageFlowCast]: /mcollective/screencasts.html#message_flow
[Plugins]: http://projects.puppetlabs.com/projects/mcollective-plugins/wiki
[MCDownloads]: http://www.puppetlabs.com/downloads/mcollective/
[RubyGems]: http://packages.debian.org/search?suite=default&section=all&arch=any&searchon=names&keywords=rubygems

Getting started using Debian based distribution like Debian squeeze and Ubuntu is easy as DEBs are available for most the required components.  This guide walks you through the process.

## Requirements
We try to keep the requirements on external Gems to a minimum, you only need:

 * A Stomp server, tested against [ActiveMQ]
 * Ruby
 * RubyGems
 * [Ruby Stomp Client][Stomp]

## Packages

We strongly recommend you set up a local Apt repository that will host all the packages on your LAN, you can get the prerequisite packages here:

 * [ActiveMQ]
 * Java - OpenJDK that is included with your distribution
 * Ruby - included with your distribution
 * [RubyGems]
 * Stomp Ruby Gem
 * [MCollective][MCDownloads] - mcollective-1.x.x-1_all.deb, mcollective-common-1.x.x-1_all.deb, mcollective-client-1.x.x-1_all.deb

The rest of this guide will assume you set up a Apt repository.  Puppet Labs hosts a Apt repository with all these dependencies at _apt.puppetlabs.com_.

## ActiveMQ
ActiveMQ is currently the most used and tested middleware for use with MCollective.

You need at least one ActiveMQ server on your network, all the nodes you wish to manage will connect to the central ActiveMQ server.
Later on your can [cluster the ActiveMQ servers for availability and scale][ActiveMQClustering].

### Install

On the server that you chose to configure as the ActiveMQ server:

{% highlight console %}
% apt-get install openjdk-6-jre
{% endhighlight %}

ActiveMQ installation instructions can be found [here][ActiveMQ Getting Started].

### Configuring

Initially you'll just keep it simple with a single ActiveMQ broker and a basic user setup, further security information for ActiveMQ
can be found [here][SecurityWithActiveMQ]

Place the following in your ActiveMQ configuration path as *activemq.xml*. You can download this file from [GitHub][ActiveMQSingleBrokerSample]

Other examples are also available from [GitHub][ActiveMQSamples]

{% highlight xml %}
<beans
  xmlns="http://www.springframework.org/schema/beans"
  xmlns:amq="http://activemq.apache.org/schema/core"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-2.0.xsd
  http://activemq.apache.org/schema/core http://activemq.apache.org/schema/core/activemq-core.xsd
  http://activemq.apache.org/camel/schema/spring http://activemq.apache.org/camel/schema/spring/camel-spring.xsd">

    <broker xmlns="http://activemq.apache.org/schema/core" brokerName="localhost" useJmx="true">
        <destinationPolicy>
          <policyMap>
            <policyEntries>
              <policyEntry topic=">" producerFlowControl="false"/>
              <policyEntry queue="*.reply.>" gcInactiveDestinations="true" inactiveTimoutBeforeGC="300000" />
            </policyEntries>
          </policyMap>
        </destinationPolicy>

        <managementContext>
            <managementContext createConnector="false"/>
        </managementContext>

        <plugins>
          <statisticsBrokerPlugin/>
          <simpleAuthenticationPlugin>
            <users>
              <authenticationUser username="mcollective" password="marionette" groups="mcollective,everyone"/>
              <authenticationUser username="admin" password="secret" groups="mcollective,admin,everyone"/>
            </users>
          </simpleAuthenticationPlugin>
          <authorizationPlugin>
            <map>
              <authorizationMap>
                <authorizationEntries>
                  <authorizationEntry queue=">" write="admins" read="admins" admin="admins" />
                  <authorizationEntry topic=">" write="admins" read="admins" admin="admins" />
                  <authorizationEntry topic="mcollective.>" write="mcollective" read="mcollective" admin="mcollective" />
                  <authorizationEntry queue="mcollective.>" write="mcollective" read="mcollective" admin="mcollective" />
                  <authorizationEntry topic="ActiveMQ.Advisory.>" read="everyone" write="everyone" admin="everyone"/>
                </authorizationEntries>
              </authorizationMap>
            </map>
          </authorizationPlugin>
        </plugins>

        <systemUsage>
            <systemUsage>
                <memoryUsage>
                    <memoryUsage limit="20 mb"/>
                </memoryUsage>
                <storeUsage>
                    <storeUsage limit="1 gb" name="foo"/>
                </storeUsage>
                <tempUsage>
                    <tempUsage limit="100 mb"/>
                </tempUsage>
            </systemUsage>
        </systemUsage>

        <transportConnectors>
            <transportConnector name="openwire" uri="tcp://0.0.0.0:61616"/>
            <transportConnector name="stomp" uri="stomp://0.0.0.0:61613"/>
        </transportConnectors>
    </broker>
</beans>
{% endhighlight %}

This creates a user *mcollective* with the password *marionette* and give it access to read/write/admin */topic/mcollective.`*`*.  You should change this passsword.

### Starting

Start the ActiveMQ service:

{% highlight console %}
  # /etc/init.d/activemq start
{% endhighlight %}

You should see it running in the process list:

{% highlight console %}
 # ps -auxw|grep java
 activemq  3012  0.1 14.5 1155112 152180 ?      Sl   Dec28   2:02 java -Dactivemq.home=/usr/share/activemq -Dactivemq.base=/usr/share/activemq -Dcom.sun.management.jmxremote -Dorg.apache.activemq.UseDedicatedTaskRunner=true -Xmx512m -Djava.library.path=/usr/lib:/usr/lib64 -classpath /usr/share/java/tanukiwrapper.jar:/usr/share/activemq/bin/run.jar -Dwrapper.key=eg4_VvENzCmvtAKg -Dwrapper.port=32000 -Dwrapper.jvm.port.min=31000 -Dwrapper.jvm.port.max=31999 -Dwrapper.pid=3000 -Dwrapper.version=3.2.3 -Dwrapper.native_library=wrapper -Dwrapper.service=TRUE -Dwrapper.cpu.timeout=10 -Dwrapper.jvmid=1 org.tanukisoftware.wrapper.WrapperSimpleApp org.apache.activemq.console.Main start
{% endhighlight %}

You should also see it listening on port 61613 in your network stack

You should open port 61613 for all your nodes to connect to.

## Marionette Collective

There are a few packages supplied and you will have potentially two type of server:

 * Nodes that you wish to manage using mcollective need the mcollective and mcollective-common packages
 * Nodes that you wish to use to initiate requests from also known as clients need mcollective-client and mcollective-common packages

A machine can be both at once, in which case you need to install all 3 packages.  We'll work on the assumption here that you wish to both manage your machine and use it as a client by installing all 3 packages on our initial node.

### Installation

{% highlight console %}
  # apt-get install mcollective mcollective-client mcollective-common
  # gem install stomp
{% endhighlight %}


## Configuring
You'll need to tweak some configs in */etc/mcollective/client.cfg*, a full reference of config settings can be
found [here][ConfigurationReference]:

We're assuming you called the machine running ActiveMQ *stomp.example.net* please change as appropriate

{% highlight ini %}
  # main config
  libdir = /usr/libexec/mcollective
  logfile = /dev/null
  loglevel = error

  # connector plugin config
  connector = activemq
  plugin.activemq.pool.size = 1
  plugin.activemq.1.host = stomp.example.net
  plugin.activemq.1.port = 61613
  plugin.activemq.1.user = mcollective
  plugin.activemq.1.password = marionette

  # security plugin config
  securityprovider = psk
  plugin.psk = abcdefghj
{% endhighlight %}

You should also create _/etc/mcollective/server.cfg_ here's a sample, , a full reference of config settings can be found here [ConfigurationReference]:

{% highlight ini %}
  # main config
  libdir = /usr/libexec/mcollective
  logfile = /var/log/mcollective.log
  daemonize = 1
  loglevel = info

  # connector plugin config
  connector = activemq
  plugin.activemq.pool.size = 1
  plugin.activemq.1.host = stomp.example.net
  plugin.activemq.1.port = 61613
  plugin.activemq.1.user = mcollective
  plugin.activemq.1.password = marionette


  # facts
  factsource = yaml
  plugin.yaml = /etc/mcollective/facts.yaml

  # security plugin config
  securityprovider = psk
  plugin.psk = abcdefghj
{% endhighlight %}

Replace the *plugin.psk* in both these files with a Pre-Shared Key of your own.

### Create Facts
By default - and for this setup - we'll use a simple YAML file for a fact source, later on you can use Puppet Labs Facter or something else.

Create */etc/mcollective/facts.yaml* along these lines:

{% highlight yaml %}
  ---
  location: devel
  country: uk
{% endhighlight %}

### Start the Server

The packages include standard init script, just start the server:

{% highlight console %}
  # /etc/init.d/mcollective restart
{% endhighlight %}

You should see in the log file somethig like:

{% highlight console %}
  # tail /var/log/mcollective.log
  I, [2010-12-29T11:15:32.321744 #11479]  INFO -- : mcollectived:33 The Marionette Collective 1.1.0 started logging at info level
{% endhighlight %}

### Test connectivity

If all is fine and you see this log message you can test with the client code:

{% highlight console %}
% mco ping
your.domain.com                           time=74.41 ms

---- ping statistics ----
1 replies max: 74.41 min: 74.41 avg: 74.41
{% endhighlight %}

This sends out a simple 'hello' packet to all the machines, as we only installed one you should have just one reply.

If you install the _mcollective_ and _mcollective-common_ packages along wit the facts and server.cfg you should see more nodes show up here.

You can explore other aspects of your machines:

{% highlight console %}
% mco find --with-fact country=uk
your.domain.com
{% endhighlight %}

This searches all systems currently active for ones with a fact *country=uk*, it got the data from the yaml file you made earlier.

If you use confiuration management tools like puppet and the nodes are setup with classes with *classes.txt* in */var/lib/puppet* then you
can search for nodes with a specific class on them - the locations will configurable soon:

{% highlight console %}
% mco find --with-class common::linux
your.domain.com
{% endhighlight %}

The filter commands are important they will be the main tool you use to target only parts of your infrastructure with calls to agents.

See the *--help* option to the various *mco `*`* commands for available options.  You can now look at some of the available plugins and
play around, you might need to run the server process as root if you want to play with services etc.

### Plugins
We provide limited default plugins, you can look on our sister project [MCollective Plugins][Plugins] where you will
find various plugins to manage packages, services etc.

### Further Reading
From here you should look at the rest of the wiki pages some key pages are:

 * [Screencasts] - Get a hands-on look at what is possible
 * [Terminology]
 * [Introduction to Simple RPC][SimpleRPCIntroduction] - a simple to use framework for writing clients and agents
 * [ControllingTheDaemon] - Controlling a running daemon
 * [AESSecurityPlugin] - Using AES+RSA for secure message encryption and authentication of clients
 * [SSLSecurityPlugin] - Using SSL for secure message signing and authentication of clients
