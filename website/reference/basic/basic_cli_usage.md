---
layout: default
title: Using MCollective Command Line Applications
---
MCollective is designed first and foremost for the CLI. You will mostly
interact with a single executable called *mco* which has a number of
sub-commands, arguments and flags.

## Basic Usage of the *mco* Command

A simple example of a *mco* command can be seen below:

{% highlight console %}
% mco ping
dev8                                     time=126.19 ms
dev6                                     time=132.79 ms
dev10                                    time=133.57 ms
.
.

---- ping statistics ----
25 replies max: 305.58 min: 57.50 avg: 113.16
{% endhighlight %}

In this example the *ping* sub-command is referred to as an
*application*. Mcollective provides many applications, for a list of
them, type *mco help*. You can also create your own application to plug
into the framework. The *help* sub-command will show you something like
this:


{% highlight console %}
% mco help
The Marionette Collective version 2.0.0

  controller      Control the mcollective daemon
  facts           Reports on usage for a specific fact
  find            Find hosts matching criteria
  help            Application list and help
  inventory       General reporting tool for nodes, collectives and subcollectives
  ping            Ping all nodes
  plugin          MCollective Plugin Application
  rpc             Generic RPC agent client application
{% endhighlight %}

You can request help for a specific application using either *mco help
application* or *mco application ---help*. Shown below is part of the
help for the *rpc* application:

{% highlight console %}
% mco help rpc
Generic RPC agent client application

Usage: mco rpc [options] [filters] --agent <agent> --action <action> [--argument <key=val> --argument ...]
Usage: mco rpc [options] [filters] <agent> <action> [<key=val> <key=val> ...]

        --no-results, --nr           Do not process results, just send request
    -a, --agent AGENT                Agent to call
        --action ACTION              Action to call
        --arg, --argument ARGUMENT   Arguments to pass to agent

        --np, --no-progress          Do not show the progress bar
    -1, --one                        Send request to only one discovered nodes
        --batch SIZE                 Do requests in batches
        --batch-sleep SECONDS        Sleep time between batches
        --limit-nodes, --ln COUNT    Send request to only a subset of nodes, can be a percentage
    -j, --json                       Produce JSON output
    -c, --config FILE                Load configuratuion from file rather than default
    -v, --verbose                    Be verbose
    -h, --help                       Display this screen

Common Options
    -T, --target COLLECTIVE          Target messages to a specific sub collective
        --dt, --discovery-timeout SECONDS
                                     Timeout for doing discovery
    -t, --timeout SECONDS            Timeout for calling remote agents
    -q, --quiet                      Do not be verbose
        --ttl TTL                    Set the message validity period
        --reply-to TARGET            Set a custom target for replies

Host Filters
    -W, --with FILTER                Combined classes and facts filter
    -S, --select FILTER              Compound filter combining facts and classes
    -F, --wf, --with-fact fact=val   Match hosts with a certain fact
    -C, --wc, --with-class CLASS     Match hosts with a certain config management class
    -A, --wa, --with-agent AGENT     Match hosts with a certain agent
    -I, --wi, --with-identity IDENT  Match hosts with a certain configured identity

The Marionette Collective 2.0.0
{% endhighlight %}

The *help* first shows a basic overview of the command line syntax
followed by options specific to this command.  Following that you will
see some *Common Options* and *Host Filters* that generally apply to
most applications.

## Making RPC Requests

### Overview of a Request

The *rpc* application is the main application used to make requests to
your servers. It is capable of interacting with any standard Remote
Procedure Call (RPC) agent. Below is an example that shows an attempt to
start a webserver on several machines:

{% highlight console %}
% mco rpc service start service=httpd
Determining the amount of hosts matching filter for 2 seconds .... 10

 * [ ============================================================> ] 10 / 10

dev4                                     Request Aborted
   Could not start Service[httpd]: Execution of '/sbin/service httpd start' returned 1:


Finished processing 10 / 10 hosts in 1323.61 ms
{% endhighlight %}

The order of events in this process are:

 * Perform discovery against the network and discover 10 servers
 * Send the request and then show a progress bar of the replies
 * Show any results that were out of the ordinary
 * Show some statistics

Mcollective client applications aim to only provide the most relevant
information.  In this case, the application is not showing verbose
information about the nine *OK* results, since the most important issue
is the one *Failure*. Keep this in mind when viewing the results of
commands.

### Anatomy of a Request

MCollective agents are broken up into actions and each action can take
input arguments.

{% highlight console %}
% mco rpc service stop service=httpd
{% endhighlight %}

This shows the basic make-up of an RPC command. In this case we are:

 * using the *rpc* application - a generic application that can interact with any agent
 * directing our request to machines with the *service* agent
 * sending a request to the *stop* action of the service agent
 * supplying a value, *httpd*, to the *service* argument of the *stop* action

The same command has a longer form as well:

{% highlight console %}
% mco rpc --agent service --action stop --argument service=httpd
{% endhighlight %}

These two commands are functionally identical.

### Discovering Available *Agents*

The above command showed you how to interact with the *service* agent,
but how can you find out that this agent even exists? On a correctly
installed MCollective system you can use the *plugin* application to get
a list:

{% highlight console %}
% mco plugin doc
Please specify a plugin. Available plugins are:

Agents:
  package         Install and uninstall software packages
  puppetd         Run puppet agent, get its status, and enable/disable it
  rpcutil         General helpful actions that expose stats and internals to SimpleRPC clients
  service         Agent to manage services
{% endhighlight %}

The first part of this list shows all the agents this computer is aware
of. In order to show up on this list, an agent must have a *DDL* file
and be installed locally.

To find out the *actions*, *inputs* and *outputs* for a specific agent
use the plugin application again:

{% highlight console %}
% mco plugin doc service
SimpleRPC Service Agent
=======================

Agent to manage services

      Author: R.I.Pienaar
     Version: 1.2
     License: GPLv2
     Timeout: 60
   Home Page: http://mcollective-plugins.googlecode.com/



ACTIONS:
========
   restart, start, status, stop

   status action:
   --------------
       Gets the status of a service

       INPUT:
           service:
              Description: The service to get the status for
                   Prompt: Service Name
                     Type: string
               Validation: ^[a-zA-Z\-_\d]+$
                   Length: 30


       OUTPUT:
           status:
              Description: The status of service
               Display As: Service Status
{% endhighlight %}

This shows a truncated example of the auto-generated help for the
*service* agent. First shown is metadata such as version, author and
license. This is followed by the list of actions available, in this case
the *restart*, *start*, *status* and *stop* actions.

Further information is shown about each action. For example, you can see
that the *status* action requires an input called *service* which is a
string, has a maximum length of 30, etc. You can also see you will
receive one output called *status*

With this information, you can request the status for a specific
service:

{% highlight console %}
% mco rpc service status service=httpd
Determining the amount of hosts matching filter for 2 seconds .... 10

 * [ ============================================================> ] 10 / 10


dev1
   Service Status: stopped

dev4
   Service Status: stopped

.
.
.

Finished processing 10 / 10 hosts in 326.01 ms
{% endhighlight %}

Unlike the previous example, in this case specific information is
returned on the success of the action. This is because this specific
action is meant to retrieve information and so mcollective assumes you
would like to see complete, thorough data regardless of success or
failure.

Note that this output displays *Service Status* as shown in the *mco
plugin doc service* help page. Any time you need more information about
a display name, the doc for the associated agent will have a
*Description* section for every input and output.

## Selecting Request Targets Using *Filters*

### Basic Filters

A key capability of mcollective is fast discovery of network resources.
Discovery rules are written using *filters*.  For example:

{% highlight console %}
% mco rpc service status service=httpd -S "environment=development or customer=acme"
{% endhighlight %}

This shows a filter rule that limits the RPC request to being run on
machines that are either in the Puppet environment *development* or
belong to the Customer *acme*.

Filtering can be based on *facts*, the presence of a *Configuration
Management Class* on the node, the node's *Identity*, or installed
*Agents* on the node.

Here are a number of examples of this with short descriptions of each
filter:

{% highlight console %}
# all machines with the service agent
% mco ping -A service
% mco ping --with-agent service

# all machines with the apache class on them
% mco ping -C apache
% mco ping --with-class apache

# all machines with a class that match the regular expression
% mco ping -C /service/

# all machines in the UK
% mco ping -F country=uk
% mco ping --with-fact country=uk

# all machines in either UK or USA
% mco ping -F "country=/uk|us/"

# just the machines called dev1 or dev2
% mco ping -I dev1 -I dev2

# all machines in the domain foo.com
% mco ping -I /foo.com$/
{% endhighlight %}

As you can see, you can filter by Agent, Class and/or Fact, and you can
use regular expressions almost anywhere.  You can also combine filters
additively in a command so that all the criteria have to be matched.

Note: You can use a shortcut to combine Class and Fact filters:

{% highlight console %}
# all machines with classes matching /apache/ in the UK
% mco ping -W "/apache/ location=uk"
{% endhighlight %}

### Complex *Compound* or *Select* Queries

While the above examples are easy to enter, they are limited in that
they can only combine filters additively. If you want to create searches
with more complex boolean logic use the *-S* switch. For example:

{% highlight console %}
% mco ping -S "((customer=acme and environment=staging) or environment=development) and /apache/"
{% endhighlight %}

The above example shows a scenario where the development environment is
usually labeled *development* but one customer has chosen to use
*staging*. You want to find all machines in those customer's
environments that match the class *apache*. This search would be
impossible using the previously shown methods, but the above command
uses *-S* to allow the use of boolean operators such as *and* and *or*
so you can easily build the logic of the search.

The *-S* switch also allows for negative matches using *not* or *!*:

{% highlight console %}
% mco ping -S "environment=development and !customer=acme"
% mco ping -S "environment=development and not customer=acme"
{% endhighlight %}

### Filtering Using Data Plugins

As of version 2.1.0, custom data plugins can also be used to create
complex filters:

{% highlight console %}
% mco ping -S "fstat('/etc/hosts').md5=/baa3772104/ and environment=development"
{% endhighlight %}

This will search for the md5 hash of a specific file with matches
restricted to the *development* environment.  Note that as before,
regular expressions can also be used.

As with agents, you can also discover which plugins are available for
use:

{% highlight console %}
% mco plugin doc

Please specify a plugin. Available plugins are:

Agents:
  .
  .

Data Queries:
  agent           Meta data about installed MColletive Agents
  augeas_match    Allows agents and discovery to do Augeas match lookups
  fstat           Retrieve file stat data for a given file
  resource        Information about Puppet managed resources
  sysctl          Retrieve values for a given sysctl
{% endhighlight %}

For information on the input these plugins take and  output they provide
use the *mco plugin doc fstat* command.

Currently, each data function can only accept one input while matches
are restricted to a single output field per invocation.

## Chaining RPC Requests

The *rpc* application can chain commands one after the other. The
example below uses the *package* agent to find machines with a specific
version of mcollective and then schedules Puppet runs on those machines:

{% highlight console %}
% mco rpc package status package=mcollective -j|jgrep "data.properties.ensure=2.0.0-6.el6" |mco rpc puppetd runonce
{% endhighlight %}

Mcollective results can also be filtered using the opensource gem,
jgrep. Mcollective data output is fully compatible with jgrep.

## Seeing the Raw Data

By default the *rpc* application will try to show human-readable data.
To see the actual raw data, add the *-v* flag to disable the display
helpers:

{% highlight console %}
% mco rpc nrpe runcommand command=check_load -I dev1 -v
.
.
dev1                                    : OK
    {:exitcode=>0,     :output=>"OK - load average: 0.00, 0.00, 0.00",     :perfdata=>      "load1=0.000;1.500;2.000;0; load5=0.000;1.500;2.000;0; load15=0.000;1.500;2.000;0;"}
{% endhighlight %}


This data can also be returned in JSON format:

{% highlight console %}
% mco rpc nrpe runcommand command=check_load -I dev1 -j
[
  {
    "action": "runcommand",
    "agent": "nrpe",
    "data": {
      "exitcode": 0,
      "output": "OK - load average: 0.00, 0.00, 0.00",
      "perfdata": "load1=0.000;1.500;2.000;0; load5=0.000;1.500;2.000;0; load15=0.000;1.500;2.000;0;"
    },
    "statuscode": 0,
    "statusmsg": "OK",
    "sender": "dev1"
  }
]
{% endhighlight %}

## Error Messaging

When an application encounters an error, it returns an explanatory
string:

{% highlight console %}
% mco rpc rpcutil foo
rpc failed to run: Attempted to call action foo for rpcutil but it's not declared in the DDL (MCollective::DDLValidationError)
{% endhighlight %}

By default only an abbreviated error string is shown that  provides some
insight into the nature of the problem.  For more details, add the *-v*
flag to show a full stack trace:

{% highlight console %}
% mco rpc rpcutil foo -v
rpc failed to run: Attempted to call action foo for rpcutil but it's not declared in the DDL (MCollective::DDLValidationError)
        from /usr/lib/ruby/site_ruby/1.8/mcollective/ddl.rb:303:in `validate_rpc_request'
        from /usr/lib/ruby/site_ruby/1.8/mcollective/rpc/client.rb:218:in `method_missing'
        from /home/rip/.mcollective.d/lib/mcollective/application/rpc.rb:133:in `send'
        from /home/rip/.mcollective.d/lib/mcollective/application/rpc.rb:133:in `main'
        from /usr/lib/ruby/site_ruby/1.8/mcollective/application.rb:283:in `run'
        from /usr/lib/ruby/site_ruby/1.8/mcollective/applications.rb:23:in `run'
        from /usr/bin/mco:20
{% endhighlight %}

## Custom Applications
The *rpc* application should suit most needs. However, sometimes the
data being returned calls for customization such as custom aggregation,
summarising or complete custom display.

In such cases, a custom application may be useful For example, the
*package* application provides concluding summaries and provides some
basic safe guards for its use. The agent also provides the commonly
required data. Typical *package* output looks like this:

{% highlight console %}
% mco package status kernel
Do you really want to operate on packages unfiltered? (y/n): y

 * [ ============================================================> ] 25 / 25


 dev5                                     version = kernel-2.6.32-220.7.1.el6
 dev9                                     version = kernel-2.6.32-220.2.1.el6
 .
 .

---- package agent summary ----
           Nodes: 25 / 25
        Versions: 9 * 2.6.32-220.2.1.el6, 9 * 2.6.32-220.4.1.el6, 7 * 2.6.32-220.el6
    Elapsed Time: 3.95 s
{% endhighlight %}


Notice how this application recognises that you are acting on all
possible machines, an action which might have a big impact on your YUM
servers. Consequently, *package* prompts for confirmation and, at the
end of processing, displays a brief summary of the network status.

While the behaviors of custom applications are not always consistent
with each other, in general they accept the standard discovery flags.
For details of which flags are accepted in a given application, use the
*mco help appname* command.

To discover which custom applications are available,  run *mco* or *mco
help*.
