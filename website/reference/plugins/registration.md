---
layout: mcollective
title: Registration
disqus: true
---
[RegistrationMonitor]: http://code.google.com/p/mcollective-plugins/wiki/AgentRegistrationMonitor

## {{page.title}}

We support the ability for each node to register with a central inventory, we don't use the inventory 
internally for anything it's there as a framework to enable you to build inventory systems or WebUI's.

### Details

Registration plugins are easy to write and you can configure your nodes to use your own or the provided one.  
All Registration plugins must inherit from *MCollective::Registration::Base* to ensure they get loaded into 
the plugin system.

The one we provide simply sends a list of agents to the inventory, it is called *agentlist* and can be seen 
in its entirety below:

{% highlight ruby %}
module MCollective
    module Registration
        # A registration plugin that simply sends in the list of agents we have
        class Agentlist<Base
            def body
                MCollective::Agents.agentlist
            end
        end
    end
end
{% endhighlight %}

You can see it's very simple, you just need to provide a _body_ method and it's return value will be sent 
to the registration agent(s)

To configure it to be used you just need the following in your config:

{% highlight ini %}
registerinterval = 300
registration = Agentlist
{% endhighlight %}

This will cause the plugin to be called every 300 seconds.

We do not provide the receiving end of this in the core mcollective, you only need to write an agent called 
*registration* and do whatever you want with the data you receive from all the nodes.  You can find 
[a simple monitoring system][RegistrationMonitor] built using this method at mcollective-plugins as an example.

You need to note a few things about these agents:

 * They need to be fast, you'll receive a lot of registration messages if your agent will talk to a database that 
   is slow you'll run into problems
 * They should not return anything other than *nil*, the mcollective server will interpret *nil* from an agent as 
   an indication that you do not want to send back any reply.  Replying to registration requests is almost always undesired.

There's nothing preventing you from running more than one type of receiving agent in your collective, you can have one 
on your monitor server as above and another with completely different code on a web server feeding a local cache 
for your web interfaces.  As long as both agents are called *registration* you'll be fine, this means though you can't 
run more than one type on the same server.
