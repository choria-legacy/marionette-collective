---
title: "MCollective » Deployment » Middleware » ActiveMQ"
subtitle: "Configuring ActiveMQ for Use With MCollective"
layout: default
---

[activemq_connector]: /reference/plugins/connector_activemq.html
[stomp_connector]: /reference/plugins/connector_stomp.html
[subcollectives]: /reference/basic/subcollectives.html
[minimal_example]: TODO
[maximal_example]: TODO
[template_example]: TODO
[apache_activemq_config_docs]: http://activemq.apache.org/version-5-xml-configuration.html
[mcollective_connector_tls]: TODO


Apache ActiveMQ is the main middleware we recommend with MCollective. It's good software, but is configured with a very large and unwieldy XML file, and depending on what you need from your MCollective deployment, you may need to edit many many sections of that file. This reference attempts to describe all of the major ActiveMQ settings that MCollective is likely to care about. 

> **Note:** Some config data needs to be set in both MCollective and ActiveMQ; your configuration of one will affect the other. In this page, we call out that information with headers labeled "Shared Configuration."

Version Limits
-----

This document is about the "new" MCollective/ActiveMQ interface, which means it requires the following:

* MCollective 2.0.0 or newer
* ActiveMQ 5.5.0 or newer
* Stomp gem 1.2.2 or newer (or 1.1.8 and newer if you will never use TLS)
* The [activemq connector][activemq_connector] plugin

Older combinations of software can use the deprecated generic [stomp connector][stomp_connector] plugin, but this document does not cover that. 


How MCollective Uses ActiveMQ
-----

MCollective connects to ActiveMQ over the Stomp protocol, and presents certain credentials:

* It provides a username and password, with which ActiveMQ can do what it pleases. 
* If TLS is in use, it will also present a certificate (and verify the ActiveMQ server's certificate).

Once allowed to connect, MCollective will use several built-in topics (whose names begin with `ActiveMQ.Advisory`) to create subscriptions. It will then produce and consume a lot of traffic on queues and topics whose names begin with `mcollective`. (See "Topic and Queue Names" directly below.)

### Absolute Minimum Requirements

ActiveMQ defaults to believing that it is routing traffic between processes in a single JVM instance: it doesn't assume it is connected to the network, and it uses a loose-to-nonexistent security model.

This means that if you do nothing but enable Stomp traffic, MCollective will work fine. (Albeit with terrible security and eventual out-of-control memory usage.)

### Topic and Queue Names

MCollective uses the following destination names. This list uses standard [ActiveMQ destination wildcards][wildcard]. "COLLECTIVE" is the name of the collective being used; by default, this is `mcollective`, but if you are using [subcollectives][], each one is implemented as an equal peer of the default collective.

Topics: 

- `ActiveMQ.Advisory.>` (a built-in ActiveMQ facility for creating subscriptions)
- `COLLECTIVE.*.agent` (for each agent plugin, where the `*` is the name of the plugin)

Queues:

- `COLLECTIVE.nodes` (used for direct addressing; this is a single destination that uses JMS selectors, rather than a group of destinations)
- `COLLECTIVE.reply.>` (where the continued portion is a request ID)

TODO make sure this is accurate.

> #### Shared Configuration
> 
> Subcollectives must also be configured in the MCollective client and server config files. ActiveMQ must allow traffic on any subcollective that MCollective servers and clients expect to use.

> ### A Note on Tuning
> 
> Don't tune until you need to. You generally don't need to until you have more than 800 MCollective nodes connected to a single ActiveMQ server.


The ActiveMQ Config File
-----

ActiveMQ's config is usually called activemq.xml, and is kept in ActiveMQ's configuration directory; other files it refers to will generally be looked for in that directory. Note that all of the settings relevant to MCollective are located inside activemq.xml's `<broker>` element. 

This document won't describe the complete format of the activemq.xml config file, and will sometimes use incomplete shorthand to describe elements of it. You should definitely refer to an example config file while reading, so you can see each element in context.

You can also read external documentation for a more complete understanding.

> **Bug Warning:** In ActiveMQ 5.5, the first-level children of the `<broker>` element must be arranged in alphabetical order. There is no good reason for this behavior, and it was fixed in ActiveMQ 5.6.

### Example Config Files

We have several. 

* [Minimal config example][minimal_example] --- single broker, minimal authorization.
* [Maximal config example][maximal_example] --- multi-broker with extensive authorization config.
* [Template-based example][template_example] --- reduces configuration down to a handful of variables; shows how those few decisions ramify into many config edits.

### External ActiveMQ Documentation

The Apache ActiveMQ documentation makes a good effort, but large parts of it are quite poor, it is badly organized, and there are many broken links. The Fuse documentation (a commercially supported release of ActiveMQ) is significantly better written and better organised, although it requires signing up for an email newsletter.

* [Apache ActiveMQ Documentation][apache_activemq_config_docs]
* [Fuse Documentation](http://fusesource.com/documentation/fuse-message-broker-documentation/)

### Wildcards

You'll see a lot of [ActiveMQ destination wildcards][wildcard] below. In short:

* Segments in a destination name are separated with dots (`.`)
* A `*` represents _one segment_ (i.e. any sequence of non-dot characters)
* A `>` represents _the whole rest of the name_ after a prefix

[Wildcard]: http://activemq.apache.org/wildcards.html

Required Settings
-----

One way or another, you must set all of the following.

### Transport Connector(s)

ActiveMQ must listen over the network for Stomp connections; otherwise, MCollective can't reach it. Enable this with a `<transportConnector>` element inside the `<transportConnectors>` element. 

{% highlight xml %}
    <transportConnectors>
      <transportConnector name="stomp+nio" uri="stomp+nio://0.0.0.0:61613"/>
    </transportConnectors>
{% endhighlight %}

* The `name` attribute doesn't seem to matter as long as it's locally unique.
* For unencrypted Stomp, use a URI of `stomp+nio://0.0.0.0:61613`.
* For Stomp over TLS, use a URI of `stomp+ssl://0.0.0.0:61614?needClientAuth=true`.
* You can also restrict the interface/hostname to use instead of listening on `0.0.0.0`.

> **If you are using TLS,** note that you must also:
> 
> * [Configure ActiveMQ's TLS credentials](#tls-credentials) (see below)
> * [Configure MCollective to use TLS credentials][mcollective_connector_tls]

If you are using a network of brokers instead of just one ActiveMQ server, they talk to each other over OpenWire, and will all need a transport connector for that protocol too:

{% highlight xml %}
    <transportConnector name="openwire+ssl" uri="ssl://0.0.0.0:61617?needClientAuth=true"/>
{% endhighlight %}

* For unencrypted OpenWire, use a URI of `tcp://0.0.0.0:61616`.
* For OpenWire over TLS, use a URI of `ssl://0.0.0.0:61617?needClientAuth=true`.

It's generally best to only enable the transport connectors you need. If you're using Stomp over TLS, don't leave a bare Stomp transport open.

> #### Shared Configuration
> 
> MCollective needs to know the following:
> 
> * The port to use for Stomp traffic
> * The hostname or IP address to reach ActiveMQ at
> * Whether to use TLS
> 
> In a network of brokers, the other ActiveMQ servers need to know the following:
> 
> * The port to use for OpenWire traffic
> * The hostname or IP address to reach peer ActiveMQ servers at
> * Whether to use TLS


#### Standard Ports for Stomp and OpenWire

Alas, there aren't any; just a rough consensus.

* 61613 for unencrypted Stomp
* 61614 for Stomp with TLS
* 61616 for unencrypted OpenWire
* 61617 for OpenWire with TLS

All of our documentation assumes these ports.


* * * 

### Reply Queue Pruning

MCollective sends replies on uniquely-named single-use queues with names like `mcollective.reply.<UNIQUE ID>`. These have to be deleted after about five minutes, lest they clog up ActiveMQ's available memory. By default, queues live forever, so you have to configure this.

Use a `<policyEntry>` element for `*.reply.>` queues, with `gcInactiveDestinations` set to true and `inactiveTimoutBeforeGC` set to 300000 ms (five minutes).

{% highlight xml %}
    <destinationPolicy>
      <policyMap>
        <policyEntries>
          <policyEntry queue="*.reply.>" gcInactiveDestinations="true" inactiveTimoutBeforeGC="300000" />
        </policyEntries>
      </policyMap>
    </destinationPolicy>
{% endhighlight %}

* * * 


Recommended Settings
-----

We recommend configuring the following, as ActiveMQ and MCollective aren't particularly secure without them.

### TLS Credentials

If you are using TLS in either your Stomp or OpenWire [transport connectors](#transport-connectors), ActiveMQ needs a keystore file, a truststore file, and a password for each:

{% highlight xml %}
    <sslContext>
      <sslContext
         keyStore="keystore.jks" keyStorePassword="secret"
         trustStore="truststore.jks" trustStorePassword="secret"
      />
    </sslContext>
{% endhighlight %}

The redundant nested `<sslContext>` elements are not a typo; for some reason ActiveMQ actually needs this.

ActiveMQ will expect to find these files in the same directory as activemq.xml.

> #### Creating a Keystore and Truststore
> 
> There is a [separate guide that covers how to create keystores.][activemq_keystores]

[activemq_keystores]: ./activemq_keystores.html

* * *

### Authentication (Users and Groups)

When they connect, MCollective clients and servers provide a username, password, and optionally an SSL certificate. ActiveMQ can use any of these to authenticate them. 

By default, ActiveMQ ignores all of these and has no particular concept of "users." Enabling authentication means ActiveMQ will only allow users with proper credentials to connect. It also gives you the option of setting up per-destination authorization (see below). 

You set up authentication by adding the appropriate element to the `<plugins>` element. [The Fuse documentation has a more complete description of ActiveMQ's authentication capabilities;][fuse_security] the [ActiveMQ docs version][activemq_security] is somewhat less organized. In summary:

- `simpleAuthenticationPlugin` defines users directly in activemq.xml. It's well-tested and easy. It also requires you to edit activemq.xml and restart the broker every time you add a new user. Using this means activemq.xml contains sensitive passwords, and must be protected.
- `jaasAuthenticationPlugin` lets you use external text files (or even an LDAP database) to define users and groups. You need to make a `login.config` file in the ActiveMQ config directory, and possibly several other files, so that's more complicated. But you can add users and groups without restarting. The external users file contains sensitive passwords and must be protected, but you're probably using TLS anyway and should therefore protect activemq.xml as well. 
- `jaasCertificateAuthenticationPlugin` ignores the username and password that MCollective presents; instead, it reads the distinguished name of the certificate and maps that to a username. It requires TLS, a `login.config` file, and two other external files. It is also impractical unless your servers are all using the same SSL certificate to connect to ActiveMQ; the currently recommended approach of re-using Puppet certificates makes this problematic, but you can probably ship credentials around and figure out a way to make it work. This is not currently well-tested with MCollective.

[fuse_security]: http://fusesource.com/docs/broker/5.5/security/front.html
[activemq_security]: http://activemq.apache.org/security.html

The example below uses `simpleAuthenticationPlugin`.

{% highlight xml %}
    <plugins>
      <simpleAuthenticationPlugin>
        <users>
          <authenticationUser username="mcollective" password="marionette" groups="mcollective,everyone"/>
          <authenticationUser username="admin" password="secret" groups="mcollective,admins,everyone"/>
        </users>
      </simpleAuthenticationPlugin>
      <!-- ... authorization goes below... -->
    </plugins>
{% endhighlight %}

This creates two users, with the expectation that MCollective servers will log in as `mcollective` and admin users issuing commands will log in as `admin`. 

Note that unless you set up authorization (see below), these users have the exact same capabilities. 

> #### Shared Configuration
> 
> MCollective servers and clients both need a username and password to use when connecting. That user **must** have appropriate permissions (see "Authorization," directly below) for that server or client's role. 


* * * 

### Authorization (Group Permissions)

By default, ActiveMQ allows everyone to **read** from any topic or queue, **write** to any topic or queue, and create (**admin**) any topic or queue. 

By setting rules in an `<authorizationPlugin>` element, you can regulate things a bit. Some notes:

* Authorization is done **by group.**
* The exact behavior of authorization doesn't seem to be documented. Going by observation, it appears that ActiveMQ first tries the most specific rule available, then retreats to less specific rules. This means if a given group is denied an action by a more specific rule but allowed it by a more general rule, it still gets authorized to take that action. TODO nail this down a bit?
* MCollective creates subscriptions before it knows whether there will be any content coming. That means any role able to **read** from or **write** to a destination must also be able to **admin** that destination. Think of "admin" as a superset of both read and write.

#### Simple Restrictions

The following example grants all permissions on destinations beginning with `mcollective` to everyone in group `mcollective`:

{% highlight xml %}
    <plugins>
      <!-- ...authentication stuff... -->
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
{% endhighlight %}

This means admins can issue commands and MCollective servers can read those commands and reply. However, it also means that servers can issue commands, which you probably don't want.

Note that the `everyone` group (as seen in the `ActiveMQ.Advisory.>` topics) **isn't special.** You need to manually make sure all users are members of it. ActiveMQ does not appear to have any kind of real wildcard "everyone" group, unfortunately.

#### Detailed Restrictions

The following example splits permissions along a simple user/server model:

{% highlight xml %}
    <plugins>
      <!-- ...authentication stuff... -->
      <authorizationPlugin>
        <map>
          <authorizationMap>
            <authorizationEntries>
              <authorizationEntry queue=">" write="admins" read="admins" admin="admins" />
              <authorizationEntry topic=">" write="admins" read="admins" admin="admins" />
              <authorizationEntry queue="mcollective.>" write="admins" read="admins" admin="admins" />
              <authorizationEntry topic="mcollective.>" write="admins" read="admins" admin="admins" />
              <authorizationEntry queue="mcollective.nodes" read="mcollective" admin="mcollective" />
              <authorizationEntry queue="mcollective.reply.>" write="mcollective" admin="mcollective" />
              <authorizationEntry topic="mcollective.*.agent" read="mcollective" admin="mcollective" />
              <authorizationEntry topic="mcollective.registration.agent" write="mcollective" read="mcollective" admin="mcollective" />
              <authorizationEntry topic="ActiveMQ.Advisory.>" read="everyone" write="everyone" admin="everyone"/>
            </authorizationEntries>
          </authorizationMap>
        </map>
      </authorizationPlugin>
    </plugins>
{% endhighlight %}

This means admins can issue commands and MCollective servers can read those commands and reply. This time, though, servers can't issue commands. The exception is the `mcollective.registration.agent` destination, which servers DO need the ability to write to if you've turned on registration. 

Admins, of course, can also read commands and reply, since they have power over the entire `mcollective.>` destination set. This isn't considered much of an additional security risk, considering that admins can already control your entire infrastructure.

#### Detailed Restrictions with Multiple Subcollectives

Both of the above examples assume only a single `mcollective` collective. If you are using additional [subcollectives][] (e.g. `uk-collective`, `us-collective`, etc.), their destinations will start with their name instead of `mcollective`. If you need to separately control authorization for each collective, it's best to use a template to do so, so you can avoid repeating yourself. 

{% highlight xml %}
    <plugins>
      <!-- ...authentication stuff... -->
      <authorizationPlugin>
        <map>
          <authorizationMap>
            <authorizationEntries>
              <!-- "admins" group can do anything. -->
              <authorizationEntry queue=">" write="admins" read="admins" admin="admins" />
              <authorizationEntry topic=">" write="admins" read="admins" admin="admins" />

              <%- @collectives.each do |collective| -%>
              <authorizationEntry queue="<%= collective %>.>" write="admins,<%= collective %>-admins" read="admins,<%= collective %>-admins" admin="admins,<%= collective %>-admins" />
              <authorizationEntry topic="<%= collective %>.>" write="admins,<%= collective %>-admins" read="admins,<%= collective %>-admins" admin="admins,<%= collective %>-admins" />
              <authorizationEntry queue="<%= collective %>.nodes" read="servers,<%= collective %>-servers" admin="servers,<%= collective %>-servers" />
              <authorizationEntry queue="<%= collective %>.reply.>" write="servers,<%= collective %>-servers" admin="servers,<%= collective %>-servers" />
              <authorizationEntry topic="<%= collective %>.*.agent" read="servers,<%= collective %>-servers" admin="servers,<%= collective %>-servers" />
              <authorizationEntry topic="<%= collective %>.registration.agent" write="servers,<%= collective %>-servers" read="servers,<%= collective %>-servers" admin="servers,<%= collective %>-servers" />
              <%- end -%>

              <authorizationEntry topic="ActiveMQ.Advisory.>" read="everyone" write="everyone" admin="everyone"/>
            </authorizationEntries>
          </authorizationMap>
        </map>
      </authorizationPlugin>
    </plugins>
{% endhighlight %}

This example divides your users into several groups:

* `admins` is the "super-admins" group, who can command all servers (and write messages to bizarre unknown topics, although you probably don't care about that since no one's listening).
* `servers` is the "super-servers" group, who can read and respond to commands on any collective they happen to be listening to.
* `COLLECTIVE-admins` can only command servers on their specific collective. (So `mcollective-admins` is the "sub-super-admins" group: they can command the default collective that all servers are _probably_ subscribed to, but can't just spray messages everywhere the way `admins` can.)
* `COLLECTIVE-servers` can only read and respond to commands on their specific collective.

Thus, when you define your users in the [authentication setup](#authentication-users-and-groups), you could allow a certain user to command both the EU and UK collectives (but not the US collective) with `groups="eu-collective-admins,uk-collective-admins"`. You would probably want most servers to be "super-servers," since each server already gets to choose which collectives to ignore.

#### MCollective's Exact Authorization Requirements

As described above, any user able to read OR write on a destination must also be able to admin that destination. 

Topics: 

- `ActiveMQ.Advisory.>` --- Everyone must be able to read and write. 
- `COLLECTIVE.*.agent` --- Admin users must be able to write. Servers must be able to read. 
- `COLLECTIVE.registration.agent` --- If you're using registration, servers must be able to read and write. Otherwise, it can be ignored.

Queues:

- `COLLECTIVE.nodes` --- Admin users must be able to write. Servers must be able to read.
- `COLLECTIVE.reply.>` --- Servers must be able to write. Admin users must be able to read.


> #### Shared Configuration
> 
> Subcollectives must also be configured in the MCollective client and server config files. If you're setting up authorization per-subcollective, ActiveMQ must allow traffic on any subcollective that MCollective servers and clients expect to use.


* * *

Settings for Networks of Brokers
-----

You can group multiple ActiveMQ servers into networks of brokers, and they can route local MCollective traffic amongst themselves. This can give you better performance for local traffic, and can let you isolate your networks by preventing certain users from sending requests to certain datacenters.

This is advanced stuff for very very large deployments. 

Designing your broker network's topology is beyond the scope of this documentation. See [the ActiveMQ docs][NetworksOfBrokers] or [the Fuse docs][fuse_cluster] for more info. For our purposes, we assume you have already decided:

* Which ActiveMQ brokers can communicate with which.
* What kinds of traffic should be excluded from other brokers.

[NetworksOfBrokers]: http://activemq.apache.org/networks-of-brokers.html
[fuse_cluster]: http://fusesource.com/docs/broker/5.5/clustering/index.html

### Network Connectors

If you are using a network of brokers, you need to configure which brokers can talk to each other. 

The simplest way to do this is to --- on **one** broker in each pair that should be linked --- set up **two** bi-directional network connectors: one for topics, and one for queues. (The only difference between the two connectors is the `conduitSubscriptions` policy. This is necessary due to the way MCollective uses queues for replies and direct addressing.) (TODO Nick doesn't really understand that last bit.)  

This is done with a pair of `<networkConnector>` elements inside the `<networkConnectors>` element. Note that the queues connector excludes topics and vice-versa.

{% highlight xml %}
    <networkConnectors>
      <networkConnector
        name="stomp1-stomp2-topics"
        uri="static:(tcp://stomp2.example.com:61616)"
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
        uri="static:(tcp://stomp2.example.com:61616)"
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

Notes: 

* Both brokers involved need to have [OpenWire transports enabled](#transport-connectors). (TODO is it both or just one?) If you're using TLS for OpenWire, you'll need to change the URIs to `static:(ssl://stomp2.example.com:61617)` (note the change of both protocol and port). 
* You will need to adjust the TTL for your network's conditions.
* The connecting broker authenticates to the other with a username and password. This user must be able to read/write/admin on all of the destinations it will be passing along messages to; see [authentication](#authentication-users-and-groups) and [authorization](#authorization-group-permissions) above. (TODO Nick isn't actually sure about that.)
* The _name_ on each connector should be globally unique. Easiest way to do that is to combine the pair of hostnames involved in the connection and whether the connection is for queues or topics.
* Alternately, you can set up two uni-directional connectors on both brokers; see the Fuse or ActiveMQ documentation linked above for more details. 

* * *

### Destination Filtering

[fuse_filtering]: http://fusesource.com/docs/broker/5.5/clustering/Networks-Filtering.html

Relevant external docs:

* [Fuse filtering guide][fuse_filtering]

If you want to prevent certain traffic from leaving a given datacenter, you can do so with `<excludedDestinations>` or `<dynamicallyIncludedDestinations>` elements **inside each `<networkConnector>` element.** This is mostly useful for noise reduction, by blocking traffic that other datacenters don't care about, but it can also serve security purposes. Generally, you'll be filtering on [subcollectives][], which, as described above, begin their destination names with the name of the collective.

Both types of filter element can contain `<queue>` and `<topic>` elements, with ther `physicalName` attributes defining a destination name with the normal wildcards.

#### Examples

Assume a star network topology. 

This topology can be achieved by either having each edge broker connect to the central broker, or having the central broker connect to each edge broker. You can achieve the same filtering in both situations, but with slightly different configuration. The two examples below have similar but not identical effects; the ramifications are subtle, and we _really_ recommend reading the external ActiveMQ and Fuse documentation if you've come this far in your deployment scale.

If your central broker is connecting to the UK broker, and you want it to only pass on traffic for the global `mcollective` collective and the UK-specific `uk-collective` collective:

{% highlight xml %}
    <dynamicallyIncludedDestinations>
      <topic physicalName="mcollective.>" />
      <queue physicalName="mcollective.>" />
      <topic physicalName="uk-collective.>" />
      <queue physicalName="uk-collective.>" />
    </dynamicallyIncludedDestinations>
{% endhighlight %}

In this case, admin users connected to the central broker can command nodes on the `uk-collective`, but admin users connected to the UK broker can't command nodes on the `us-collective`, etc. 

Alternately, if your UK broker is connecting to your central broker and you want it to refrain from passing on UK-specific traffic that no one outside that datacenter cares about:

{% highlight xml %}
    <excludedDestinations>
       <topic physicalName="uk-collective.>" />
       <queue physicalName="uk-collective.>" />
    </excludedDestinations>
{% endhighlight %}

In this case, admin users connected to the central broker **cannot** command nodes on the `uk-collective`; it's expected that they'll be issuing commands to the main `mcollective` collective if they need to (and are authorized to) cross outside their borders. 

TODO Nick needs an adult, and is unsure about MUCH of that.

* * * 

Tuning Boilerplate
-----

There's no reason to care about these settings until your deployment is extremely large and heavily trafficked.

### Persistence

Just make sure kahaDB persistence is enabled and pointing to a valid directory. Most users don't even need this, but it enables long-lived direct addressing and doesn't hurt anything. 

TODO Nick doesn't really understand this.

{% highlight xml %}
    <persistenceAdapter>
        <kahaDB directory="${activemq.base}/data/kahadb"/>
    </persistenceAdapter>
{% endhighlight %}
 
### Producer Flow Control

Turn it off for topics unless you really know what you're doing. Here it's shown alongside [the reply-pruning rule from "required settings"](#reply-queue-pruning):

TODO Nick doesn't really understand this.


{% highlight xml %}
    <destinationPolicy>
        <policyMap>
          <policyEntries>
            <policyEntry topic=">" producerFlowControl="false"/>
            <policyEntry queue="*.reply.>" gcInactiveDestinations="true" inactiveTimoutBeforeGC="300000" />
          </policyEntries>
        </policyMap>
    </destinationPolicy> 
{% endhighlight %}


### Broker Name

The `<broker>` element needs a `brokerName` attribute. It seems like this needs to be something other than `localhost` if you're using a network of brokers (TODO from the old clusters guide: **The _brokerName_ attribute is important and should be unique.** (Leaving it set to localhost will cause message loops to occur)) , but it doesn't appear to need to be globally unique? Experimentation with two identically-named brokers hasn't turned up any problems, so we don't really know what's up with that. 

TODO Nick doesn't really understand this.

{% highlight xml %}
    <broker xmlns="http://activemq.apache.org/schema/core" brokerName="mcollective-broker" dataDirectory="${activemq.base}/data" destroyApplicationContextOnStop="true">
{% endhighlight %}

