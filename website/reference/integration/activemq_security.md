---
layout: default
title: ActiveMQ Security
toc: false
---
[Security]: http://activemq.apache.org/security.html
[Registration]: /mcollective/reference/plugins/registration.html
[Wildcard]: http://activemq.apache.org/wildcards.html
[ActiveMQ TLS]: activemq_ssl.html

As part of rolling out mcollective you need to think about security. The various examples in the quick start guide and on this blog has allowed all agents to talk to all nodes all agents. The problem with this approach is that should you have untrusted users on a node they can install the client applications and read the username/password from the server config file and thus control your entire architecture.

The default format for message topics is compatible with [ActiveMQ wildcard patterns][Wildcard] and so we can now do fine grained controls over who can speak to what.

General information about [ActiveMQ Security can be found on their wiki][Security].

The default message targets looks like this:

{% highlight console %}
    /topic/mcollective.agentname.command
    /topic/mcollective.agentname.reply
{% endhighlight %}

If you are using Subcollectives each subcollective will have topics like:

{% highlight console %}
    /topic/subcollective.agentname.command
    /topic/subcollective.agentname.reply
{% endhighlight %}

For a node to belong to a sub collective he also need rights to these topics.

The nodes only need read access to the command topics and only need write access to the reply topics. The examples below also give them admin access so these topics can be created dynamically. For simplicity we'll wildcard the agent names, you could go further and limit certain nodes to only run certain agents. Adding these controls effectively means anyone who gets onto your node will not be able to write to the command topics and so will not be able to send commands to the rest of the collective.

There's one special case and that's the registration topic, if you want to enable the [registration feature][Registration] you should give the nodes access to write on the command channel for the registration agent. Nothing should reply on the registration topic so you can limit that in the ActiveMQ config.

We'll let mcollective log in as the mcollective user, create a group called mcollectiveservers, we'll then give the mcollectiveservers group access to run as a typical registration enabled mcollective node.

The rip user is a mcollective admin and can create commands and receive replies.

First we'll create users and the groups.

{% highlight xml %}
    <simpleAuthenticationPlugin>
     <users>
      <authenticationUser username="mcollective" password="pI1SkjRi" groups="mcollectiveservers,everyone"/>
      <authenticationUser username="rip" password="foobarbaz" groups="admins,everyone"/>
     </users>
    </simpleAuthenticationPlugin>
{% endhighlight %}

Now we'll create the access rights:

{% highlight xml %}
    <authorizationPlugin>
      <map>
        <authorizationMap>
          <authorizationEntries>
            <authorizationEntry queue="mcollective.>" write="admins" read="admins" admin="admins" />
            <authorizationEntry topic="mcollective.>" write="admins" read="admins" admin="admins" />
            <authorizationEntry queue="mcollective.reply.>" write="mcollectiveservers" admin="mcollectiveservers" />
            <authorizationEntry queue="mcollective.nodes.>" read="mcollectiveservers" admin="mcollectiveservers" />
            <authorizationEntry topic="mcollective.*.agent" read="mcollectiveservers" admin="mcollectiveservers" />
            <authorizationEntry topic="mcollective.registration.agent" write="mcollectiveservers" read="mcollectiveservers" admin="mcollectiveservers" />
            <authorizationEntry topic="ActiveMQ.Advisory.>" read="everyone,all" write="everyone,all" admin="everyone,all"/>
          </authorizationEntries>
        </authorizationMap>
      </map>
    </authorizationPlugin>
{% endhighlight %}

Notes:

* These rights are meant for the current ActiveMQ connector plugin, which uses a different addressing structure from the older, deprecated generic Stomp plugin.
* You can also restrict read access to `mcollective.registration.command` to just the specific node that runs the registration agent, in order to ensure secrecy of your node registration. However, this requires that you create a separate ActiveMQ user and group for just that node.
* The same goes for restricting write access to specific commands: you can get as detailed as you want, but will pay a price of increased complexity. You may get more convenient results with a combination of the MCollective actionpolicy plugin and a security plugin (like the SSL one) that provides strong caller identification.

Finally the nodes need to be configured, the server.cfg should have the following at least:

{% highlight ini %}
    plugin.stomp.user = mcollective
    plugin.stomp.password = pI1SkjRi
    plugin.psk = aBieveenshedeineeceezaeheer
{% endhighlight %}

For my clients I can use the ability to configure the user details in my shell environment:

{% highlight bash %}
    export STOMP_USER=rip
    export STOMP_PASSWORD=foobarbaz
    export STOMP_SERVER=stomp1
    export MCOLLECTIVE_PSK=aBieveenshedeineeceezaeheer
{% endhighlight %}

And finally the rip user when logged into a shell with these variables have full access to the various commands. You can now give different users access to the entire collective or go further and give a certain admin user access to only run certain agents by limiting the command topics they have access to. Doing the user and password settings in shell environments means it's not kept in any config file in /etc/ for example.

Your next step should be to setup TLS between your nodes and your middleware, to set this up follow our [ActiveMQ TLS] quide.
