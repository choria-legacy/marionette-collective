---
title: "MCollective » Deployment » Middleware » ActiveMQ"
subtitle: "Configuring ActiveMQ for Use With MCollective"
layout: default
---


ActiveMQ is the primary recommended middleware for use with MCollective.

ActiveMQ is configured with a large XML file. This configuration involves a large number of settings that MCollective depends on, and a large number of settings that MCollective is agnostic about. 

When configuring ActiveMQ for MCollective, you must first collect some information about what your MCollective site requires, then ensure that several settings are correctly set in the activemq.xml file. 

All of the settings MCollective relies on are located in activemq.xml's `<broker>` element. 

TODO Note that the file has to be owned by the activemq user and world-unreadable due to credentials. 

## Extra Features

It's easy to configure ActiveMQ to have no opinions about what kind of traffic is allowed. Most users will want to make it be a bit more discerning. 

If you want to use any of the additional features below, you will need to enable them in your ActiveMQ config. In some cases, you must change several settings.

* Use TLS to encrypt traffic
* Perform authorization (such that only admins can issue commands)
* Route MCollective traffic among a network of brokers
* Use subcollectives (either to enhance authorization or reduce inter-datacenter traffic)


## Required Data

The following things must be configured similarly in both ActiveMQ and MCollective. You should keep track of this data and use standard defaults where possible.

* The port for Stomp traffic (default: 61613 unencrypted, or 61614 encrypted)
* Usernames and passwords for anything that will be connecting to the server (generally this entails one account for the servers and at least one account for your admin users)
* If you are using TLS, ActiveMQ and MCollective must use certificates from the same CA.

## Basic Requirements



## Extra Requirements


MCollective's ActiveMQ needs to 





  $activemq_confdir = '/etc/activemq',
  $activemq_user = 'activemq',
  $brokername = 'mcollective-broker',
  
  
  $tls = true,
  $authentication = 'properties',
  $collectives = ['mcollective'],
  $users = [
    { 'name'     => 'mcollective',
      'password' => 'secret',
      'groups'   => ['servers']
    },
    { 'name'     => 'admin',
      'password' => 'secret',
      'groups'   => ['admins']
    }
  ],
  $keystore_password = 'UNSET',
  $ca = '/var/lib/puppet/ssl/certs/ca.pem', 
  $cert = 'UNSET', 
  $private_key = 'UNSET',
  $peers = [ ],

------------

This plugin requires version _1.2.2_ or newer of the Stomp gem. (Older versions don't properly support SSL. If you aren't securing traffic, you can use versions as old as 1.1.8, but no earlier.)


The ActiveMQ connector requires MCollective 2.0.0 or newer and introduce a new structure to the middleware messsages.

 * Replies goes direct to clients using short lived queues
 * Agent topics are called */topic/&lt;collective&gt;.&lt;agent_name&gt;.agent*
 * Support for point to point messages are added by using _/queue/&lt;collective&gt;.nodes_ and using JMS selectors.

The use of short lived queues mean that replies are now going to go back only to the person who sent the request.
This has big impact on overall CPU usage by clients on busy networks but also optimize the traffic flow on
networks with many brokers.

Point to Point messages means each node has a unique subscription, the approach using JMS Selectors means
internally to ActiveMQ only a single thread will be dedicated to this rather than 1 per connected node.


ActiveMQ 5.5.0 and later.

### broker name

TODO ???????????

> * *The _brokerName_ attribute is important and should be unique.* (Leaving it set to localhost will cause message loops to occur)

from the clusters guide.

### Transport connectors

ActiveMQ must listen for stomp connections. Easiest to use the default stomp port of 61613 or the default stomp+tls port of 61614.

        <transportConnectors>
            <transportConnector name="stomp+nio" uri="stomp+nio://0.0.0.0:61613"/>
            <transportConnector name="openwire" uri="tcp://0.0.0.0:61616"/>
        </transportConnectors>

You can also have an openwire transport connector if you expect to have a network of brokers or are using other services with the same ActiveMQ broker. 

If you're using TLS, you need to configure this in the transport connectors. 

Best practice: Turn off transport connectors you don't need. If you're doing TLS for stomp connections, don't leave a bare stomp transport open. 

{% highlight xml %}
<transportConnectors>
            <transportConnector name="stomp+ssl" uri="stomp+ssl://0.0.0.0:61614?needClientAuth=true"/>
            <transportConnector name="openwire+ssl" uri="ssl://0.0.0.0:61617?needClientAuth=true"/>
</transportConnectors>
{% endhighlight %}


### Remove unused queues
We use uniquely named queues for replies.  As queues will live forever we need to get ActiveMQ to remove
queues we are done with else they will just add up and grow forever.

{% highlight xml %}
<destinationPolicy>
  <policyMap>
    <policyEntries>
      <policyEntry queue="*.reply.>" gcInactiveDestinations="true" inactiveTimoutBeforeGC="300000" />
    </policyEntries>
  </policyMap>
</destinationPolicy>
{% endhighlight %}

The above policy will instruct ActiveMQ to remove dead queues after 5 minutes.



### Network connectors

If you are using a network of brokers, you need to configure which brokers can talk to each other. On _one_ node in each pair that can communicate, you need to set up two bi-directional network connectiors, one for topics and one for queues. 

Topology can vary wildly. Look at the [activemq network of brokers docs][activemq_network_of_brokers] for more info.

{% highlight xml %}
<networkConnectors>
  <networkConnector
        name="stomp1-stomp2-topics"
        uri="static:(tcp://stomp2.xx.net:6166)"
        userName="amq"
        password="secret"
        duplex="true"
        decreaseNetworkConsumerPriority="true"
        networkTTL="2"
        dynamicOnly="true">
        <excludedDestinations>
                <queue physicalName=">" />
        </excludedDestinations>
  </networkConnector>
  <networkConnector
        name="stomp1-stomp2-queues"
        uri="static:(tcp://stomp2.xx.net:6166)"
        userName="amq"
        password="secret"
        duplex="true"
        decreaseNetworkConsumerPriority="true"
        networkTTL="2"
        dynamicOnly="true"
        conduitSubscriptions="false">
        <excludedDestinations>
                <topic physicalName=">" />
        </excludedDestinations>
  </networkConnector>
</networkConnectors>
{% endhighlight %}

You will need to adjust the TTL for your network.  Note the queue connection has a different
_conduitSubscriptions_ policy than the topic one, you have to create these different connections
and set this policy for everything to work correctly.

* The _name_ on each connector should be unique, I just list the pair of hostnames involved which should be unique.
* This is a bi-directional connection it can send and receive traffic, you can make uni directional connections too if you wanted
* We're authenticating with a username and password
* The user used for inter-broker communication must be able to read/write/admin any topic or queue that might be used in mcollective traffic. 
* You can use the excluded destinations to prevent certain traffic from leaving a datacenter. This is mostly useful for traffic reduction. in the excluded destinations element, put something like:
     <excludedDestinations>
        <topic physicalName="us_collective.>" />
        <queue physicalName="us_collective.>" />
     </excludedDestinations>
    ...to keep that traffic from being passed on.

TODO, nick doesn't understand this and couldn't get it to work, which probs has something to do w/ the connectors being duplex. 
    yeah that's exactly what it was, woo. as long as you aren't routing around the restriction it works as expected. 
    So if you have the network connector on the edges of the star, they need to restrict passing on their own collective's traffic...? that doesn't seem right. that would mean the NOC can't issue commands to that collective. so it's more like, it needs to know about and include....
        OH, no, I see how it is, you have to use dynamicallyIncludedDestinations if you're trying to filter traffic from the edges. That way they state the collectives they DO care about, and exclude everything else. 
        Yup, that's exactly how it works. woooooot.
    If the network connector is in the center of the star, it needs to restrict passing on any collectives that the destination of that connector doesn't care about. That seems easier. 


There are some relevant docs on the ActiveMQ Wiki:

 * [Network of Brokers][NetworksOfBrokers]
 * [Using SSL for transport security][UsingSSL]

[NetworksOfBrokers]: http://activemq.apache.org/networks-of-brokers.html
[UsingSSL]: http://activemq.apache.org/how-do-i-use-ssl.html




### persistence

         <persistenceAdapter>
             <kahaDB directory="${activemq.base}/data/kahadb"/>
         </persistenceAdapter>

If you want long-lived direct addressing, you need persistence configured. 

TODO nick doesn't really understand this.
 
### TLS

You must configure ActiveMQ to use a keystore containing its own certificate and private key, and a truststore containing the site's CA certificate (usually the Puppet CA). 

> [See here for instructions for creating the keystore and truststore.][activemq_keystores]

{% highlight xml %}
<sslContext>
   <sslContext
   	keyStore="keystore.jks" keyStorePassword="secret"
   	trustStore="truststore.jks" trustStorePassword="secret"
   />
</sslContext>
{% endhighlight %}

And we need to tell ActiveMQ to only accept fully verified connections:

{% highlight xml %}
<transportConnectors>
            <transportConnector name="stomp+ssl" uri="stomp+ssl://0.0.0.0:61614?needClientAuth=true"/>
            <transportConnector name="openwire+ssl" uri="ssl://0.0.0.0:61617?needClientAuth=true"/>
</transportConnectors>
{% endhighlight %}


### Producer flow control

TODO ????????????????


### User accounts and permissions. 

MCollective servers and admin users need to ID themselves to the ActiveMQ broker. The way this works is:

- The server or user presents a username and password when they connect to ActiveMQ.
- ActiveMQ associates any number of group names with that username.
- ActiveMQ's authorization plugin allows certain groups to read, write, and create certain topics and queues. 

This happens in the <plugins> element of the broker. Authentication happens in one of several plugins, and authorization happens in the <authorizationPlugin> element. 

You have several options for making users; the two main ones are simple authentication (store names, groups, and passwords in the XML file) and properties file authentication (store names, groups, and passwords outside the XML file, dosn't require a restart to add new users). Simple authentication is shown below.

        <plugins>
          <statisticsBrokerPlugin/>
          <simpleAuthenticationPlugin>
            <users>
              <authenticationUser username="mcollective" password="marionette" groups="mcollective,everyone"/>
              <authenticationUser username="admin" password="secret" groups="mcollective,admin,everyone"/>
            </users>
          </simpleAuthenticationPlugin>
          

The easiest and least secure approach is to leave off both authentication and authorization; activemq defaults to assuming it's in a trusted environment and allowing everything. This allows any mcollective server or user to connect with ANY username and password and issue any command or reply. Don't do that. 

The next easiest approach is to have one user for both servers and clients, and allow that user to read/write/amdin on any topic or queue beginning with the name of the collective. (MCollective's default collective name is `mcollective`. Subcollectives are implemented by just changing that first segment of the topic/queue name, so if you use subcollectives your users must also be able to read/write/admin to topics and queues starting with each subcollective name.)

A more nuanced approach is to use two levels of authorization, admin users and servers; servers able to receive and respond to commands, and admin users able to issue them. 

A detailed approach is to use subcollectives to further restrict adimn users to certain groups of machines. 

The full access requirements for standard mcollective usage are:

- Everyone must be able to read/write/admin the following:
    - ActiveMQ.Advisory.>
- Servers must be able to read and admin the following:
    - queue COLLECTIVE.nodes.>
    - topic COLLECTIVE.*.agent
- Servers must be able to write and admin the following:
    - queue COLLECTIVE.reply.>
    - topic COLLECTIVE.registration.agent, if you're using registration
- Admin users must be able to read/write/admin the following:
    - topic COLLECTIVE.>
    - queue COLLECTIVE.>

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

---

                  <authorizationEntry queue="<%= collective %>.>" write="admins,<%= collective %>-admins" read="admins,<%= collective %>-admins" admin="admins,<%= collective %>-admins" />
                  <authorizationEntry topic="<%= collective %>.>" write="admins,<%= collective %>-admins" read="admins,<%= collective %>-admins" admin="admins,<%= collective %>-admins" />
                  <authorizationEntry queue="<%= collective %>.nodes.>" read="servers,<%= collective %>-servers" admin="servers,<%= collective %>-servers" />
                  <authorizationEntry queue="<%= collective %>.reply.>" write="servers,<%= collective %>-servers" admin="servers,<%= collective %>-servers" />
                  <authorizationEntry topic="<%= collective %>.*.agent" read="servers,<%= collective %>-servers" admin="servers,<%= collective %>-servers" />
                  <authorizationEntry topic="<%= collective %>.registration.agent" write="servers,<%= collective %>-servers" read="servers,<%= collective %>-servers" admin="servers,<%= collective %>-servers" />

General information about [ActiveMQ Security can be found on their wiki][Security].
[Security]: http://activemq.apache.org/security.html
The default format for message topics is compatible with [ActiveMQ wildcard patterns][Wildcard] and so we can now do fine grained controls over who can speak to what.
[Wildcard]: http://activemq.apache.org/wildcards.html
