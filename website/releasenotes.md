---
layout: default
title: Release Notes
toc: false
---

This is a list of release notes for various releases, you should review these
before upgrading as any potential problems and backward incompatible changes
will be highlighted here.


<a name="2_8_7">&nbsp;</a>

## 2.8.7 - 2016/01/13

### Changes since 2.8.6

* Fixed logrotate on systemd-based systems.
* Fixed negative data plugin comparisons.
* Fixed run helper on systems where the path to ruby includes spaces.


|Date|Description|Ticket|
|----|-----------|------|
|2015/12/17|Fix systemd logrotate unit|MCO-744|
|2015/12/16|Fix run helper for systems where the path to ruby binary includes spaces|MCO-742|
|2015/12/01|Fix negative data plugin comparisons|MCO-739|


<a name="2_8_6">&nbsp;</a>

## 2.8.6 - 2015/09/15

### Changes since 2.8.5

* Fixed an issue with the solaris smf service in AIO. The service manifest listed the
daemon binary in the wrong location (/opt/puppetlabs/bin as opposed to
/opt/puppetlabs/puppet/bin)

|Date|Description|Ticket|
|----|-----------|------|
|2015/09/11|Fix solaris smf service manifest for aio|(#345)[https://github.com/puppetlabs/marionette-collective/pull/345]|


<a name="2_8_5">&nbsp;</a>

## 2.8.5 - 2015/09/10

### Changes since 2.8.4

* Added condrestart action to suse AIO init script


|Date|Description|Ticket|
|----|-----------|------|
|2015/08/25|Add condrestart to the suse init script for AIO|RE-11690|


<a name="2_8_4">&nbsp;</a>

## 2.8.4 - 2015/08/21

### Changes since 2.8.3

* Changed the OSX service name back to the 2.8.2 value
  (com.puppetlabs.mcollective -> mcollective) as changing the service
  name in a point release is too disruptive.


|Date|Description|Ticket|
|----|-----------|------|
|2015/08/20|Revert RE-5032|MCO-705|


<a name="2_8_3">&nbsp;</a>

## 2.8.3 - 2015/08/18

### Bug fixes and improvements since 2.8.2

* Added a `describe_filter` application
* Fixed handling of quoted strings in compound filters
* Adds a solaris smf definition for puppet-agent
* Fixes for OSX service plist used by puppet-agent

### `mco describe_filter` application

In order to help you understand what the filtering options will
translate into when discovering nodes we've added a `describe_filter`
application.

Some exmples of this might be, find nodes with the apache configuraion
class:

{% highlight shell %}
$ mco describe_filter -C apache
-C filter expands to the following class checks:

  Check if class 'apache' is present on the host
{% endhighlight %}

Find hosts with the wizard class that came from the moon:

{% highlight shell %}
$ mco describe_filter -S 'wizard and source="moon"'
-S Query expands to the following instructions:

  Check if class 'wizard' is present on the host
  AND
  Check if fact 'source' = 'moon'
{% endhighlight %}


### Changes since 2.8.2

|Date|Description|Ticket|
|----|-----------|------|
|2015/08/05|Add solaris smf service for AIO|MCO-687|
|2015/07/17|Fully qualify the label in the osx mco plist|RE-5032|
|2015/07/13|Set character encoding in the OSX plist|(#326)[https://github.com/puppetlabs/marionette-collective/pull/326]|
|2015/07/03|Fix documentation links to use https|DOCS-2092|
|2015/06/05|Add `mco describe_filter` application|MCO-668|
|2015/06/05|Fix quote handling in compound query language|MCO-668|
|2015/06/04|Add acceptance tests|MCO-671|


<a name="2_8_2">&nbsp;</a>

## 2.8.2 - 2015/05/19

### Bug fixes and improvements since 2.8.1

* `mco notacommand` now tells you where we looked for application plugins
* Exit code of `mco notacommand` now indicates failure
* Fixes to the init script used by SUSE under puppet-agent

#### `mco nosuchapplication` behaviour changes

The behaviour of the `mco` command when a subcommand is absent has
been changed to indicate failure in its exit code.  We also now tell
you where we would have looked for the application plugins.

{% highlight shell %}
$ mco notacommand
The Marionette Collective version 2.8.2

Unknown command 'notacommand', searched for applications in:

   /Users/richardc/src/mcollective/lib
   /Users/richardc/.gem/ruby/1.9.3/gems/stomp-1.3.4/lib
   /opt/rubies/ruby-1.9.3-p547/lib/ruby/site_ruby/1.9.1
   /opt/rubies/ruby-1.9.3-p547/lib/ruby/site_ruby/1.9.1/x86_64-darwin13.4.0
   /opt/rubies/ruby-1.9.3-p547/lib/ruby/site_ruby
   /opt/rubies/ruby-1.9.3-p547/lib/ruby/vendor_ruby/1.9.1
   /opt/rubies/ruby-1.9.3-p547/lib/ruby/vendor_ruby/1.9.1/x86_64-darwin13.4.0
   /opt/rubies/ruby-1.9.3-p547/lib/ruby/vendor_ruby
   /opt/rubies/ruby-1.9.3-p547/lib/ruby/1.9.1
   /opt/rubies/ruby-1.9.3-p547/lib/ruby/1.9.1/x86_64-darwin13.4.0
   /Users/richardc/src/mcollective/lib/mcollective/vendor/systemu/lib

Known commands:

   completion           facts                find
   help                 inventory            ping
   plugin               rpc

Type 'bin/mco help' for a detailed list of commands and 'bin/mco help command'
to get detailed help for a command
$ echo $?
1
{% endhighlight %}

### Changes since 2.8.1

|Date|Description|Ticket|
|----|-----------|------|
|2015/05/12|Do not build for debian stable or testing (target codenames instead)|MCO-665|
|2015/05/08|Exit non-zero when `mco` is called with a non-existent subcommand|MCO-640|
|2015/05/08|Add legacy `libdir` settings to aio sample config|MCO-641|
|2015/05/08|Downgrade warning on absent `libdir`|MCO-647|
|2015/05/04|Add OSX plist for AIO|MCO-646|
|2015/04/23|Drop lucid from build targets|MCO-638|
|2015/04/13|Drop fedora 19 from build targets|MCO-633|
|2015/03/22|Update AIO SUSE init script|RE-3977|


<a name="2_8_1">&nbsp;</a>

## 2.8.1 - 2015/03/11

### Bug fixes since 2.8.0

* Fixed loading of the mcollective-client gem
* debian init condrestart action fixed for AIO

### Configuration path changes for Puppet Labs All-In-One Agent

Client applications will now use the first readable config file of
`~/.mcollective`, `/etc/puppetlabs/mcollective/client.cfg`,
`/etc/mcollective/client.cfg` when no configuration file is specified.

The MCollective daemon will now use the first readable config file of
`/etc/puppetlabs/mcollective/server.cfg`,
`/etc/mcollective/server.cfg` when no configuration file is specified.

*Note:* these are different to the paths announced in the 2.8.0 release
and may be a source of incompatibility if you have already rearranged
your files.

### Changes since 2.8.0

|Date|Description|Ticket|
|----|-----------|------|
|2015/03/05|Maintain version number in-tree|MCO-617|
|2015/02/18|Use updated AIO paths|MCO-594|
|2015/02/10|Fix AIO debian condrestart action|MCO-591|
|2015/02/05|Fix problems with 2.8.0 gem loading|MCO-587|


<a name="2_8_0">&nbsp;</a>

## 2.8.0 - 2015/02/04

### New Features and Improvements from 2.7.0

* Puppet Labs All-In-One Agent paths are now consulted in preference
  to traditional paths
* core plugins now live in lib, are installed into sitelibdir
* $libdir is now optional and extends the ruby $LOAD_PATH
* rubocop policy violations now cause Travis CI build failures

### Configuration path changes for Puppet Labs All-In-One Agent

Client applications will now use the first readable config file of
`~/.mcollective`, `/etc/puppetlabs/agent/mcollective/client.cfg`,
`/etc/mcollective/client.cfg` when no configuration file is specified.

The MCollective daemon will now use the first readable config file of
`/etc/puppetlabs/agent/mcollective/server.cfg`,
`/etc/mcollective/server.cfg` when no configuration file is specified.

This is to support the forthcoming All-In-One Agent packages from
Puppet Labs, which you can read about [here][aio].

[aio]: https://groups.google.com/d/msg/puppet-dev/qZ-nOvmfrig/htvN7tyo_1YJ

### $libdir/$LOAD_PATH changes and core plugins

What would have been known as the core plugins now live alongside the
core MCollective libraries and will be installed into ruby's
sitelibdir on installation.

In addition to this we have changed the behaviour of plugin loading so
that all of ruby's $LOAD_PATH is consulted, the $libdir configuration
file directive now works as a way to add entries to the start of this
search path.

The sum of these changes will make the mcollective-client gem usable
as a self-contained client, just supply `~/.mcollective`.

### Bug fixes since 2.7.0

* Fixed crashing bug caused by interaction of autoload and threads
* Fixed `mco facts` when no fact value is returned

### Changes since 2.7.0

|Date|Description|Ticket|
|----|-----------|------|
|2015/02/02|Add AIO init scripts to ext/aio|MCO-555|
|2015/02/02|Move core plugins into sitelibdir|MCO-583|
|2015/01/29|Prefer configuration files from AIO paths|MCO-560|
|2015/01/29|Use $LOAD_PATH for loading plugins|MCO-315|
|2015/01/28|Replace uses of `autoload` with `require`|MCO-580|
|2015/01/21|Fix `mco facts` in absence of fact|MCO-558|
|2015/01/07|Ensure rubocop failures fail the build|MCO-519|
|2014/12/19|Fix powershell exit code interactions|MCO-550|


<a name="2_7_0">&nbsp;</a>

## 2.7.0 - 2014/12/02


### New Features and Improvements from 2.6.1

* A collective data plugin has been added
* `mco` now supports a --connection-timeout option
* The target collective is now visible to custom discovery plugins
* implemented_by now searches a more conventional path
* `mco plugin package` now supports 'lib' layout
* The version of the stomp gem in use is now logged at connector startup
* We now log the senderid of a successfully decoded frame at debug
* Default values for STOMP 1.1 heart-beating have been revisited


### New collective data plugin, and collective filtering

We have added a collective data plugin, which enables you to filter
based on collective membership.

For example, to find nodes connected to the `all` collective which are
also members of the `us` collective you can use the following compound
query:

{% highlight console %}
$ mco find -T all -S 'collective("us").member=true'
{% endhighlight %}


### --connection-timeout client option

`mco` now supports a --connection-timeout option (connection_timeout
in a client configuration file).  It will cause the mcollective client
to abort if a connection to the middleware cannot be established in
the specified number of seconds (the default value is unspecified - no
timeout).

{% highlight shell %}
$ mco ping --connection-timeout 5
error 2014/11/24 17:10:47: activemq.rb:149:in `on_ssl_connectfail' SSL session creation with stomp+ssl://mcollective@127.0.0.1:61614 failed: Connection refused - connect(2)
error 2014/11/24 17:10:47: activemq.rb:149:in `on_ssl_connectfail' SSL session creation with stomp+ssl://mcollective@127.0.0.1:61614 failed: Connection refused - connect(2)
error 2014/11/24 17:10:47: activemq.rb:149:in `on_ssl_connectfail' SSL session creation with stomp+ssl://mcollective@127.0.0.1:61614 failed: Connection refused - connect(2)
error 2014/11/24 17:10:47: activemq.rb:149:in `on_ssl_connectfail' SSL session creation with stomp+ssl://mcollective@127.0.0.1:61614 failed: Connection refused - connect(2)
error 2014/11/24 17:10:47: activemq.rb:149:in `on_ssl_connectfail' SSL session creation with stomp+ssl://mcollective@127.0.0.1:61614 failed: Connection refused - connect(2)
error 2014/11/24 17:10:47: activemq.rb:149:in `on_ssl_connectfail' SSL session creation with stomp+ssl://mcollective@127.0.0.1:61614 failed: Connection refused - connect(2)
error 2014/11/24 17:10:47: activemq.rb:149:in `on_ssl_connectfail' SSL session creation with stomp+ssl://mcollective@127.0.0.1:61614 failed: Connection refused - connect(2)
error 2014/11/24 17:10:48: activemq.rb:149:in `on_ssl_connectfail' SSL session creation with stomp+ssl://mcollective@127.0.0.1:61614 failed: Connection refused - connect(2)
error 2014/11/24 17:10:49: activemq.rb:149:in `on_ssl_connectfail' SSL session creation with stomp+ssl://mcollective@127.0.0.1:61614 failed: Connection refused - connect(2)
error 2014/11/24 17:10:52: client.rb:39:in `rescue in initialize' Timeout occured while trying to connect to middleware

The ping application failed to run, use -v for full error backtrace details: execution expired
{% endhighlight %}

This is complementary to the `plugin.activemq.max_reconnect_attempts`
or `plugin.rabbitmq.max_reconnect_attempts` parameters available to the
activemq and rabbitmq connectors.


### STOMP 1.1 heart-beat values

The initial default values for `plugin.activemq.max_hbrlck_fails` and
`plugin.rabbitmq.max_hbrlck_fails` have been changed to 0.  This is
more appropriate for MCollective's usage pattern as the main receiver
thread will block the heartbeat threads ability to claim the read
lock on the connector socket.

If you have previously specified a value for this parameter, we
suggest you use the new default of 0.


### lib layout and `mco plugin package`

The traditional way to layout an MCollective plugin in your source
repository is what we are now referring to as 'flat' layout, and looks
like this:

{% highlight console %}
$ tree
.
├── agent
│   ├── flat.ddl
│   └── flat.rb
└── spec
    └── unit
        └── flat_agent_spec.rb
{% endhighlight %}


A similar agent plugin in lib layout will look like this:

{% highlight console %}
$ tree
.
├── lib
│   └── mcollective
│       └── agent
│           ├── lib.ddl
│           └── lib.rb
└── spec
    └── unit
        └── mcollective
            └── agent
                └── lib_spec.rb
{% endhighlight %}

You'll see that under lib layout the paths now more closely match the
namespaces in the files, and also the structure you use when
installing the agent onto a target system.  This means that you can
more readily test a plugin under development by adding something like
the following to your configuration files:

{% highlight ini %}
libdir = /usr/src/mcollective-libdemo-agent/lib
{% endhighlight %}

In order to allow you to adopt lib layout more easily, `mco plugin
package` has been updated to support it.

### implemented_by path changes

As originally written, the `implemented_by $command` feature searches
for the command in `$libdir/agent/$agentname/$command` when the path
is not fully-qualified.  This was potentially confusing as the main
agent implementation file is in
`$libdir/mcollective/agent/$agentname.rb`.

With this release we now search
`$libdir/mcollective/agent/$agentname/$command` in addition to
`$libdir/agent/$agentname/$command`, and will invoke the command from
the former location if the command exists in both locations.

In MCollective 2.8.0 we will warn more strongly if we find a the
external helper in both locations, and remove the search of the old
path in 2.9.0.


### Bug fixes since 2.6.1

* Exceptions raised in the runner are now re-raised in the main thread
* Windows service_manager.rb now more aggressively tests for a ruby binary, avoiding broken installs


### Changes since 2.6.1

|Date|Description|Ticket|
|----|-----------|------|
|2014/11/24|Revisit STOMP 1.1 heart-beat defaults|MCO-522|
|2014/11/18|Log the senderid of messages at debug|MCO-521|
|2014/11/11|Add a --connection-timeout to the client options|MCO-464|
|2014/11/11|Add search of `$libdir/mcollective/agent/$agent/$action` to `implemented_by`|MCO-466|
|2014/11/10|`mco plugin package` support for 'lib' layout|MCO-314|
|2014/10/28|Add rubocop style checks to the codebase|MCO-136|
|2014/10/22|Expose target collective to custom discovery plugins|MCO-456|
|2014/10/13|Make windows service_manager.rb helper more vigorous in finding ruby|MCO-465|
|2014/10/02|Reraise exceptions caught by the runner thread in the main thread|MCO-475|
|2014/10/01|Add a collective data plugin|MCO-472|
|2014/10/01|Update windows scripts to pass --daemonize to daemon|MCO-474|
|2014/09/20|Report the version of stomp gem at startup|MCO-470|
|2014/09/19|Removed vendoring of the json gem|MCO-457|


<a name="2_6_1">&nbsp;</a>

## 2.6.1 - 2014/10/29


### Improvements from 2.6.0

* We now preconfigure the SSL context used to disallow the SSLv2 and SSLv3 protocols.
* The rabbitmq and activemq connectors now allow you to specify the
  desired set of SSL ciphers.

### Connector cipher specification

The rabbitmq and activemq connector plugins now allow the
specification of ciphers to be used in the connection to the
middleware.

To request the same set of cipher that ruby 2.1.2 defaults to you
could specify:

    # ciphers from ruby 2.1.2
    plugin.activemq.pool.1.ssl.ciphers = ALL:!ADH:!EXPORT:!SSLv2:RC4+RSA:+HIGH:+MEDIUM:+LOW


If not specified the default set of ciphers chosen will depend on a
combination of the version of the stomp gem in use and your version of
ruby.

See the OpenSSL documentation for further explanation of what these cipher
strings mean.

https://www.openssl.org/docs/apps/ciphers.html#CIPHER_STRINGS


### Changes since 2.6.0

|Date|Description|Ticket|
|----|-----------|------|
|2014/10/23|Disable SSLv2 and SSLv3 protocols by default|MCO-489|
|2014/10/16|Expose SSL cipher selection via connector settings|MCO-486|


<a name="2_6_0">&nbsp;</a>

## 2.6.0 - 2014/08/28



### New Features and Improvements from 2.5.3

 * `mcollectived` now supports the command line options `--no-daemonize` and `--daemonize`
 * Connector plugins now require DDL files
 * The base64_decode method is now stricter, and will report errors from the correct place in the calling hierarchy
 * Structured facts are now supported in simple discovery and compound filters
 * Several actions now choose the number of display columns dynamically based on the values they are presenting
 * rpc clients now respect a `--sort` option
 * `mcollectived` now responds to the SIGWINCH signal to perform log rotation
 * The `--batch` flag can now by used to specify percentages
 * Agent loading can now be globally defaulted to false
 * A new option `registration_splay` has been added to defer registration on startup
 * `discovery_timeout` can now be specified in the client.cfg
 * `soft_shutdown` is now configurable with a `soft_shutdown_timeout` option
 * We now use a distinct reply queue per request, which should perform better at scale

### Structured fact support

We have added two mechanisms for dealing with structured facts when
filtering nodes.

For the simple form of fact matching, --with-fact (-F) will now match
to array elements or hash keys where the value of a fact is a hash or
array.

Given the set of facts:

    {
      "baz": [ "a", "b" ],
      "quux": { "foo": "flirble" },
    }

These mco ping invocations would match:

    mco ping --with-fact 'baz=a'
    mco ping --with-fact 'quux=foo'

And the following would not:

    mco ping --with-fact 'baz=c'
    mco ping --with-fact 'quux=flirble'


There is more complex and powerful mechanism available via the fact
data plugin which is exposed by the compound filter language use by
the `--select` (`-S) switch.  It allows you to navigate the structured
facts with a path delimited by periods.

Given these facts:

    {
      "foo": "bar",
      "baz": [ "a", "b" ],
      "numbers": [ 6, 2, 1 ],
      "quux": { "foo": "flirble" },
    }

The following invocations would match:

    mco ping --select 'fact("foo").value=bar'
    mco ping --select 'fact("baz.0").value=a'
    mco ping --select 'fact("quux.foo").exists=true' # checks for existence of the key
    mco ping --select 'fact("quux.foo").value=flirble'


### `registration_splay`

Registration can now be delayed from sending the initial registration
message (splayed) with the `registration_splay` option.  In the
following configuration the first registration message will be sent
after a random delay of up to 600 seconds, and then subsequent
registration messages will be every 600 seconds.

    # server.cfg
    registration = 600
    registration_splay = true

This can reduce load spikes on your middleware if you choose to
restart your agents in batches.

### Changes to agent loading

It is now possible to change the default behavior for agent loading
with the `activate_agents` option which complements the
`plugin.$plugin_name.activate_agent` settings.  It defaults to `true`
which is the behavior in previous versions of MCollective.

In this example we only enable the service and package agents, rather
than all agents installed:

    # server.cfg
    activate_agents = false
    plugin.service.activate_agent = true
    plugin.package.activate_agent = true

### mco rpc actions now have a '--sort' option

It is now possible to order the results in an rpc result set with the
`--sort` flag.  This adds a small overhead, and so is off by default.


{% highlight shell %}
$ mco rpc rpcutil ping --sort
Discovering hosts using the mc method for 2 second(s) .... 5

* [ ============================================================> ] 5 / 5


server-0
   Timestamp: 1408313208

server-1
   Timestamp: 1408313208

server-2
   Timestamp: 1408313208

server-3
   Timestamp: 1408313208

server-4
   Timestamp: 1408313208



Finished processing 5 / 5 hosts in 10.29 ms
{% endhighlight %}



### Bug fixes since 2.5.3

 * Fixed the exitcode of `mco ping`
 * Fixed the flow of rpc response processing
 * Fixed reply-to behavior in the rabbitmq connector
 * Fixed `call_agent_batched` to work with activerecord
 * It is now possible to reset `limit_targets`
 * Fixes to signal handling were made for ruby 2 compatibility
 * It is now possible to unset `LC_ALL` when using the shell helper
 * Fixed a race condition in validation plugin loader


### Backwards Compatibility and Upgrading

If you are using a non-standard connector plugin, you will need to
ensure it has a DDL file or MCollective will refuse to use it.

### Changes since 2.5.3

|Date|Description|Ticket|
|----|-----------|------|
|2014/08/20|Fix a race condition in type validator plugin loader|MCO-453|
|2014/08/12|Use a distinct reply queue per request|MCO-443|
|2014/08/07|Add `soft_shutdown_timeout` option|MCO-243|
|2014/08/06|Add documentation of heartbeat options to the connector pages|MCO-175|
|2014/08/01|Move signal handling into threads (ruby 2 compatibility)|MCO-421|
|2014/08/01|Allow LC\_ALL environment variable to be unset|MCO-156|
|2014/08/01|Add `discovery_timeout` to the configuration file|MCO-193|
|2014/08/01|Add `registration_splay` configuration option|MCO-272|
|2014/07/31|Allow for agent loading to be globally defaulted|MCO-408|
|2014/07/31|Change the 'expired message' message to indicate the message is being discarded|MCO-418|
|2014/07/31|Allow the --batch flag to specify percentages|MCO-68|
|2014/07/31|Reopen logfiles on SIGWINCH|MCO-328|
|2014/07/31|Add --sort option to rpc clients|MCO-83|
|2014/07/31|Dynamically decide number of columns for output|PR#215|
|2014/07/31|Specify the --daemonize option in sample init scripts|MCO-416|
|2014/07/29|Allow `limit_targets` to be reset|MCO-93|
|2014/07/29|Fixed rabbitmq reply-to under `use_reply_exchange`|MCO-351|
|2014/07/29|Reworked examples of catching uncatchable errors|MCO-411|
|2014/07/23|Make the base64 decoder more strict|MCO-293|
|2014/07/22|Add support for structured facts|MCO-363|
|2014/07/18|Fix `call_agent_batched` to work with activerecord|MCO-205|
|2014/07/18|Fix rpc response processing for bad replies|MCO-264|
|2014/07/17|Fix direct addressing regression introduced in MCO-360|MCO-410|
|2014/07/17|Require connector plugins to have ddls|MCO-407|
|2014/07/17|Add ddls to `activemq` and `rabbitmq` connectors|MCO-406|
|2014/07/16|Fix halt\_code to return the correct exitcode for `mco ping`|MCO-199|
|2014/07/16|Remove all reference to the 'mcollective' agent|MCO-360|
|2014/07/01|Add --no-daemonize and --daemonize option to mcollectived|MCO-181|
|2014/05/21|Fix a url in the solaris readme|MCO-186|

<a name="2_5_3">&nbsp;</a>

## 2.5.3 - 2014/07/15

### Bug fixes since 2.5.2

* Address potential flaw in aes security plugin - CVE-2014-3251
* Fix data plugin load ordering

### Changes since 2.5.2

|Date|Description|Ticket|
|----|-----------|------|
|2014/06/20|Address potential flaw in aes security plugin.  CVE-2014-3251|MCO-329|
|2014/05/30|Fix data plugin load ordering|MCO-346|


<a name="2_5_2">&nbsp;</a>

## 2.5.2 - 2014/06/10

### Bug fixes since 2.5.1

* Remove '.' from ruby `$LOAD_PATH` - CVE-2014-3248

### Changes since 2.5.1

|Date|Description|Ticket|
|----|-----------|------|
|2014/05/27|Remove '.' from ruby `$LOAD_PATH` CVE-2014-3248|MCO-311|


<a name="2_5_1">&nbsp;</a>

## 2.5.1 - 2014/05/14

### Bug fixes since 2.5.0

* Improve line parsing in flatfile discovery
* Remove unused/broken `mc-call-agent` binary
* Fix `mco plugin package` for RedHat derivatives
* Allow stomp login/passcode to be optional

### Changes since 2.5.0

|Date|Description|Ticket|
|----|-----------|------|
|2014/05/12|Allow stomp login/passcode to be optional|MCO-316|
|2014/05/02|Fix dependencies of rpms from `mco plugin package`|MCO-292|
|2014/05/01|Fix rpmbuild error in `mco plugin package`|MCO-285|
|2014/04/24|Stop install mc-call-agent|MCO-266|
|2014/04/24|Improve line parsing in flatfile discovery|MCO-262|


<a name="2_5_0">&nbsp;</a>

## 2.5.0 - 2014/04/23

### New Features and Improvements

 * MCollective should generally fail less awkwardly when dealing with middleware problems
 * Added a new `soft_shutdown` option to allow agents to complete or timeout before exiting the daemon

As part of the improvements we've made to connectors and their interaction
with the middleware, we've made a few changes that under semver need us to
bump the version number to 2.5.0.

### The `soft_shutdown` option

To make use of the new `soft_shutdown` feature add the following to your server.cfg

    soft_shutdown = true

### Changes since 2.4.1

|Date|Description|Ticket|
|----|-----------|------|
|2014/04/23|Deprecate Runner#run method|MCO-265|
|2014/04/23|Drop ubuntu 13.04 (raring ringtail) from the supported package builds|MCO-263|
|2014/04/17|Add ubuntu 14.04 (trusty tahir) to the supported package builds|MCO-189|
|2014/04/10|Refactor the runner class|MCO-221|
|2014/04/04|Update rubygems requirement to 1.3.7 or greater|MCO-188|
|2014/04/02|Move exception classes from lib/mcollective.rb to lib/mcollective/exceptions.rb|MCO-215|
|2014/03/26|Plugin plugin - add dist macro to Release field|MCOP-17|
|2014/03/12|Implements exponential back-off at the connector level|MCO-192|
|2014/02/28|Log reciept and contents of non-MESSAGE STOMP frames|MCO-191|
|2014/02/25|Connectors should not suggest STOMP 1.1 heartbeats if the gem cannot support them|MCO-198|


<a name="2_4_1">&nbsp;</a>

## 2.4.1 - 2014/02/10

### Bug Fixes from 2.4.0

 * Remove reference to package iteration in #package_information
 * Improve logging when connector fails to connect
 * Fix `plugin.rabbitmq.use_reply_exchange` subscription behavior

### Changes since 2.4.0

|Date|Description|Ticket|
|----|-----------|------|
|2014/02/10|Remove reference to package iteration in #package_information|MCO-179|
|2014/02/07|Update documentation to note that `plugin.rabbitmq.use_reply_exchange` should work from 2.4.1|MCO-174|
|2014/01/30|Improve logging when connector fails to connect|MCO-173|
|2014/01/29|Fix `plugin.rabbitmq.use_reply_exchange` subscription behavior|MCO-172|


<a name="2_4_0">&nbsp;</a>

## 2.4.0 - 2014/01/23

*Note: From 2.4.0 MCollective is observing semver (http://semver.org/)*

### New Features and Improvements from 2.2.4

 * Correct reply-to headers are now set for both ActiveMQ and RabbitMQ
 * Fire and forget requests are now direct addressing aware
 * Boolean values in the config classes have now been standardised via a new Util#str_to_bool helper
 * SSL certificate paths for ActiveMQ and RabbitMQ can now be set in the users shell environment
 * Aggregate plugins are supported in the 'mco plugin doc' application and bundled plugins now have usage information
 * Default ports for ActiveMQ and RabbitMQ have changed to 61613
 * Data returned by data plugins are pre-populated with defaults from the DDL
 * Direct addressing is now enabled by default
 * Argument validation in the rpc application now happens before discovery to provide more timely user feedback
 * plugin.discovery.timeout has been removed
 * Certain paths have more platform appropriate defaults on Windows
 * Filter methods on the RPC client are now idempotent
 * The topicprefix, topicsep, queueprefix, rpchelptemplate, helptemplatedir options have been removed and will log a deprecation warning if used.
 * Support for version 1.1 of the Stomp protocol has been added to the ActiveMQ and RabbitMQ connectors
 * A get_facts action has been added to the rpcutil agent that can retrieve a list of facts
 * The plugin packager has been updated to only create a single source artifact when building packages
 * The plugin packager can now express operating system specific dependencies
 * A Module packager has been added that will output Puppet modules that can be used with the Puppet Labs MCollective module
 * A stdin discovery plugin has been added
 * Message publishing time is no longer part of the request timeout and is now configurable
 * An option has been added to enable threading in the client which improves responsiveness when publishing large amounts of directed messages
 * RabbitMQ federation support has been added
 * A timeout option has been added to the Shell command runner
 * Packaging has been updated to conform with other Puppet Labs projects
 * Test coverage has been improved
 * Config values that are expected to be integers will no longer be incorrectly parsed
 * The DDL action display preference, :flatten, has been deprecated and will be completely removed in the next minor release

### Bug Fixes from 2.2.4

 * Direct requests on sub-collectives will now work correctly when using the RabbitMQ connector
 * The Plugin Packager now correctly sets the plugin version supplied by the --pluginversion flag
 * The --nodes flag will no longer raise an error on Ruby 1.9.3
 * Stopping the MCollective agent on Windows will now exit cleanly
 * The systemu guard thread will now exit cleanly when Shell.runcommand() is called from a long running thread
 * Correctly handle discovery where data plugins return nil for a specific item
 * The flatfile discovery method validates identities using the same rules as the config class
 * The Util#versioncmp function behaves correctly with semver versions where the minor is larger than 10
 * Debian packages will now build correctly in a chroot
 * The run() agent helper could sometimes return -1 and leave zombies, this has been improved
 * Certain operations on a reply data item in an agent could alter the cached copy of the DDL thus affecting future agent invocations
 * Absolute paths on Windows are detected correctly
 * Line numbers are printed correctly in logs on Windows machines
 * Whitespace before config keys in the config file are now ignored

### Removed Functionality from 2.2.4

 * The STOMP adapter has been deprecated and removed

### Backwards Compatibility and Upgrading:

With the removal of the Stomp connector, in this release we are deprecating a number of unused configuration options that was used by this
connector and a few others that has become pointless over the years.

If you have any of the following in your configuration files you should consider removing them as they no longer have any effect.

 * topicprefix
 * queueprefix
 * rpchelptemplate
 * helptemplatedir
 * plugin.discovery.timeout
 * topicsep

### STOMP 1.1 support with RabbitMQ and ActiveMQ

A common problem is that idle STOMP connections get expired by session tracking firewalls and NAT devices. Version 1.1 of the STOMP
protocol combats this with protocol level heartbeats which can now be enabled when using version 1.2.10 and up of the stomp gem.


    # Send heartbeats in 30 second intervals. This is the shortest supported period.
    plugin.activemq.heartbeat_interval = 30

    # By default if heartbeat_interval is set it will request STOMP 1.1 but support fallback
    # to 1.0, but you can enable strict STOMP 1.1 only operation by disabling 1.0 fallback
    plugin.activemq.stomp_1_0_fallback = 0

    # Maximum amount of heartbeat read failures before retrying. 0 means never retry.
    plugin.activemq.max_hbread_fails = 2

    # Maxium amount of heartbeat lock obtain failures before retrying. 0 means never retry.
    plugin.activemq.max_hbrlck_fails = 2


For the RabbitMQ connector the names of the options are as follows.


    # Send heartbeats in 30 second intervals. This is the shortest supported period.
    plugin.rabbitmq.heartbeat_interval = 30

    # By default if heartbeat_interval is set it will request STOMP 1.1 but support fallback
    # to 1.0, but you can enable strict STOMP 1.1 only operation by disabling 1.0 fallback
    plugin.rabbitmq.stomp_1_0_fallback = 0

    # Maximum amount of heartbeat read failures before retrying. 0 means never retry.
    plugin.rabbitmq.max_hbread_fails = 2

    # Maxium amount of heartbeat lock obtain failures before retrying. 0 means never retry.
    plugin.rabbitmq.max_hbrlck_fails = 2

More information about STOMP heartbeats can be found http://stomp.github.io/stomp-specification-1.1.html#Heart-beating

### RabbitMQ Federation

RabbitMQ federation only mirrors exchanges between nodes so replies need to be
sent to an exchange instead of a queue.  In order to enable that add the
following snippet to your client configuration:


    plugin.rabbitmq.use_reply_exchange = true


You will also need to create an exchange called `mcollective_reply` in your
rabbitmq vhost.


    $ rabbitmqadmin declare exchange --user=admin --password=changeme --vhost=/mcollective name=mcollective_reply type=direct


### Changes to the Client

In this release we have made two changes to increase reliability when sending a large amount of messages. Firstly, we have
added a customisable publishing timeout which is independant from the agent timeout. This can be set either in the client
configuration file

    #client.cfg
    publish_timeout = 2

or on the command line

    $ mco rpc rpcutil ping --publish_timeout 2

The publishing timeout will default to 2 seconds.

Secondly this release adds the ability to start the client in threaded mode. This will greatly increase the amount of
messages that can be sent when using direct addressing. This can be enabled either in the client configuration file

    #client.cfg
    threaded = true

or on the command line

    $ mco rpc rpcutil ping --nodes large_node_file.txt --threaded

### Plugin Packager

This release brings three improvements to the plugin packager.

A module target has been added which allows you output Puppet modules that can be used with the new MCollective Puppet Module.


    $ git clone https://github.com/puppetlabs/mcollective-service-agent
    $ cd mcollective-service-agent
    $ mco plugin package \
         --format modulepackage \
         --vendor puppetlabs


This will create a module for the forge named puppetlabs-mcollective_service_agent containing the source
code and the class mcollective_service_agent::agent

This release also adds the ability to specify system specific dependensies when building RPM's or Deb's.

    $ mco plugin package --dependency="debian::ruby-net-ping" \
                         --dependency="redhat::rubygem-net-ping"

Finally the plugin packager will no longer create multiple source artifacts when building packages.

### Changes since 2.2.4

|Date|Description|Ticket|
|----|-----------|------|
|2014/01/16|MCollective service doesn't exit on Windows|MCO-158|
|2014/01/08|Turned use of removed options into warnings|MCO-151|
|2014/01/08|Removed i18n spike (#18863)|MCO-138|
|2014/01/07|Fixed a spurious warning in 'mco ping'|MCO-146|
|2014/01/07|Config class does not parse fixnum config parameters correctly|MCO-97|
|2014/01/06|deprecate and remove flattened output|MCO-84|
|2013/12/19|Make audit plugin log output match standard format|MCO-142|
|2013/11/07|Add a modulepackage target to the plugin packager|23099|
|2013/11/06|Fix possible thread leak in Shell|23090|
|2013/11/06|Add a timeout option for system commands|22114|
|2013/11/05|Redo the packaging of mcollective|17067|
|2013/10/30|Add rabbitmq federation support with `plugin.rabbitmq.use_reply_exchange`|22603|
|2013/10/30|Update rabbitmq connector documentation for recent version of rabbitmqadmin|19537|
|2013/10/17|mcollective service does not gracefully exit on windows|20467|
|2013/10/16|Add option to thread client|21910|
|2013/10/16|Publishing time should not be part of the request time|21910|
|2013/10/11|Add a stdin discovery method|22061|
|2013/10/08|Plugin packager doesn't apply --pluginversion option|22790|
|2013/10/07|Mcollective plugins cannot express dependencies|22361|
|2013/10/03|Ability to retrieve multiple facts through rpcutil|21788|
|2013/10/01|Fix packaging for debain/ubuntu with ruby 1.9|16572|
|2013/09/27|Fix buildmacpkg|16786|
|2013/09/27|Fix --nodes 'nodefile' on ruby 1.9.3|22720|
|2013/09/25|MCO Plugin Packager produces more than one source artifact|22316|
|2013/09/06|Fix directed request on subcollectives with rabbit connector|21755|
|2013/08/19|add an install.rb file to mcollective|22220|
|2013/08/02|Support Stomp 1.1 with RabbitMQ and ActiveMQ|15182|
|2013/07/31|Surpress Errno::ESRCH info messages when running shell commands|21779|
|2013/07/03|Improve error reporting when requesting docs for a non existing plugin|21429|
|2013/07/03|Support aggregate plugins in 'mco plugin doc'|18414|
|2013/07/03|Allow the ActiveMQ and RabbitMQ SSL cert paths to be set using environment variables|20550|
|2013/06/23|Gracefully handle whitespaces in the config file before config keys|21407|
|2013/06/19|Ensure the line numbers are printed correctly on both Windows and Unix|20506|
|2013/06/19|Remove the rpchelptemplate and helptemplatedir options|20714|
|2013/06/18|Correctly detect Windows absolute paths|21251|
|2013/06/10|Fix and centralize handling of boolean values for settings|19751|
|2013/06/06|Clone the default values from the DDL to avoid accidental modifications to the cached DDL file|21104|
|2013/06/05|Filter methods on the RPC Client are now idempotent|20233|
|2013/06/04|run() call in an agent can return incorrect Process::Status|17667|
|2013/06/03|Improve debian dependencies so packages can be rebuilt in a chroot|20950|
|2013/05/28|Set expire headers in the ActiveMQ and RabbitMQ message headers|19905|
|2013/05/10|Correctly detect version differences in semver version where the path level is greater 10|20661|
|2013/05/01|Improve behaviour of data matchers when return values are nil|20059|
|2013/04/29|Improve config defaults on windows machines|20388|
|2013/04/18|Enforce valid identity names in the file discovery method|20282|
|2013/04/11|Add direct addressing awareness to the fire and forget request mode|17930|
|2013/03/22|Remove the topicprefix, queueprefix and topicsep options|19673|
|2013/03/21|Remove the plugin.discovery.timeout setting as it's not relevant anymore|19694|
|2013/03/21|Improve error reporting from the rpc application in the light of direct_addressing|19827|
|2013/03/20|Fail with a friendly error message when no libdir is set|19752|
|2013/03/14|Change default RabbitMQ and ActiveMQ ports to 61613|19734|
|2013/03/13|Set correct reply-to headers in the RabbitMQ connector|17034|
|2013/03/12|Pre-populate the data from data plugins like agent replies|19564|
|2013/03/12|Explicitly include StringIO|19367|
|2013/03/12|Enable direct addressing by default|19665|
|2013/02/20|Fix error code collision on PLMC18|19366|
|2013/02/15|Validate arguments supplied to the RPC application and raise errors sooner|19181|


<a name="2_3_3">&nbsp;</a>

## 2.3.3 - 2013/11/07

This is the fourth release in the new development series of MCollective. This
release features enchancements and bug fixes.

This release is for early adopters, production users should consider the 2.2.x
series.

### New Features and Improvements

 * Support for version 1.1 of the Stomp protocol has been added to the ActiveMQ and RabbitMQ connectors
 * A get_facts action has been added to the rpcutil agent that can retrieve a list of facts
 * The plugin packager has been updated to only create a single source artifact when building packages
 * The plugin packager can now express operating system specific dependencies
 * An experimental module packager has been added that will output Puppet modules that can be used with the Puppet Labs MCollective module
 * A stdin discovery plugin has been added
 * Message publishing time is no longer part of the request timeout and is now configurable
 * An experimental option has been added to enable threading in the client which should improve responsiveness when publishing large amounts of directed messages
 * Experimental RabbitMQ federation support has been added
 * A timeout option has been added to the Shell command runner
 * Packaging has been updated to conform with other Puppet Labs projects

### Bug Fixes

 * Suppress Errno::ESRCH info messages when running shell commands
 * Direct requests on sub-collectives will now work correctly when using the RabbitMQ connector
 * The Plugin Packager now correctly sets the plugin version supplied by the --pluginversion flag
 * The --nodes flag will no longer raise an error on Ruby 1.9.3
 * Stopping the MCollective agent on Windows will now exit cleanly
 * The systemu guard thread will now exit cleanly when Shell.runcommand() is called from a long running thread

### Backwards Compatibility and Upgrading

There should be no additional steps required when upgrading from 2.3.2 to 2.3.3. If you are upgrading from 2.3.1 or earlier please
refer to the 2.3.2 compatibility notes.

### Changes since 2.3.2

|Date|Description|Ticket|
|----|-----------|------|
|2013/11/07|Add a modulepackage target to the plugin packager|23099|
|2013/11/06|Fix possible thread leak in Shell|23090|
|2013/11/06|Add a timeout option for system commands|22114|
|2013/11/05|Redo the packaging of mcollective|17067|
|2013/10/30|Add rabbitmq federation support with `plugin.rabbitmq.use_reply_exchange`|22603|
|2013/10/30|Update rabbitmq connector documentation for recent version of rabbitmqadmin|19537|
|2013/10/17|mcollective service does not gracefully exit on windows|20467|
|2013/10/16|Add option to thread client|21910|
|2013/10/16|Publishing time should not be part of the request time|21910|
|2013/10/11|Add a stdin discovery method|22061|
|2013/10/08|Plugin packager doesn't apply --pluginversion option|22790|
|2013/10/07|Mcollective plugins cannot express dependencies|22361|
|2013/10/03|Ability to retrieve multiple facts through rpcutil|21788|
|2013/10/01|Fix packaging for debain/ubuntu with ruby 1.9|16572|
|2013/09/27|Fix buildmacpkg|16786|
|2013/09/27|Fix --nodes 'nodefile' on ruby 1.9.3|22720|
|2013/09/25|MCO Plugin Packager produces more than one source artifact|22316|
|2013/09/06|Fix directed request on subcollectives with rabbit connector|21755|
|2013/08/19|add an install.rb file to mcollective|22220|
|2013/08/02|Support Stomp 1.1 with RabbitMQ and ActiveMQ|15182|
|2013/07/31|Surpress Errno::ESRCH info messages when running shell commands|21779|

<a name="2_3_2">&nbsp;</a>

## 2.3.2 - 2013/07/11

This is the third release in the new development series of MCollective.  This
release features enhancements and bug fixes.

This release is for early adopters, production users should consider the 2.2.x
series.

There are important steps to take before upgrading to this release, please carefully
read the updating section below.

### New Features and Improvements

 * Correct reply-to headers are now set for both ActiveMQ and RabbitMQ
 * Fire and forget requests are now direct addressing aware
 * Boolean values in the config classes have now been standardised via a new `Util#str_to_bool` helper
 * SSL certificate paths for ActiveMQ and RabbitMQ can now be set in the users shell environment
 * Aggregate plugins are supported in the 'mco plugin doc' application and bundled plugins now have usage information
 * Default ports for ActiveMQ and RabbitMQ have changed to 61613
 * Data returned by data plugins are pre-populated with defaults from the DDL
 * Direct addressing is now enabled by default
 * Argument validation in the rpc application now happens before discovery to provide more timely user feedback
 * Improved error handling and error messages
 * Remove the topicprefix, queueprefix, rpchelptemplate, helptemplatedir, plugin.discovery.timeout and topicsep configuration options
 * Certain paths have more platform appropriate defaults on Windows
 * Filter methods on the RPC client are now idempotent

### Bug Fixes

 * Correctly handle discovery where data plugins return nil for a specific item
 * The flatfile discovery method validates identities found using the same rules as the config class
 * The Util#versioncmp function behaves correctly with semver versions where the minor is larger than 10
 * Debian packages will now build correctly in a chroot
 * The run() agent helper could sometimes return -1 and leave zombies, this has been improved
 * Certain operations on a reply data item in an agent could alter the cached copy of the DDL thus affecting future agent invocations
 * Absolute paths on Windows are detected correctly
 * Line numbers are printed correctly in logs on Windows machines
 * Whitespace before config keys in the config file are now ignored

### Backwards Compatibility and Upgrading

In release 2.3.1 we removed the Stomp connector, in this release we are removing a number of unused
configuration options that was used by this connector and a few others that has become pointless over
the years.

If you have any of the following in your configuration files you must remove them *before* upgrading
as the daemon and client will fail to start if any of them are present:

  * topicprefix
  * queueprefix
  * rpchelptemplate
  * helptemplatedir
  * plugin.discovery.timeout
  * topicsep

If you have in the past not configured the port for the ActiveMQ and RabbitMQ connectors the default
would have been 6163, this has now changed to 61613 to be more in line with what other projects default
to.  This means if you rely on the defaulting behaviour you might now have to specifically state the
ports.  We recommend always stating ports specifically.

### Changes since 2.2.3

|Date|Description|Ticket|
|----|-----------|------|
|2013/07/03|Improve error reporting when requesting docs for a non existing plugin|21429|
|2013/07/03|Support aggregate plugins in 'mco plugin doc'|18414|
|2013/07/03|Allow the ActiveMQ and RabbitMQ SSL cert paths to be set using environment variables|20550|
|2013/06/23|Gracefully handle whitespaces in the config file before config keys|21407|
|2013/06/19|Ensure the line numbers are printed correctly on both Windows and Unix|20506|
|2013/06/19|Remove the rpchelptemplate and helptemplatedir options|20714|
|2013/06/18|Correctly detect Windows absolute paths|21251|
|2013/06/10|Fix and centralize handling of boolean values for settings|19751|
|2013/06/06|Clone the default values from the DDL to avoid accidental modifications to the cached DDL file|21104|
|2013/06/05|Filter methods on the RPC Client are now idempotent|20233|
|2013/06/04|run() call in an agent can return incorrect Process::Status|17667|
|2013/06/03|Improve debian dependencies so packages can be rebuilt in a chroot|20950|
|2013/05/28|Set expire headers in the ActiveMQ and RabbitMQ message headers|19905|
|2013/05/10|Correctly detect version differences in semver version where the path level is greater 10|20661|
|2013/05/01|Improve behaviour of data matchers when return values are nil|20059|
|2013/04/29|Improve config defaults on windows machines|20388|
|2013/04/18|Enforce valid identity names in the file discovery method|20282|
|2013/04/11|Add direct addressing awareness to the fire and forget request mode|17930|
|2013/03/22|Remove the topicprefix, queueprefix and topicsep options|19673|
|2013/03/21|Remove the plugin.discovery.timeout setting as it's not relevant anymore|19694|
|2013/03/21|Improve error reporting from the rpc application in the light of direct_addressing|19827|
|2013/03/20|Fail with a friendly error message when no libdir is set|19752|
|2013/03/14|Change default RabbitMQ and ActiveMQ ports to 61613|19734|
|2013/03/13|Set correct reply-to headers in the RabbitMQ connector|17034|
|2013/03/12|Pre-populate the data from data plugins like agent replies|19564|
|2013/03/12|Explicitly include StringIO|19367|
|2013/03/12|Enable direct addressing by default|19665|
|2013/02/20|Fix error code collision on PLMC18|19366|
|2013/02/15|Validate arguments supplied to the RPC application and raise errors sooner|19181|

<a name="2_2_4">&nbsp;</a>

## 2.2.4 - 2013/05/21

This is a maintenance release to the current production series of MCollective.
This release is a bug fix only release.

### Bug Fixes

 * A work around for a API behaviour change in the latest JSON gem have been added
 * Configuration defaults on MS Windows have been improved
 * The correct reply-to headers are now set by the RabbitMQ connector allowing async communication modes
 * The StringIO library is now specifically required to avoid a case where the client library would fail when a non YAML fact source is set on the client
 * The Util#versioncmp function incorrectly compared semver versions with high minor versions

### Backwards Compatibility and Upgrading

This release should be 100% backwards compatible with 2.2.0, 2.2.1, 2.2.2 and 2.2.3, when upgrading
from earlier releases please review the Release notes for 2.0.0.

### Changes since 2.2.3

|Date|Description|Ticket|
|----|-----------|------|
|2013/05/10|Correctly detect version differences in semver version where the path level is greater 10|20661|
|2013/05/07|Support the latest version of the JSON gem|20594|
|2013/04/29|Improve config defaults on windows machines|20388|
|2013/03/13|Set correct reply-to headers in the RabbitMQ connector|17034|
|2013/03/12|Explicitly include StringIO|19367|

<a name="2_3_1">&nbsp;</a>

## 2.3.1 - 2013/02/14

This is the second release in the new development series of MCollective.  This
release features enhancements and bug fixes.

This release is for early adopters, production users should consider the 2.2.x
series.

### New Features and Improvements

 * Initial work towards online help, improved logging and internationalization
 * The output from `--help` has been made clearer
 * The output of a failed reply in the default `printrpc` method has been improved

### Bug Fixes

 * The vendored JSON gem was updated to version 1.5.5 due to CVE-2013-0269
 * The RPC client inadvertently lost the ability to set discovery_timeout, this has been restored
 * Plugins with underscores in their name were not packagable on Debian, we now change underscores to dashes
 * The STOMP connector will not be maintained further and has been removed
 * A config file reading race condition were fixed, we no longer attempt to use config details before parsing the config file thus always using defaults.
 * Dependencies on packaged plugins have been made more specific to ensure updates work correctly
 * When an argument to the rpc application fails to parse the command will fail instead of continue with unexpected side effects
 * Processing of `--no-response` was broken in 2.3.0, this has been fixed

### Removed Functionality

 * The STOMP adapter has been deprecated and removed

### Online Help and Internationalization

Starting in this release a number of errors and messages will start showing error codes along
with the error text and we have a method for obtaining detailed information about each coded
message.

An example log line can be seen here:

{% highlight console %}
puppetd.rb:26 PLMC34: setting meta data in agents have been deprecated, DDL files are now being used for this information. Please update the 'puppetd.rb' agent
{% endhighlight %}

And an example CLI error string:

{% highlight console %}
% mco rpc rpcutil get_fact

The rpc application failed to run: PLMC30: Action 'get_fact' needs a 'fact' argument

Use the 'mco doc PLMC30' command for details about this error, use -v for full error backtrace details
{% endhighlight %}

You can now use the `mco doc PLMC30` command to get additional information about this error
and any other error code you might see.

Only a small number of errors and log lines have been updated for the new system and
we will soon publish web versions of these help documents too which should help when
searching for resolution to common errors.

### Backwards Compatibility and Upgrading

The STOMP connector has been removed, if you are using it please move to the RabbitMQ
or ActiveMQ one before upgrading.  Especially if you use Debian which would avoid the
package upgrading from failing

### Changes since 2.3.0

|Date|Description|Ticket|
|----|-----------|------|
|*2013/02/14*|*Release 2.3.1*|19265|
|2013/02/14|Initial work towards internationalization and online help|18663|
|2013/02/14|Update vendored JSON gem for CVE-2013-0269|19265|
|2013/02/13|Restore the ability to set a discovery timeout on a RPC client|19238|
|2013/02/12|Replace underscores in plugin names with dashes to keep Debian happy|19200|
|2013/02/12|Fix package building on certain Debian systems|19141|
|2013/02/12|Remove the stomp connector|19146|
|2013/02/07|Read the client config before trying to use any configuration options|19105|
|2013/01/22|When an argument fails to parse in the rpc application fail rather than continue with unintended consequences|18773|
|2013/01/22|The fix the *--no-response* argument to the rpc application that broke due to 18438|18513|
|2013/01/22|Set *=* dependencies on the various packages that form a plugin rather than *>=*|18758|
|2013/01/21|Improve presentation of the --help output for applications|18447|
|2013/01/21|When a request failed via *reply.fail*, only show the message and not the half built data|18434|

<a name="2_2_3">&nbsp;</a>

## 2.2.3 - 2013/02/14

This is a maintenance release to the current production version of MCollective.
This release is a bug fix only release.

### Bug Fixes

 * The vendored JSON gem was updated to version 1.5.5 due to CVE-2013-0269
 * The RPC client inadvertently lost the ability to set discovery_timeout, this has been restored
 * Plugins with underscores in their name were not packagable on Debian, we now change underscores to dashes
 * The STOMP adapter will not be maintained past this release series, we now issue deprecation warnigns
 * A config file reading race condition were fixed, we no longer attempt to use config details before parsing the config file thus always using defaults.
 * Dependencies on packaged plugins have been made more specific to ensure updates work correctly

### Backwards Compatibility and Upgrading

This release should be 100% backwards compatible with 2.2.0, 2.2.1 and 2.2.2, when upgrading
from earlier releases please review the Release notes for 2.0.0.

If you packaged any plugins with a underscore in their name, future packages will have a dash
instead, this might cause upgrade problems.

We are deprecating the STOMP connector, if you are using this connector please consider moving to the
ActiveMQ or RabbitMQ specific ones.

### Changes since 2.2.2

|Date|Description|Ticket|
|----|-----------|------|
|*2013/02/14*|*Release 2.2.3*|19265|
|2013/02/14|Update vendored JSON gem for CVE-2013-0269|19265|
|2013/02/13|Restore the ability to set a discovery timeout on a RPC client|19238|
|2013/02/12|Replace underscores in plugin names with dashes to keep Debian happy|19200|
|2013/02/12|Fix package building on certain Debian systems|19141|
|2013/02/12|Deprecate the stomp connector|19146|
|2013/02/07|Read the client config before trying to use any configuration options|19105|
|2013/01/22|Set `=` dependencies on the various packages that form a plugin rather than `>=`|18758|

<a name="2_0_1">&nbsp;</a>

## 2.0.1 - 2013/02/14

This is a maintenance release against our unsupported past production release, it brings no
visible changes or bug fixes we only updated the vendored JSON gem to version 1.5.5 due to
CVE-2013-0269

<a name="2_2_2">&nbsp;</a>

## 2.2.2 - 2013/01/17

This is a maintenance release to the current production version of MCollective.
This release is a bug fix only release.

### Bug Fixes

 * Add the package iteration number as dependency for common packages
 * The :any validator has been restored
 * Packaging non-agent plugins failed when providing custom paths
 * Packaging on RHEL5 systems failed due to an undefined buildroot
 * When available packages will be built using rpmbuild-md5
 * Help for data plugins with no input queries are now rendered correctly
 * The rpcutil#get_data action now supports data plugins without input queries
 * The RPM packages will now require Ruby > 1.8 to improve packaging for 1.9.x

### Backwards Compatibility and Upgrading

This release should be 100% backwards compatible with 2.2.0 and 2.2.1, when upgrading
from earlier releases please review the Release notes for 2.0.0.

### Changes since 2.2.1

|Date|Description|Ticket|
|----|-----------|------|
|*2013/02/17*|*Release 2.2.2*|18258|
|2013/01/03|Add the package iteration number as a dependency for the common packages|18273|
|2012/12/24|Restore the :any validator|18265|
|2012/12/19|Do not fail when packaging non-agent packages using custom paths|17281|
|2012/12/19|Require Ruby > 1.8 in the RPM specs for Ruby 1.9|17149|
|2012/11/08|Define a specific buildroot to support RHEL5 systems correctly|17516|
|2012/11/08|Use the correct rpmbuild commands on systems with rpmbuild-md5|17515|
|2012/10/22|Correctly show help for data plugins without any input queries|17137|
|2012/10/22|Allow the rpcutil#get_data action to work with data queries that takes no input|17138|

<a name="2_3_0">&nbsp;</a>

## 2.3.0 - 2012/01/10

This is the first release in the new development series of MCollective.  This
release features small enhancements and bug fixes.

This release is for early adopters, production users should consider the 2.2.x
series.

### Enhancements and behaviour changes

 * Data queries can be written without any input queries
 * Required inputs can now supply default values in their DDLs
 * Support for Ruby 1.9 was improved in the packages
 * The generated plugin documentation has been updated to show defaults and optional items
 * Errors in agents will now log backtraces on the servers to assist with debugging
 * libdirs will now be expanded to absolute paths and using relative ones will raise an error
 * Various error and logging improvements
 * Various improvements to the plugin packager

### Bug fixes

 * Packaging non-agent plugins with custom paths caused an unexpected failure
 * The plugin packager works correctly on RHEL5 now after previously using an incorrect buildroot
 * Correctly handle custom formats passed to the aggregation plugins from the DDL
 * Failure in one aggregate plugin does not impact other aggregate functions
 * The chosen timeout for agents when using direct addressing could be wrong in some cases
 * Data plugins can now return BigNum data like those found in timestamps
 * Aggregate functions support non string data
 * Boolean flags in applications can now support --noop and --no-noop style flags
 * Data results were not raising the correct exception, this was not causing problems in practice but caused the mcollective-test gem to fail

### Input defaults in the DDL

You can now provide input defaults for required inputs in the DDL meaning if not
supplied they will default to the supplied format.

{% highlight ruby %}
action "get_fact", :description => "Retrieve a single fact from the fact store" do
     input :fact,
           :prompt      => "The name of the fact",
           :description => "The fact to retrieve",
           :type        => :string,
           :validation  => '^[\w\-\.]+$',
           :optional    => false,
           :maxlength   => 40,
           :default     => "operatingsystems"
end
{% endhighlight %}

The DDL file above defines a input *fact* that is required and sets a default value to
*operatingsystem*.

Previously the following command would have failed stating the input is required, now it
will default to the supplied value and continue without error:

{% highlight ruby %}
$ mco rpc rpcutil get_fact
{% endhighlight %}

The defaults processing is done on the client side and not on the servers meaning at no
point does a non compliant request get published by the clients and older MCollective servers
will process these requests correctly.

### Backwards Compatibility and Upgrading

This release can cohabit with older versions with the only potential upgrade problem being
the changes to how the libdir variable is handled.

In the past a libdir could be:

{% highlight ini %}
libdir = /usr/libexec/mcollective:.mcollective.d
{% endhighlight %}

This would have the effect of looking for *.mcollective.d* in the current directory.

This represented a security risk and would fail on the server side when daemonizing.
We now force all libdir paths to be fully qualified and raises an error at start should
you have relative paths.

### Changes since 2.2.1

|Date|Description|Ticket|
|----|-----------|------|
|2012/01/10|Raise the correct exception when trying to access unknown data items in a Data results|18466|
|2013/01/10|Fix failing documentation generation for data plugins|18437|
|2013/01/09|Correctly support negative boolean flags declared as --[no]-foo|18438|
|2013/01/03|Add the package iteration number as a dependency for the common packages|18273|
|2012/12/21|The libdirs supplied in the config file now has to be absolute paths to avoid issues when daemonising|16018|
|2012/12/20|Logs the error and backtrace when an action fails|16414|
|2012/12/20|Display the values of :optional and :default in DDL generated help|16616|
|2012/12/20|Allow the query string for the get_data action in rpcutil to be 200 chars|18200|
|2012/12/19|Do not fail when packaging non-agent packages using custom paths|17281|
|2012/12/19|Require Ruby > 1.8 in the RPM specs for Ruby 1.9|17149|
|2012/12/18|Allow required inputs to specify default data in DDLs|17615|
|2012/11/12|When disconnecting set the connection to nil|17384|
|2012/11/08|Define a specific buildroot to support RHEL5 systems correctly|17516|
|2012/11/08|Use the correct rpmbuild commands on systems with rpmbuild-md5|17515|
|2012/10/22|Correctly show help for data plugins without any input queries|17137|
|2012/10/22|Allow the rpcutil#get_data action to work with data queries that takes no input|17138|
|2012/10/03|Improve text output when providing custom formats for aggregations|16735|
|2012/10/03|Correctly process supplied formats when displaying aggregate results|16415|
|2012/10/03|Prevent one failing aggregate function from impacting others|16411|
|2012/10/03|When validation fails indicate which input key has the problem|16617|
|2012/09/26|Data queries can be written without any input queries meaning they take no input|16424|
|2012/09/26|Use correct timeout for agent requests when using direct addressing|16569|
|2012/09/26|Allow BigNum data to be used in data plugin replies|16503|
|2012/09/26|Support non string data in the summary aggregate function|16410|


<a name="2_2_1">&nbsp;</a>

## 2.2.1 - 2012/10/17

This is a maintenance release to the current production version of MCollective.
This release is a bug fix only release.

### Bug Fixes

 * Various display and stability improvements with aggregate plugins
 * Improve error messages
 * Data queries that does not take an input still had to provide a bogus query input, now not needed
 * When using direct addressing and identity filter the client timeout was incorrect
 * BigNum type data can now be used in data plugin replies

### Backwards Compatibility and Upgrading

This release should be 100% backwards compatible with 2.2.0, when upgrading from earlier releases
pleas reivew the Release notes for 2.0.0.

### Changes since 2.1.0

|Date|Description|Ticket|
|----|-----------|------|
|*2012/10/17*|*Release 2.2.1*|16965|
|2012/10/03|Improve text output when providing custom formats for aggregations|16735|
|2012/10/03|Correctly process supplied formats when displaying aggregate results|16415|
|2012/10/03|Prevent one failing aggregate function from impacting others|16411|
|2012/10/03|When validation fails indicate which input key has the problem|16617|
|2012/09/26|Data queries can be written without any input queries meaning they take no input|16424|
|2012/09/26|Use correct timeout for agent requests when using direct addressing|16569|
|2012/09/26|Allow BigNum data to be used in data plugin replies|16503|
|2012/09/26|Support non string data in the summary aggregate function|16410|
|2012/09/14|Package discovery plugins that was left out for debian|16413|

<a name="2_2_0">&nbsp;</a>

## 2.2.0 - 2012/09/13

This is the next production release of MCollective. It brings to an end active
support for versions 2.1.1 and older.

### Major Enhancements

 * A new plugin type called data plugins were added making network discovery extendible by users
 * Discovery is now pluggable allowing network based, database based, file based or any other data source to be used as a source of truth
 * Automatic result summarization methods can be declared in the DDL and users can write their own
 * A RabbitMQ specific Direct Addressing capable connector was added
 * Agent DDLs must be present on the servers, input validation is done against the DDL and prior to running user code
 * DDL files can define default values for returned data - all declared data fields are pre-populated by agents
 * DDL files can store general usage information that gets rendered via the help application
 * DDL files can declare the minimum version mcollective they need to be functional and loading plugins on older mcollective versions will fail
 * New validation logic in DDL files and Agents can now be delivered using plugins
 * A thread safe caching system was added that users can use in their Agents to store information between invocations
 * Code generators to assist writing agents
 * Support deterministic random node selection
 * Display mode can be overriden on the CLI using the new *--display* option
 * The plugin packager will now keep source debs and rpms and has had major improvements done
 * A new application called *completion* was added to assist in writing shell completion systems. ZSH and Bash examples are in *ext/*
 * Various improvements to documentation was made especially around using the CLI tools and discovery available plugins

### Bug Fixes

 * The vendored systemu gem has been updated to remove a rude error message
 * Improved error reporting in many areas
 * Boolean and numeric data is correctly parsed on the RPC application command line
 * Improved parsing of compound filters
 * Batched requests will now all have the same request id thus improving consistency of auditing information

### Deprecations

 * Remove the traditional Client#discovered_req method
 * The metadata section in the agent is being removed as the DDL is now present everywhere

### Data Plugins

A new plugin type called _data plugins_ have been added, these plugins are
usable in discovery requests and in any agent code.

You can use these plugins to expose any node side data to your client discovery
command line, an example can be seen below, this will discover all nodes where
_/etc/syslog.conf_ has a md5 sum matching the regular expression _/19ff4997e/_:

{% highlight console %}
$ mco rpc rpcutil ping -S "fstat('/etc/rsyslog.conf').md5 = /19ff4997e/"
{% endhighlight %}

For full information see the plugins documentation on our website. The _fstat_
plugin seen above is included at the moment, more will be added in due course
but as always users can also write their own suitable to their needs.

### Custom Discovery Sources

A new type of plugin that can be used as alternative data sources for discovery
data has been added. The traditional network broadcast mode is supported and
remains the default but a new flat file one was added.

Custom discovery sources can be made the default for a client using the
*default_discovery_method* configuration option but can be selected on the
command line using _--disc-method_.

All applications now have a _--nodes_ option that takes as an argument a flat
file full of mcollective identity names, one per line.

Users can write their own discovery plugins and distribute it using the normal
plugin packager. A complex example can be seen in the community plugin site
for the MongoDB registration plugin.

In the event that the _-S_ filter is used the network discovery mode will be
forced so that data source plugins in discovery queries will always work as
expected.

This feature requires Direct Addressing.

### DDL files on the servers

The DDL files now have to be on the servers and the clients. On the servers the
results will be pre-populated with default data for all defined output values of
a specific action and you can now supply defaults.

Additionally input will be validated on each node prior to running the agent
code providing consistent input validation on client and server.  This should
remove the need to add *validate* statements to agents.

An example for a Nagios plugin can be seen below, here we default to *UNKNOWN*
so that even if the action fails to run we will still see valid data being
returned thats appropriate for the specific use case.

{% highlight ruby %}
action "runcommand", :description => "Run a NRPE command" do
  output :exitcode,
         :description  => "Exit Code from the Nagios plugin",
         :display_as   => "Exit Code",
         :default      => 3
end
{% endhighlight %}

### Summarization Plugins

Often custom applications are written just to summarize data like the *facts*
application or *nrpe* ones.

We have added a new plugin type that allows you to define summarization logic
and included a few of our own.  These summaries are declared in the DDL, here is
a section from the new DDL for the *get_fact* action:

{% highlight ruby %}
action "get_fact", :description => "Retrieve a single fact from the fact store" do
  output :value,
          :description => "The value of the fact",
          :display_as => "Value"

  summarize do
    aggregate summary(:value)
  end
end
{% endhighlight %}

Here we are using the *summarize* block to say that we wish to summarize the
output *:value*.  The *summary(:value)* is the call to a custom plugin and you
can provide your own.

Now when interacting with this action you will see summaries produced
automatically:

{% highlight ruby %}
% mco rpc rpcutil get_fact fact=operatingsystemrelease
.
.
dev2
    Fact: operatingsystemrelease
   Value: 6.2


Summary of Value:

    6.2 = 19
    6.3 = 7

Finished processing 26 / 26 hosts in 294.97 ms
{% endhighlight %}

The last section of the rpc output shows the summarization in action.

The NRPE plugin on GitHub shows an example of a Nagios specific aggregation
function and the plugin packager supports distributing these plugins.

### Validation Plugins

Users can now write their own plugins to perform input validation, these
validations are usable in DDL files and agents.

Below is a snippet from a DDL file using a custom *exim_msgid* validation
plugin:

{% highlight ruby %}
    input :msgid,
          :prompt      => "Message ID",
          :description => "Valid message id currently in the mail queue",
          :type        => :string,
          :validation  => :exim_msgid,
          :optional    => false,
          :maxlength   => 16
{% endhighlight %}

And a snippet using the same plugin inside your agent:

{% highlight ruby %}
action "retrymsg" do
  validate :msgid, :exim_msgid

  # call out to exim to retry the message
end
{% endhighlight %}

The error messages shown when validation fails are more user friendly than
before, in this example the new error would be *Not a valid Exim Message ID*
where in the past it would have been *value should match ^(?:[+-]\d{4})?(?:\[\d+\] )?(\w{6}\-\w{6}\-\w{2})/*

### Code generation

Code for agents and data sources can now be generated to assist development, you
can use the _plugin_ command to create a basic skeleton agent or data source
including the DDL files.

{% highlight console %}
$ mco plugin generate agent myagent actions=do_something,do_something_else
{% endhighlight %}

Defaults used in the metadata templates can be set in the config file:

{% highlight ini %}
plugin.metadata.url=http://devco.net
plugin.metadata.author=R.I.Pienaar <rip@devco.net>
plugin.metadata.license=ASL2.0
plugin.metadata.version=0.0.1
{% endhighlight %}

All generator produced output will have these settings set, the other fields are
constructed using a pattern convenient for using in your editor as a template.

### Backwards Compatibility and Upgrading

As of this version every agent on every node and client must have a DDL file. If
the DDL file is not present or not valid the agent will not activate.  Further
input validation is done according to the content of the DDL prior to running
any actions.  You should therefore prepare for this upgrade by writing and
deploying DDL files for all your agents.

Version 2.0.0 and 2.2.0 can co-exist on the same network. If a new client uses
any of the new features added such as data plugins the older clients will simply
refuse to run the request but requests using features shared between versions
will continue to work.

When you first start this version of mcollectived you will see warnings logged
similar to the one below:

{% highlight ruby %}
puppetd.rb:26: setting meta data in agents have been deprecated, DDL files are now being used for this information.
{% endhighlight %}

This is only a warning and not a critical problem.  The next major release will
remove support for metadata in agents.

Upgrading from versions prior to 2.0.0 was not tested, please refer to the
release notes for 2.0.0.

<a name="2_1_1">&nbsp;</a>

## 2.1.1 - 2012/07/12

This release features major new features, enhancements and bug fixes.

This release is for early adopters, production users should consider the 2.0.x
series.

### Major Enhancements

 * A new discovery source was added capable of querying agent properties
 * When doing limited discovery you can now supply a random seed for deterministic random selection
 * A *get_data* action has been added to the *rpcutil* agent to retrieve the result of a data plugin
 * RPC Agents must have DDLs on the MCollective Servers, agents will not load without them
 * Output values can now have defaults assigned in the DDL, the server will set those defaults before running an action
 * A new plugin type used to summarize sets of replies has been added. Summarization is declared in the DDL for an Agent

### Bug Fixes

 * Correctly parse numeric and boolean input arguments in the RPC application

### Deprecations

 * The old *Client#discovered_req* is removed along with the *controller* application that used it
 * Parsing compound filters were improved wrt complex regular expressions
 * Metadata sections in agents are not needed anymore and deprecation notices are logged when they are found

### Summarization Plugins

Often custom applications are written just to summarize data like the *facts*
application or *nrpe* ones.

We have added a new plugin type that allows you to define summarization logic
and included a few of our own.  These summaries are declared in the DDL, here is
a section from the new DDL for the *get_fact* action:

{% highlight ruby %}
action "get_fact", :description => "Retrieve a single fact from the fact store" do
  output :value,
          :description => "The value of the fact",
          :display_as => "Value"

  summarize do
    aggregate summary(:value)
  end
end
{% endhighlight %}

Here we are using the *summarize* block to say that we wish to summarize the
output *:value*.  The *summary(:value)* is the call to a custom plugin and you
can provide your own.

Now when interacting with this action you will see summaries produced
automatically:

{% highlight ruby %}
% mco rpc rpcutil get_fact fact=operatingsystemrelease
.
.
dev2
    Fact: operatingsystemrelease
   Value: 6.2


Summary of Value:

    6.2 = 19
    6.3 = 7

Finished processing 26 / 26 hosts in 294.97 ms
{% endhighlight %}

The last section of the rpc output shows the summarization in action.

The NRPE plugin on GitHub shows an example of a Nagios specific aggregation
function and the plugin packager supports distributing these plugins.

### DDL files on the servers

The DDL files now have to be on the servers and the clients.  On the servers the
results will be pre-populated with default data for all defined output values of
a specific action and you can now supply defaults.

An example for a Nagios plugin can be seen below, here we default to *UNKNOWN*
so that even if the action fails to run we will still see valid data being
returned thats appropriate for the specific use case.

{% highlight ruby %}
action "runcommand", :description => "Run a NRPE command" do
  output :exitcode,
         :description  => "Exit Code from the Nagios plugin",
         :display_as   => "Exit Code",
         :default      => 3
end
{% endhighlight %}

As the servers now have the DDL the *metadata* section at the top of agents are
not needed anymore and deprecations will be logged when the mcollectived starts
up warning you of this.

### Backwards Compatibility and Upgrading

As this release now requires DDL files to exist before an agent can be loaded in
the server you might have to adjust your deployment strategy and possibly write
some DDLs for your custom agents.  The DDL files have to be on both client and
servers.

The servers will now pre-populate the replies with all output defined in the DDL
and supply defaults if no default is provided in the DDL it will default to nil.
This might potentially change the behavior of custom applications that are
designed around the approach of checking if a field is included in the results
or not.

When you first start this version of mcollectived you will see warnings logged
similar to the one below:

{% highlight ruby %}
puppetd.rb:26: setting meta data in agents have been deprecated, DDL files are now being used for this information.
{% endhighlight %}

This is only a warning and not a critical problem.  Once 2.2.0 is out we will be
updating all the agents to remove metadata sections in favour of those in the DDL.
You should also remove metadata from your own agents.

### Changes since 2.1.0

|Date|Description|Ticket|
|----|-----------|------|
|2012/07/11|Add a --display option to RPC clients that overrides the DDL display mode|15273|
|2012/07/10|Do not add a metadata to agents created with the generator as they are now deprecated|15445|
|2012/07/03|Correctly parse numeric and boolean data on the CLI in the rpc application|15344|
|2012/07/03|Fix a bug related to parsing regular expressions in compound statements|15323|
|2012/07/02|Update vim snippets in ext for new DDL features|15273|
|2012/06/29|Create a common package for agent packages containing the DDL for servers and clients|15268|
|2012/06/28|Improve parsing of compound filters where the first argument is a class|15271|
|2012/06/28|Add the ability to declare automatic result summarization in the DDL files for agents|15031|
|2012/06/26|Surpress subscribing to reply queues when no reply is expected|15226|
|2012/06/25|Batched RPC requests will now all have the same requestid|15195|
|2012/06/25|Record the request id on M::Client and in the RPC client stats|15194|
|2012/06/24|Use UUIDs for the request id rather than our own weak implementation|15191|
|2012/06/18|The DDL can now define defaults for outputs and the RPC replies are pre-populated|15087|
|2012/06/18|Remove unused agent help code|15084|
|2012/06/18|Remove unused code from the *discovery* agent related to inventory and facts|15083|
|2012/06/18|Nodes will now refuse to load RPC agents without DDL files|15082|
|2012/06/18|The Plugin Name and Type is now available to DDL objects|15076|
|2012/06/15|Add a get_data action to the rpcutil agent that can retrieve data from data plugins|15057|
|2012/06/14|Allow the random selection of nodes to be deterministic|14960|
|2012/06/12|Remove the Client#discovered_req method and add warnings to the documentation about its use|14777|
|2012/06/11|Add a discovery source capable of doing introspection on running agents|14945|
|2012/06/11|Only do identity filter optimisations for the *mc* discovery source|14942|

<a name="2_1_0">&nbsp;</a>

## 2.1.0 - 2012/06/08

This is the first release in the new development series of MCollective.  This
releas features major new features and enhancements.

This release is for early adopters, production users should consider the 2.0.x
series.

### Major Enhancements

 * Discovery requests can now run custom data plugins on nodes to facilitate discovery against any node-side data
 * Discovery sources are now pluggable, one supporting flat files are included in this release
 * All applications now have a --nodes option to read a text file of identities to operate on
 * A new _completion_ application was added to assist with shell completion systems, zsh and bash tab completion plugins are in ext
 * Users can now use a generator to create skeleton agents and data sources

### Changes in behavior

 * The _mco controller_ application is being deprecated for the next major release and has now been removed from the development series
 * The _mco find_ application is now a discovery client so it's output mode has changed slightly but the functionality stays the same

### Bug Fixes

 * Numerous small improvement to user facing errors and status outputs have been made
 * Sub collectives combined with direct addressing has been fixed
 * Various packaging issues were resolved
 * The ActiveMQ and Stomp connectors will now by default handle dual homed IPv6 and IPv4 hosts better in cases where the IPv6 target isn't reachable

### Data Plugins

A new plugin type called _data plugins_ have been added, these plugins are
usable in discovery requests and in any agent code.

You can use these plugins to expose any node side data to your client discovery
command line, an example can be seen below, this will discover all nodes where
_/etc/syslog.conf_ has a md5 sum matching the regular expression
_/19ff4997e/_:

{% highlight console %}
$ mco rpc rpcutil ping -S "fstat('/etc/rsyslog.conf').md5 = /19ff4997e/"
{% endhighlight %}

For full information see the plugins documentation on our website. The _fstat_
plugin seen above is included at the moment, more will be added in due course
but as always users can also write their own suitable to their needs.

### Custom Discovery Sources

Since the introduction of direct addressing mode in 2.0.0 you've been able to
pragmatically specify arbitrary host lists as discovery data but this was never
exposed to the user interface.

We now introduce plugins that can be used as alternative data sources and
include the traditional network broadcast mode and a flat file one.  The hope
is that more will be added in future perhaps integrating with systems like
PuppetDB.  There is also one that uses the MongoDB Registration plugin to build
a local node cache.

Custom discovery sources can be made the default for a client using the
*default_discovery_method* configuration option but can be selected on the
command line using _--disc-method_.

All applications now have a _--nodes_ option that takes as an argument a flat
file full of mcollective identity names, one per line.

Users can write their own discovery plugins and distribute it using the normal
plugin packager.

In the event that the _-S_ filter is used the network discovery mode will be
forced so that data source plugins in discovery queries will always work as
expected.

### Code generation

Code for agents and data sources can now be generated to assist development,
you can use the _plugin_ command to create a basic skeleton agent or data source
including the DDL files.

{% highlight console %}
$ mco plugin generate agent myagent actions=do_something,do_something_else
{% endhighlight %}

Defaults used in the metadata templates can be set in the config file:

{% highlight ini %}
plugin.metadata.url=http://devco.net
plugin.metadata.author=R.I.Pienaar <rip@devco.net>
plugin.metadata.license=ASL2.0
plugin.metadata.version=0.0.1
{% endhighlight %}

All generator produced output will have these settings set, the other fields
are constructed using a pattern convenient for using in your editor as a
template.

### Backwards Compatibility and Upgrading

This release can co-exist with 2.0.0 but using the new discovery data plugins in a
mixed environment will result in the old nodes not being discovered and they will
log exceptions in their logs.  This was done by choice and ensures the safest
possible upgrade path.

When the 2.0.0 collective is running with directed mode enabled a client using the
new discovery plugins will be able to communicate wth the older nodes without
problem.

### Changes since 2.0.0

|Date|Description|Ticket|
|----|-----------|------|
|2012/06/07|Force discovery state to be reset when changing collectives in the RPC client|14874|
|2012/06/07|Create code generators for agents and data plugins|14717|
|2012/06/07|Fix the _No response from_ report to be correctly formatted|14868|
|2012/06/07|Sub collectives and direct addressing mode now works correctly|14668|
|2012/06/07|The discovery method is now pluggable, included is one supporting flat files|14255|
|2012/05/28|Add an application to assist shell completion systems with bash and zsh completion plugins|14196|
|2012/05/22|Improve error messages from the packager when a DDL file cannot be found|14595|
|2012/05/17|Add a dependency on stomp to the rubygem|14300|
|2012/05/17|Adjust the ActiveMQ and Stomp connect_timeout to allow IPv4 fall back to happen in dual homed hosts|14496|
|2012/05/16|Add a plugable data source usable in discovery and other plugins|14254|
|2012/05/04|Improve version dependencies and upgrade experience of debian packages|14277|
|2012/05/03|Add the ability for the DDL to load DDL files from any plugin type|14293|
|2012/05/03|Rename the MCollective::RPC::DDL to MCollective::DDL to match its larger role in all plugins|14254|

<a name="2_0_0">&nbsp;</a>

## 2.0.0 - 2012/04/30

This is the next production release of MCollective.  It brings to an
end active support for versions 1.3.3 and older.

This release brings to general availability all the features added in the
1.3.x development series.

### Major Enhancements

 * Complete messaging protocol rewrite to enable direct style connectivity that would allow programs to bypass normal discovery instead using their own data sources
 * An additional more robust messaging paradigm supporting a more assured addressing and delivery scheme
 * Batched mode allowing users to address machines in small groups thus avoiding thundering herd and enabling more granular changes
 * A more complete language for expressing discovery that includes and/or/not style queries across the infrastructure
 * Improved Stomp connection security using normal industry standard Certificate Authority validated TLS
 * New connector that uses ActiveMQ specific features for better performance and scalability
 * Security of the SSL and AES security plugins have been improved for tamper protection by middle men
 * A message validity period has been introduced to lower the window of message replay attacks
 * Better error handling and better logging for Stomp connections
 * JSON output from the 'rpc' application
 * Ability to pipe RPC requests into each other creating a chain of related RPC calls
 * Better validations, better error handling and better documentation creation from the DDL
 * Performance improvements in the CLI, more consistently formatted output of received data
 * A Ruby GEM of the client is now made available on rubygems.org
 * The rc script for Debian based systems have been improved to prevent duplicate daemons from running
 * Built in packager for plugins into native OS packages - RedHat and Debian supported
 * MS Windows Support

### Point to Point comms

Previously MCollective could only broadcast messages and was tied to a discovery model.

The messaging layer now supports per node destinations that allows you to address a node, even if its down,
doesn't yet exist or if you cannot come up with a filter that would match a group of arbitrarily selected
nodes.

When this mode is in use the user configure which machine to communicate with using either text, arrays or
JSON data.  It will then communicate directly to those nodes via the middleware and if any of them are down
you will get the usual no responses report after DDL configured timeout, this is a smooth transparent to the
end user mix in communication modes.

It is ideal for building deployers, web apps and so forth where you know exactly which nodes should be there
and you'd like to influence the MCollective network addressing, perhaps from a CMDB you built yourself.

This is the start towards an assured style of delivery, you can consider it the TCP to MCollective's UDP.
Both modes of communication will be supported in the future and both will have access to all the same agents
and clients.

This is feature is enabled using the *direct_addressing* configuration option. At present only the new
ActiveMQ connector supports this at scale.  The ActiveMQ connector is now the recommended standard connector
combined with Apache ActiveMQ.  More brokers could be supported in future.

### Pluggable / Optional Discovery

If the user did _mco rpc rpcutil ping -I box.example.com -I another.example.com_ mcollective will now just
assume you know what she wants, it won't do a discover to confirm those machines exist or not, it will just go
and communicate with them.  This is a big end user visible speed improvement.  If however you did a filter
like *-I /example.com/* mcollective cannot know which machines you want to reach and so a traditional
broadcast discovery is done first.

When the direct addressing mode is enabled various behind the scenes optimizations are being done:

 * If a discovery is done and it finds you only want to address 10 or fewer nodes it will use direct mode for that
   request.  This avoids a second needless broadcast.  This is less efficient to the middleware but does not send
   needless messages to uninterested nodes that would then just ignore them.
 * The _rpc_ application supports piping output from one to the next.  Example of this below.

{% highlight console %}
$ mco rpc package update package=foo -W customer=acme -j|mco rpc service restart service=bar
{% endhighlight %}

This will update a package on machines matching *customer=foo* and then restart the service *bar* on those
machines.

The first request is doing traditional discovery based on the fact while the 2nd request is not doing
discovery at all, it uses the JSON output enabled by -j as discovery data and then restart the service on only
those machines.

These abilities are exposed in the SimpleRPC client API and you can write your own schemes, query your own
databases etc

### Batching

Often the speed of MCollective is a problem, you want to install a package on thousands of machines but your
APT or YUM server isn't up to the task.

You can now do batching of requests:

{% highlight console %}
$ mco package update myapp --batch 10 --batch-sleep 60
{% endhighlight %}

This performs the update as usual but only affecting machines in groups of 10 and sleeps for a minute between.

You can also access this functionality via the API please see the docs for usage.  Any existing script or
application should support this functionality without any code changes.

The results, error reporting, statistics reporting and so forth all stays consistent with non batched
behavior.

At any time you can interrupt the process and only the current group of machines will have been affected.

The batching requires a direct addressing capable collective as it is built using the new direct to node
communications and pluggable discovery features

### ActiveMQ specific connector

A new connector plugin has been added that is specific to ActiveMQ and is compatible with the new direct
addressing communication system.

You will need to change your ActiveMQ configuration to support this plugin, see the documentation for this
plugin and the examples in _ext/activemq_ have also been updated for the new plugin.

Anyone who use ActiveMQ is strongly recommended to use this plugin as it uses a few ActiveMQ specific
optimizations that can have a big performance enhancing effect on your collective.

### Packaging Agent plugins

Distributing agents has been a problem as they are just files that have limited meta data and attached.

We now support packaging agents into rpm or deb packages, your agent must have a DDL file for this to work:

{% highlight console %}
$ mco plugin package . --vendor "My Company"
Successfully built RPM 'mcollective-exim_ng-client-0.1-1.noarch.rpm'
Successfully built RPM 'mcollective-exim_ng-common-0.1-1.noarch.rpm'
Successfully built RPM 'mcollective-exim_ng-agent-0.1-1.noarch.rpm'
{% endhighlight %}

The packages will have meta data like Author, Version and so forth as per your DDL file.

Users can provide their own packaging implementations for other package managers or custom layouts using the
MCollective plugin system.

### Full verified CA

When using the new ActiveMQ specific connector combined with Stomp version 1.2.2 or newer you can get full CA
verified connection handling ensuring that only clients using signed certificates can connect to ActiveMQ.

The documentation for the ActiveMQ SSL setup now includes instructions on setting up ActiveMQ and your clients
using the built in Puppet CA but any CA could be used to manage these certificates.

This feature will work best when ActiveMQ 5.6.0 is released in a few weeks since there will then be a NIO+SSL
Stomp connector. The current SNAPSHOT release of ActiveMQ has this feature as well as the most recent Service
Pack release of the Fuse Message Broker.

### MS Windows Support

The MS Windows platform is now supported as both a client and a server.  The _ext/windows_ directory has some
helpers and read me documentation that has been confirmed to work but we have not yet completed packaging
ourselves so this is still a manual process.

Combined with Puppet 2.7.12 or newer the Package and Service agents can be used to manage Windows resources
using the same commands as those on Linux via mcollective.

### New Discovery Language

Previously dicovery was very limited, filters were simply run one after the other and you could not do
anything complex like a mix of OR and AND boolean logic.

A new compact discovery language was introduced perfect for use on the command line, an example below:

{% highlight console %}
$ mco find -S "((fqdn=/example.com/ or fqdn=/another.com/) or customer=acme) and apache and physicalprocessorcount>2"
{% endhighlight %}

The EBNF for this language can be seen below, it's available on the command line and the API

    compound = ["("] expression [")"] {["("] expression [")"]}
    expression = [!|not]statement ["and"|"or"] [!|not] statement
    char = A-Z | a-z | < | > | => | =< | _ | - |* | / { A-Z | a-z | < | > | => | =< | _ | - | * | / | }
    int = 0|1|2|3|4|5|6|7|8|9{|0|1|2|3|4|5|6|7|8|9|0}

### Backwards Compatibility and Upgrading

This release is not compatible with older versions. Client scripts and agents written for older versions will
continue to work but a network hosting both 2.0.0 clients and older one will effectively be split into 2
networks.  While planning your upgrade you should plan to have machines running the client for both versions
to retain full control during upgrade.  The upgrade is best done in an scheduled window where all machines are
updated together.

While upgrading you must ensure that the plugins that come with the release are updated at the same time as
the release.  Older security and connector plugins will not function with this release.  This also means if
you wrote your own connector or security plugin you will need to port these prior to upgrading.

Past this it should be a simple matter of updating using your operating systems package manager.

We recommend you switch to the new ActiveMQ based connector plugin away from the previous generic Stomp one as
this is the primary supported method of deployment and the generic Stomp one will be deprecated in future.
Additionally the Stomp connector does not support the new direct messaging communications mode.

In order to upgrade to the new ActiveMQ connector you will need to change your broker setup including ACLs,
transport connectors, message policies and inter broker connections.  Sample configuration files for single
and multi broker setups can be found in the Git repository or the tar file in _ext/activemq_

<a name="1_3_3">&nbsp;</a>

## 1.3.3 - 2012/04/05

This is a release in the development series of MCollective.  It feature major new features and bug fixes.

This release is for early adopters, production users should consider the 1.2.x series.

### Major Enhancements

 * The MS Windows platform is now supported, packaging is still outstanding
 * Agents can now be packaged to native OS packages using the new _mco plugin_ command
 * _mco help rpc_ now show the help for the rpc application, _mco plugin doc puppetd_ shows the help for the puppetd agent
 * Full CA verified Stomp is supported and documented between ActiveMQ and MCollective using Stomp > 1.2.2
 * Application exit codes have been standardized using a new _halt_ helper function
 * A new validator that allows users to check if a supplied value is one of a fixed list
 * The syslog facility can now be set in the configuration file
 * The client libraries are now available as a Ruby Gem
 * Batch mode can now be enabled and disabled at will in an application
 * The client config files now default to console based logging at warn level

### Bug Fixes

 * nil or empty results are correctly displayed by printrpc
 * Some exceptions under Ruby 1.9.3 when using run() related to nil exit code has been fixed
 * Various exceptions have been silence in inventory application, stomp plugin, rpc application and others
 * Previous SSL_read errors when using the Stomp+TLS configuration is now avoided on Ruby 1.8

### Packaging Agent plugins

Distributing agents has been a problem as they are just files that have limited meta data and attached.

We now support packaging agents into rpm or deb packages, your agent must have a DDL file
for this to work:

{% highlight console %}
$ mco plugin package . --vendor "My Company"
Successfully built RPM 'mcollective-exim_ng-client-0.1-1.noarch.rpm'
Successfully built RPM 'mcollective-exim_ng-common-0.1-1.noarch.rpm'
Successfully built RPM 'mcollective-exim_ng-agent-0.1-1.noarch.rpm'
{% endhighlight %}

The packages will have meta data like Author, Version and so forth as per your DDL file.

We support building all the main plugin types in this manner but need to restructure the plugins
repository to support this layout.

To use this you need to install the fpm gem, you must install 0.4.3 and not a newer version, we are
currently working on removing the fpm dependency as it's proven to be too unreliable to use.

Users can provide their own packaging implementations for other package managers or custom layouts
using the MCollective plugin system.

### Full verified CA

When using the new ActiveMQ specific connector combined with Stomp version 1.2.2 or newer you can
get full CA verified connection handling ensuring that only clients using signed certificates
can connect to ActiveMQ.

The documentation for the ActiveMQ SSL setup now includes instructions on setting up ActiveMQ and your
clients using the built in Puppet CA but any CA could be used to manage these certificates.

This feature will work best when ActiveMQ 5.6.0 is released in a few weeks since there will then be a NIO+SSL
Stomp connector. The current SNAPSHOT release of ActiveMQ has this feature as well as the most recent Service
Pack release of the Fuse Message Broker.

### MS Windows Support

The MS Windows platform is now supported as both a client and a server.  The _ext/windows_ directory
has some helpers and read me documentation that has been confirmed to work but we have not yet
completed packaging ourselves so this is still a manual process.

Combined with Puppet 2.7.12 or newer the Package and Service agents can be used to manage Windows
resources using the same commands as those on Linux via mcollective.

### Backwards compatibility

This release is backwards compatible with version 1.3.2, if you are coming from an older version please
review earlier release notes.

If you have been using the ActiveMQ specific plugin and its SSL settings you will now need to enable
fallback mode as it will now only connect to ActiveMQ machines that present the correct CA certificate
and will refuse to use anonymous certificates

{% highlight ini %}
plugin.activemq.pool.1.ssl.fallback = 1
{% endhighlight %}

### Changes since 1.3.2

|Date|Description|Ticket|
|----|-----------|------|
|2012/04/04|Use the MCollective::SSL utility class for crypto functions in the SSL security plugin|13615|
|2012/04/02|Support reading public keys from SSL Certificates as well as keys|13534|
|2012/04/02|Move the help template to the common package for both Debian and RedHat|13434|
|2012/03/30|Support Stomp 1.2.2 CA verified connection to ActiveMQ|10596|
|2012/03/27|_mco help rpc_ now shows the help for the rpc application|13350|
|2012/03/22|Add a mco command that creates native OS packaging for plugins|12597|
|2012/03/21|Default to console based logging at warning level for clients|13285|
|2012/03/20|Work around SSL_read errors when using SSL or AES plugins and Stomp+SSL in Ruby < 1.9.3|13207|
|2012/03/16|Improve logging for SSL connections when using Stomp Gem newer than 1.2.0|13165|
|2012/03/14|Simplify handling of signals like TERM and INT and remove pid file on exit|13105|
|2012/03/13|Create a conventional place to store implemented_by scripts|13064|
|2012/03/09|Handle exceptions added to the Stomp 1.1 compliant versions of the Stomp gem|13020|
|2012/03/09|Specifically enable reliable communications while using the pool style syntax|13040|
|2012/03/06|Initial support for the Windows Platform|12555|
|2012/03/05|Application plugins can now disable any of 3 sections of the standard CLI argument parsers|12859|
|2012/03/05|Fix base 64 encoding and decoding of message payloads that would previous raise unexpected exceptions|12950|
|2012/03/02|Treat :hosts and :nodes as equivalents when supplying discovery data, be more strict about flags discover will accept|12852|
|2012/03/02|Allow exit() to be used everywhere in application plugins, not just in the main method|12927|
|2012/03/02|Allow batch mode to be enabled and disabled on demand during the life of a client|12854|
|2012/02/29|Show the progress bar before sending any requests to give users feedback as soon as possible rather than after first result only|12865|
|2012/02/23|Do not log exceptions in the RPC application when a non existing action is called with request parameters|12719|
|2012/02/17|Log miscellaneous Stomp errors at error level rather than debug|12705|
|2012/02/17|Improve subscription tracking by using the subID feature of the Stomp gem and handle duplicate exceptions|12703|
|2012/02/15|Improve error handling in the inventory application for non responsive nodes|12638|
|2012/02/14|Comply to Red Hat guideline by not setting mcollective to start by default after RPM install|9453|
|2012/02/14|Allow building the client libraries as a gem|9383|
|2012/02/13|On Red Hat like systems read /etc/sysconfig/mcollective in the init script to allow modification of the environment|7441|
|2012/02/13|Make the handling of symlinks to the mco script more robust to handle directories with mc- in their name|6275|
|2012/02/01|systemu and therefore MC::Shell can sometimes return nil exit code, the run() method now handles this better by returning -1 exit status|12082|
|2012/01/27|Improve handling of discovery data on STDIN to avoid failures when run without a TTY and without supplying discovery data|12084|
|2012/01/25|Allow the syslog facility to be configured|12109|
|2012/01/13|Add a RPC agent validator to ensure input is one of list of known good values|11935|
|2012/01/09|The printrpc helper did not correctly display empty strings in received output|11012|
|2012/01/09|Add a halt method to the Application framework and standardize exit codes|11280|
|2011/11/21|Remove unintended dependency on _pp_ in the ActiveMQ plugin|10992|
|2011/11/17|Allow reply to destinations to be supplied on the command line or API|9847|


<a name="1_3_2">&nbsp;</a>

## 1.3.2 - 2011/11/17

This is a release in the development series of MCollective.  It feature major new features.

This release is for early adopters, production users should consider the 1.2.x series.

### Enhancements

 * Handling of syntax errors in Application plugins have been improved
 * The limit method can now be set per RPC Client instance
 * Optionally show response distribution in the _ping_ application with the _--graph_ option
 * Expose a statistic about expired messages via the _rpcutil_ agent and show them in the inventory application.
 * Remove all the _mc-_ scripts that has been ported to applications
 * AES and TTL security plugins prevent tampering with the TTL and Message Times
 * The RPC client can now raise an exception rather than exit on failure - ideal for use in web apps
 * Discovery during requests that has a specific limit count set have been sped up
 * Specific types for :number, :float and :integer has been aded to the DDL and the RPC application has special handling for them
 * Caller ID, Certificate Names and Identity Names can now only be word characters, full stop and dash
 * Security plugins are now quicker to ignore miss directed messages
 * The client now unsubscribes from topics it does not need anymore
 * SimpleRPC now supports performing actions in batches with a sleep between each batch
 * A direct request capable ActiveMQ specific plugin has been included
 * Message TTLs can be set globally in the config or in the API

### ActiveMQ specific connector

A new connector plugin has been added that is specific to ActiveMQ and is compatible
with the new direct addressing communication system.

You will need to change your ActiveMQ configuration to support this plugin, see the
documentation for this plugin and the examples in _ext/activemq_ have also been
updated for the new plugin.

Anyone who use ActiveMQ is strongly recommended to use this plugin as it uses a
few ActiveMQ specific optimizations that can have a big performance enhancing effect
on your collective.

### Batching

Often the speed of MCollective is a problem, you want to install a package on thousands
of machines but your APT or YUM server isn't up to the task.

You can now do batching of requests:

{% highlight console %}
$ mco package update myapp --batch 10 --batch-sleep 60
{% endhighlight %}

This performs the update as usual but only affecting machines in groups of 10 and
sleeps for a minute between.

You can also access this functionality via the API please see the docs for usage.
Any existing script or application should support this functionality without any
code changes.

The results, error reporting, statistics reporting and so forth all stays consistent
with non batched behavior.

The batching requires a direct addressing capable collective.

### Backwards Compatibility

As this release does a few more tweaks to the security system it might not work with older
versions of MCollective.

Hopefully this will be the last release in this dev cycle to break backwards compatibility
as we're nearing the next major release.

#### Identities, Certificates and Caller ID names

These items have been tightened up to only match _\w\.-_.  Plugins like the registration
ones might assume it is safe to just write files based on names contained in these fields
so rather than expect everyone to write secure code the framework now just enforce
a safe approach to these.

This means if you have cases that would violate this rule you would need to change that
configuration prior to upgrading to 1.3.2

#### AES and SSL plugins are more secure

If you use the AES or SSL plugins you will need to plan your rollout carefully, these plugins
are not capable of communicating with older versions of MCollective.

#### Changes since 1.3.1

|Date|Description|Ticket|
|----|-----------|------|
|2011/11/16|Imrpove error reporting for code errors in application plugins|10883|
|2011/11/15|The limit method is now configurable on each RPC client as well as the config file|7772|
|2011/11/15|Add a --graph option to the ping application that shows response distribution|10864|
|2011/11/14|An ActiveMQ specific connector was added that supports direct connections|7899|
|2011/11/11|SimpleRPC clients now support native batching with --batch|5939|
|2011/11/11|The client now unsubscribes from topics when it's idle minimising the risk of receiving missdirected messages|10670|
|2011/11/09|Security plugins now ignore miss directed messages early thus using fewer resources|10671|
|2011/10/28|Support ruby-1.9.2-p290 and ruby-1.9.3-rc1|10352|
|2011/10/27|callerid, certificate names, and identity names can now only have \w . and - in them|10327|
|2011/10/25|When discovery information is provided always accept it without requiring reset first|10265|
|2011/10/24|Add :number, :integer and :float to the DDL and rpc application|9902|
|2011/10/22|Speed up discovery when limit targets are set|10133|
|2011/10/22|Do not attempt to validate TTL and Message Times on replies in the SSL plugin|10226|
|2011/10/03|Allow the RPC client to raise an exception rather than exit on failure|9360|
|2011/10/03|Allow the TTL of requests to be set in the config file and the SimpleRPC API|9399|
|2011/09/26|Cryptographically secure the TTL and Message Time of requests when using AES and SSL plugins|9400|
|2011/09/20|Update default shipped configurations to provide a better out of the box experience|9452|
|2011/09/20|Remove deprecated mc- scripts|9402|
|2011/09/20|Keep track of messages that has expired and expose the stat in rpcutil and inventory application|9456|

<a name="1_3_1">&nbsp;</a>

## 1.3.1 - 2011/09/16

This is a release in the development series of MCollective.  It feature major new features
and bug fixes.

This release is for early adopters, production users should consider the 1.2.x series.

### Enhancements

 * Messaging has been completely reworked internally to be more generic and easier to integrate
   with other middleware
 * When using Stomp 1.1.9 detailed connection logs are kept showing connections, reconnections
   and communication errors
 * A new point to point - but still via the middleware - communications ability has been introduced
 * When point to point comms is enabled, favour this mode when small number of nodes are being addressed
 * Add -j to any SimpleRPC client. Clients using _printrpc_ will automatically support a new JSON output format
 * A new rich discovery language was added using the -S flag
 * SimpleRPC validators can now also validate boolean data
 * The default location of _classes.txt_ has changed to be in line with Puppet defaults.
 * A default TTL of 60 seconds are set on all messages.  This is a start towards replay protection and is needed
   for the new point to point comms style
 * Discovery is now optional.  If you supply an identity filter discovery will be bypassed.  Additionally discovery
   can be supplied in arrays, text or JSON formats.  This requires the new point to point comms model.

### Bug Fixes

 * Missing DDL files on the servers are now logged at debug level to minimise noise in the logs
 * The RC scripts set RUBYLIB, remove this and rely on the operating system to be set up correctly
 * Invalid fact filters supplied on the CLI now raises an error rather than create empty filters

### New Discovery Language

Previously dicovery was very limited, filters were simply run one after the other and you could not do
anything complex like a mix of OR and AND boolean logic.

A new compact discovery language was introduced perfect for use on the command line, an example below:

{% highlight console %}
$ mco find -S "((fqdn=/example.com/ or fqdn=/another.com/) or customer=acme) and apache and physicalprocessorcount>2"
{% endhighlight %}

The EBNF for this language can be seen below, it's available on the command line and the API

    compound = ["("] expression [")"] {["("] expression [")"]}
    expression = [!|not]statement ["and"|"or"] [!|not] statement
    char = A-Z | a-z | < | > | => | =< | _ | - |* | / { A-Z | a-z | < | > | => | =< | _ | - | * | / | }
    int = 0|1|2|3|4|5|6|7|8|9{|0|1|2|3|4|5|6|7|8|9|0}

### Point to Point comms

Previously MCollective could only broadcast messages and was tied to a discovery model.  This is in line
with the initial goals of the project, having solved that we want to mix in a more traditional messaging
style.

The messaging layer now supports per node destinations that allows you to address a node, even if its down,
doesn't yet exist or if you cannot come up with a filter that would match a group of arbitrarily selected
nodes.

When this mode is in use you tell it using either text, arrays or JSON data which machines to communicate with
it will then talk directly to those nodes via the middleware and if any of them are down you will get the
usual no responses report after DDL configured timeout, this is a smooth transparent to the end user mix
in communication modes.

It is ideal for building deployers, web apps and so forth where you know exactly which nodes should be there
and you'd like to influence the MCollective network addressing, perhaps from a CMDB you built yourself.

This is the start towards an assured style of delivery, you can consider it the TCP to MCollective's UDP.
Both modes of communication will be supported in the future and both will have access to all the same agents
clients etc.

This is feature is still maturing, you enable it using the _direct\_\addressing_ configuration option.  At
present the STOMP connector supports it but it is not optimized for networks larger than 20 to 30 hosts.  A
new connector is being developed that uses ActiveMQ features to achieve this efficiently.

### Pluggable / Optional Discovery

If you did _mco rpc rpcutil ping -I box.example.com -I another.example.com_ mcollective will now just assume
you know what you want, it won't do a discover to confirm those machines exist or not, it will just go and
talk with them.  This is a big end user visible speed improvement.  If however you did a filter like _-I /example.com/_
it cannot know which machines you want to reach and so a traditional broadcast discovery is done first.

When the direct addressing mode is enabled various behind the scenes optimizations are being done:

 * If a discovery is done and it finds you only want to address 10 or fewer nodes it will use direct mode for that
   request.  This avoids a second needless broadcast.  This is less efficient to the middleware but does not send
   needless messages to uninterested nodes that would then just ignore them.
 * The _rpc_ application supports piping output from one to the next.  Example of this below.

{% highlight console %}
$ mco rpc package update package=foo -W customer=acme -j|mco rpc service restart service=bar
{% endhighlight %}

This will update a package on machines matching _customer=foo_ and then restart the service _bar_ on those machines.

The first request is doing traditional discovery based on the fact while the 2nd request is not doing discovery
at all, it uses the JSON output enabled by -j as discovery data and then restart the service on only those machines.

These abilities are exposed in the SimpleRPC client API and you can write your own schemes, query your own databases etc

### Backwards Compatibility

This is a big release and the entire messaging system has been redesigned, rewritten and has had features added.
As such there might be problems running mixed 1.2.x and 1.3.1 networks, we'd ask users to test this in lab situations
and provide us feedback to improve the eventual transition from 1.2.x to 1.4.x.  We did though aim to maintain backward
compatibility and the intention is to fix any bugs reported where a default configured 1.3.x cannot co-habit with a
previous 1.2.x build.

Enabling the new direct addressing mode is a big configuration change both in your collective and the middleware as such
soon as you enable it there will be compatibility issues until all your nodes are up to the same level.  Specifically old
nodes will just ignore your direct requests.

The default location for _classes.txt_ has changed to _/var/lib/puppet/state/classes.txt_ you need to ensure
this file exists or configure either MCollective or Puppet accordingly else your classes filters will break

Messages are now valid for only 60 seconds, nodes will _ignore_ messages older than 60 seconds.  This means
your clocks have to be in sync on your entire collective.  We use UTC time for the TTL check so your machines
can be in different time zones.  At present the 60 second threshold is hard coded, it will become configurble on a
per message basis in future.

#### Changes since 1.3.0

|Date|Description|Ticket|
|----|-----------|------|
|2011/09/9|Use direct messaging where possible for identity filters and make the rpc application direct aware|8466|
|2011/08/29|Enforce a 60 second TTL on all messages by default|8325|
|2011/08/29|Change the default classes.txt file to be in line with Puppet defaults|9133|
|2011/08/06|Add reload-agents and reload-loglevel commands to the redhat RC script|7730|
|2011/08/06|Avoid reloading the authorization class over and over from disk on each request|8703|
|2011/08/06|Add a boolean validator to SimpleRPC agents|8799|
|2011/08/06|Justify text results better when using printrpc|8807|
|2011/07/22|Add --version to the mco utility|7822|
|2011/07/22|Add missing meta data to the discovery agent|8497|
|2011/07/18|Raise an error if invalid format fact filters are supplied|8419|
|2011/07/14|Add a rich discovery query language|8181|
|2011/07/08|Do not set RUBYLIB in the RC scripts, the OS should do the right thing|8063|
|2011/07/07|Add a -j argument to all SimpleRPC clients that causes printrpc to produce JSON data|8280|
|2011/06/30|Add the ability to do point to point comms for requests affecting small numbers of hosts|7988|
|2011/06/21|Add support for Stomp Gem version 1.1.9 callback based logging|7960|
|2011/06/21|On the server side log missing DDL files at debug and not warning level|7961|
|2011/06/16|Add the ability for nodes to subscribe to per-node queues, off by default|7225|
|2011/06/12|Remove assumptions about middleware structure from the core and move it to the connector plugins|7619|

<a name="1_2_1">&nbsp;</a>

## 1.2.1 - 2011/06/30

This is a maintenance release in the production series of MCollective and is a recommended
upgrade for all users of 1.2.0.

### Bug Fixes

 * Improve error handling in the inventory application
 * Fix compatablity problems with RedHat 4 init scripts
 * Allow . in Fact names
 * Allow applications to use the exit method
 * Correct parsing of the MCOLLECTIVE_EXTRA_OPTS environment variable

### Backwards compatibility

This release should be 100% backward compatable with version 1.2.0

#### Changes since 1.2.0

|Date|Description|Ticket|
|----|-----------|------|
|2011/06/02|Correct parsing of MCOLLECTIVE_EXTRA_OPTS in cases where no config related settings were set|7755|
|2011/05/23|Allow applications to use the exit method as would normally be expected|7626|
|2011/05/16|Allow _._ in fact names|7532|
|2011/05/16|Fix compatibility issues with RH4 init system|7448|
|2011/05/15|Handle failures from remote nodes better in the inventory app|7524|
|2011/05/06|Revert unintended changes to the Debian rc script|7420|
|2011/05/06|Remove the _test_ agent that was accidentally checked in|7425|

<a name="1_3_0">&nbsp;</a>

## 1.3.0 - 2011/06/08

This is a release in the development series of mcollective.  It features major
new features, some bug fixes and internal structure refactoring.

This release is for early adopters, production users should consider the 1.2.x series.

### Enhancements

 * Agents can now programatically declare if they should work on a node
 * Applications can now use the exit method as normal and clean disconnects will be done
 * The target collective for registration messages is configurable.  In the past it defaulted to main_collective

### Bug Fixes

 * Error reporting in applications, agents and mcolletive core has been improved
 * The RC script works better on Red Hat 4 based systems

### Other Changes

 * The connector layer is being improved to make it easier to use other middleware.
   This release starts this process but it's far from complete.
 * The sshkey plugin was removed from core and moved to the plugins project

### Backwards Compatibility

If you were using the sshkey plugin you need to ensure your CM system is copying it out prior to this
upgrade as the packages will not contain it anymore.

If you have your own connectors other than the STOMP one we supply you should wait to upgrade till 1.3.1
at which point you will need to make extensive changes to your plugins internals.  If your CM is copying
out the connector you have to ensure that when this version of MCollective start that the new plugin is
in place.

### Changes

|Date|Description|Ticket|
|----|-----------|------|
|2011/06/07|Exceptions raised during option parsing were not handled and resulted in stack traces|7796|
|2011/06/06|Remove the sshkey, it's being moved to the plugin repository|7794|
|2011/06/02|Correct parsing of MCOLLECTIVE_EXTRA_OPTS in cases where no config related settings were set|7755|
|2011/05/31|Disconnect from the middleware when an application calls exit|7712|
|2011/05/29|Validations failure in RPC agents will now raise the correct exceptions as documented|7711|
|2011/05/25|Make the target collective for registration messages configurable|7650|
|2011/05/24|Rename the connector plugins send method to publish to avoid issues ruby Object#send|7623|
|2011/05/23|Log a warning when the CF file parsing fails rather than raise a whole ruby exception|7627|
|2011/05/23|Allow applications to use the exit method as would normally be expected|7626|
|2011/05/22|Refactor subscribe and unsubscribe so that middleware structure is entirely contained in the connectors|7620|
|2011/05/21|Add the ability for agents to programatically declare if they should work on a node|7583|
|2011/05/20|Improve error reporting in the single application framework|7574|
|2011/05/16|Allow _._ in fact names|7532|
|2011/05/16|Fix compatibility issues with RH4 init system|7448|
|2011/05/15|Handle failures from remote nodes better in the inventory app|7524|
|2011/05/06|Revert unintended changes to the Debian rc script|7420|
|2011/05/06|Remove the _test_ agent that was accidentally checked in|7425|

<a name="1_2_0">&nbsp;</a>

## 1.2.0 - 2011/05/04

This is the next production release of MCollective.  It brings to an
end active support for versions 1.1.4 and older.

This release brings to general availability all the features added in the
1.1.x development series.

### Enhancements

 * The concept of sub-collectives were introduced that help you partition
   your MCollective traffic for network isolation, traffic management and security
 * The single executable framework has been introduced replacing the old
   _mc-\*_ commands
 * A new AES+RSA security plugin was added that provides strong encryption,
   client authentication and message security
 * New fact matching operators <=, >=, <, >, !=, == and =~.
 * Actions can be written in external scripts and therefore other languages
   than Ruby, wrappers exist for PHP, Perl and Python
 * Plugins can now be configured using the _plugins.d_ directory
 * A convenient and robust exec wrapper has been written to assist in calling
   external scripts
 * The _MCOLLECTIVE\_EXTRA\_OPTS_ environment variable has been added that will
   add options to all client scripts
 * Network timeout handling has been improved to better take account of latency
 * Registration plugins can elect to skip sending of registration data by
   returning _nil_, previously nil data would be published
 * Multiple libdirs are supported
 * The logging framework is pluggable and easier to use
 * Fact plugins can now force fact cache invalidation.  The YAML plugin will
   force a cache clear as soon as the source YAML file updates
 * The _ping_ application now supports filters
 * Network payload can now be Base64 encoded avoiding issues with Unicode characters
   in older Stomp gems
 * All fact plugins are now cached and only updated every 300 seconds
 * The progress bar now resizes based on terminal dimensions
 * DDL files with missing output blocks will not invalidate the whole DDL
 * Display of DDL assisted complex data has been improved to be more readable
 * Stomp messages can have a priority header added for use with recent versions
   of ActiveMQ
 * Almost 300 unit tests have been written, lots of old code and any new code being
   written is subject to continuos testing on Ruby 1.8.5, 1.8.6 and 1.9.2
 * Improved the Red Hat RC script to be more compliant with distribution policies
   and to reuse the builtin functions

### Deprecations and removed functionality

 * The old _mc-\*_ commands are being removed in favor for the new _mco_ command.
   The old style is still available and your existing scripts will keep working but
   porting to the new single executable system is very easy and encouraged.
 * _MCOLLECTIVE_TIMEOUT_ and _MCOLLECTIVE_DTIMEOUT_ were removed in favor of _MCOLLECTIVE\_EXTRA\_OPTS_
 * _mc-controller_ could exit all mcollectived instances, this feature was not ported
   to the new _mco controller_ application

### Bug Fixes

 * mcollectived and all of the standard supplied client scripts now disconnects
   cleanly from the middleware avoiding exceptions in the ActiveMQ logs
 * Communications with the middleware has been made robust by adding a timeout
   while sending
 * Machines that do not pass security validation are now handled as having not
   responded at all
 * When a fire and forget request was sent, replies were still sent, they are
   now suppressed

### Backwards compatibility

This release can communicate with machines running older versions of mcollective
there are though a few steps to take to ensure a smooth upgrade.

#### Backward compatible sub-collective setup

{% highlight ini %}
topicprefix = /topic/mcollective
{% endhighlight %}

This has to change to:

{% highlight ini %}
topicprefix = /topic/
main_collective = mcollective
collectives = mcollective
{% endhighlight %}

#### Security Plugins

The interface for the _encodereply_ method on the security plugins have changed
if you are using any of the community plugins or wrote your own you should update
them with the latest at the time you upgrade to 1.2.0

#### Fact Plugins

The interface to the fact plugins have been greatly simplified, this means you need to
update to new plugins at the time you upgrade to 1.2.0

You can place these new plugins into the plugindir before upgrading. The old mcollective
will not use these plugins and the new one will not touch the old ones. This will allow
for a clean rollback.

Once the new version is deployed you will immediately have caching on all fact types
at 300 seconds you can tune this using the fact_cache_time setting in the configuration file.

#### New fact selectors

The new fact selectors are only available on newer versions of mcollective.  If a client
attempts to use them and an older version of the server is on the network those older
servers will treat all fact lookups as ==

#### Changes since 1.1.4

|Date|Description|Ticket|
|----|-----------|------|
|2011/05/03|Improve Red Hat RC script by using distro builtin functions|7340|
|2011/05/01|Support setting a priority on Stomp messages|7246|
|2011/04/30|Handle broken and incomplete DDLs better and improve the format of DDL output|7191|
|2011/04/23|Encode the target agent and collective in requests|7223|
|2011/04/20|Make the SSL Cipher used a config option|7191|
|2011/04/20|Add a clear method to the PluginManager that deletes all plugins, improve test isolation|7176|
|2011/04/19|Abstract the creation of request and reply hashes to simplify connector plugin development|5701|
|2011/04/15|Improve the shellsafe validator and add a Util method to do shell escaping|7066|
|2011/04/14|Update Rakefile to have a mail_patches task|6874|
|2011/04/13|Update vendored systemu library for Ruby 1.9.2 compatibility |7067|
|2011/04/12|Fix failing tests on Ruby 1.9.2|7067|
|2011/04/11|Update the DDL documentation to reflect the _mco help_ command|7042|
|2011/04/11|Document the use filters on the CLI|5917|
|2011/04/11|Improve handling of unknown facts in Util#has_fact? to avoid exceptions about nil#clone|6956|
|2011/04/11|Correctly set timeout on the discovery agent to 5 seconds as default|7045|
|2011/04/11|Let rpcutil#agent_inventory supply _unknown_ for missing values in agent meta data|7044|

<a name="1_1_4">&nbsp;</a>

## 1.1.4 - 2011/04/07

This is a release in the development series of mcollective.  It features major
new features and some bug fixes.

This release is for early adopters, production users should consider the 1.0.x series.

### Actions in other languages

We have implemented the ability to write actions in languages other than Ruby.
This is done via simple JSON API documented in [in our docs](simplerpc/agents.html#actions-in-external-scripts)

The _ext_ directory on [GitHub](https://github.com/puppetlabs/marionette-collective/tree/master/ext/action_helpers)
hosts wrappers for PHP, Perl and Python that makes using this interface easier.

{% highlight ruby %}
action "test" do
    implemented_by "/some/external/script"
end
{% endhighlight %}

Special thanks to the community members who contributed the wrappers.

### Enhancements

 * Actions can now be written in any language
 * Plugin configuration can be kept in _/etc/mcollective/plugin.d_
 * _mco inventory_ now shows collective and sub-collective membership
 * mc-controller has been deprecated for _mco controller_
 * Agents are now ran using new instances of the classes rather than reuse the exiting
   one to avoid concurrency related problems

### Bug Fixes

 * When mcollectived exits it now cleanly disconnects from the Middleware
 * The _rpcutil_ agent is less strict about valid Fact names
 * The default configuration files have been updated for sub-collectives

### Backwards Compatibility

This release will be backward compatible with version _1.1.3_ for compatibility
with earlier releases see the notes for _1.1.3_ and the sub collective related
configuration changes.

### Changes

|Date|Description|Ticket|
|----|-----------|------|
|2011/03/28|Correct loading of vendored JSON gem|6877|
|2011/03/28|Show collective and sub collective info in the inventory application|6872|
|2011/03/23|Disconnect from the middleware when mcollectived disconnects|6821|
|2011/03/21|Update rpcutil ddl file to be less strict about valid fact names|6764|
|2011/03/22|Support reading configuration from configfir/plugin.d for plugins|6623|
|2011/03/21|Update default configuration files for sub-collectives|6741|
|2011/03/16|Add the ability to implement actions using external scripts|6705|
|2011/03/15|Port mc-controller to the Application framework and deprecate the exit command|6637|
|2011/03/13|Only cache registration and discovery agents, handle the rest as new instances|6692|
|2011/03/08|PluginManager can now create new instances on demand for a plugin type|6622|

<a name="1_1_3">&nbsp;</a>

## 1.1.3 - 2011/03/07

This is a release in the development series of mcollective.  It features major
new features and some bug fixes.

This release is for early adopters, production users should consider the 1.0.x series.

### Enhancements

 * Add the ability to partition collectives into sub-collectives for security and
   network traffic management
 * Add a exec wrapper for agents that provides unique environments and cwds in a
   thread safe manner as well as avoid zombie processes
 * Automatically pass Application options to rpcclient when options are not
   specifically provided
 * Rename _/usr/sbin/mc_ to _/usr/bin/mco_

### Bug Fixes

 * Missing _libdirs_ will not cause crashes anymore
 * Parse `MCOLLECTIVE_EXTRA_OPTS` correctly with multiple options
 * `file_logger` failures are handled better
 * Improve middleware communication in unreliable settings by adding timeouts
   around middleware operations

### Backwards Compatibility

The configuration format has changed slightly to accomodate the concept of
collective names and sub-collectives.

In older releases the configuration was:

{% highlight ini %}
topicprefix = /topic/mcollective
{% endhighlight %}

This has to change to:

{% highlight ini %}
topicprefix = /topic/
main_collective = mcollective
collectives = mcollective
{% endhighlight %}

When setup as above a old and new version will be compatible but as soon as you
start configuring the new sub-collective feature you will loose compatiblity
between versions.

Various defaults apply, if you configure it with these exactly topic and
collective names you can leave off the `main_collective` and `collectives`
directives as the above settings would be their defaults

### Changes

|Date|Description|Ticket|
|----|-----------|------|
|2011/03/04|Rename /usr/sbin/mc to /usr/bin/mco|6578|
|2011/03/01|Wrap rpcclient in applications ensuring that options is always set|6308|
|2011/02/28|Make communicating with the middleware more robust by including send calls in timeouts|6505|
|2011/02/28|Create a wrapper to safely run shell commands avoiding zombies|6392|
|2011/02/19|Introduce Sub-collectives for network partitioning|5967|
|2011/02/19|Improve error handling when parsing arguments in the rpc application|6388|
|2011/02/19|Fix error logging when file_logger creation fails|6387|
|2011/02/17|Correctly parse MCOLLECTIVE\_EXTRA\_OPTS in the new unified binary framework|6354|
|2011/02/15|Allow the signing key and Debian distribution to be customized|6321|
|2011/02/14|Remove inadvertently included package.ddl|6313|
|2011/02/14|Handle missing libdirs without crashing|6306|

<a name="1_0_1">&nbsp;</a>

## 1.0.1 - 2011/02/16

### Release Focus and Notes

This is a minor bug fix release.

### Bugs Fixed

 * The YAML fact plugin failed to remove deleted facts from memory
 * The _-_ character is now allowed in Fact names for the rpcutil agent
 * Machines that fali security validations were not reported correctly,
   they are now treated as having not responded at all
 * Timeouts on RPC requests were too aggressive and did not allow for slow networks

### Backwards Compatibility

This release will be backward compatible with older releases.

### Changes

|Date|Description|Ticket|
|----|-----------|------|
|2011/02/02|Include full Apache 2 license text|6113|
|2011/01/29|The YAML fact plugin kept deleted facts in memory|6056|
|2012/01/04|Use the LSB based init script on SUSE|5762|
|2010/12/30|Allow - in fact names|5727|
|2010/12/29|Treat machines that fail security validation like ones that did not respond|5700|
|2010/12/25|Allow for network and fact source latency when calculating client timeout|5676|
|2010/12/25|Increase the rpcutil timeout to allow for slow facts|5679|

## 1.1.2 - 2011/02/14

This is a release in the development series of mcollective.  It features minor
bug fixes and features.

This release is for early adopters, production users should consider the 1.0.x series.

### Bug Fixes

 * The main fix in this release is a packaging bug in Debian systems that prevented
   both client and server from being installed on the same machine.
 * Backwards compatibility fix for fact filters that are empty strings

### Enhancement

 * Registration plugins can now return nil which will skip that specific registration
   message.  This will enable plugins to decide based on some node state if a message
   should be sent or not.

### Changes

|Date|Description|Ticket|
|----|-----------|------|
|2011/02/13|Surpress replies to SimpleRPC clients who did not request results|6305|
|2011/02/11|Fix Debian packaging error due to the same file in multiple packages|6276|
|2011/02/11|The application framework will now disconnect from the middleware for consistency|6292|
|2011/02/11|Returning _nil_ from a registration plugin will skip registration|6289|
|2011/02/11|Set loglevel to warn by default if not specified in the config file|6287|
|2011/02/10|Fix backward compatibility with empty fact strings|6278|

## 1.1.1 - 2011/02/02

This is a release in the development series of mcollective.  It features major new
features and numerous bug fixes.  Please pay careful attention to the upgrading
section as there is some changes that are not backward compatible.

This release is for early adopters, production users should consider the 1.0.x series.

### AES+RSA Security Plugin

A new security plugin that encrypts the payloads, uniquely identify senders and secure
replies from inspection by other people on the collective has been written.  The plugin
can re-use Puppet certificates and supports distributing of public keys if you wish.

This plugin and its deployment is very complex and it has a visible performance impact
but we felt it was a often requested feature and so decided to implement it.

Full documentation for this plugin can be found [in our docs](reference/plugins/security_aes.html), please read them very
carefully should you choose to deploy this plugin.

### Single Executable Framework

In the past a lot of the CLI tools have behaved inconsistently as the mc scripts were
mostly just written to serve immediate needs, we are starting a process of improving
these scripts and making them more robust.

The first step is to create a new framework for CLI commands, we call these Single Executable
Applications.  A new executable called _mc_ is being distributed with this release:

{% highlight console %}
$ mc
The Marionette Collective version 1.1.1

/usr/sbin/mc: command (options)

Known commands: rpc filemgr inventory facts ping find help
{% endhighlight %}

{% highlight console %}
$ mc help
The Marionette Collection version 1.1.1

  facts           Reports on usage for a specific fact
  filemgr         Generic File Manager Client
  find            Find hosts matching criteria
  help            Application list and RPC agent help
  inventory       Shows an inventory for a given node
  ping            Ping all nodes
  rpc             Generic RPC agent client application
{% endhighlight %}

{% highlight console %}
$ mc rpc package status package=zsh
Determining the amount of hosts matching filter for 2 seconds .... 51

 * [ ============================================================> ] 51 / 51


 test.com:
    Properties:
       {:provider=>:yum,
	:release=>"3.el5",
	:arch=>"x86_64",
	:version=>"4.2.6",
	:epoch=>"0",
	:name=>"zsh",
	:ensure=>"4.2.6-3.el5"}
{% endhighlight %}

You can see these commands behave just like their older counter parts but is more integrated
and discovering available commands is much easier.

Agent help that was in the past available through _mc-rpc --ah agentname_ is now available through
_mc help agentname_ and error reporting is short single line reports by default but by adding
_-v_ to the command line you can get full Ruby backtraces.

We've maintained backward compatibility by creating wrappers for all the old mc scripts but these
might be deprecated in future.

These application live in the normal plugin directories and should make it much easier to distribute
plugins in future.

We will port the scripts for plugins to this framework and encourage you to do the same when writing
new CLI tools.  An example of a ported CLI can be seen in the _filemgr_ agent.

Find the documentation for these plugins [here](reference/plugins/application.html).

### Miscellaneous Improvements

The logging system has been ra-efactored to not use a Signleton, logging messages are now simply:

{% highlight ruby %}
MCollective::Log.notice("hello world")
{% endhighlight %}

A backwards compatible wrapper exist to prevent existing code from breaking.

In some cases - like when using MCollective from within Rails - the STOMP
gem would fail to decode the payloads.  We've worked with the authors and
a new release was made that makes this more robust but we've also enabled
Base64 encoding on the Stomp connector for those who can't upgrade the Gem
and who are running into this problem.

### Bug Fixes


 * Machines that do not pass security checks are handled as having not responded
   so that these are listed in the usual stat for non responsive hosts
 * The - character is now allowed in Fact names by the DDL for rpcutil
 * Version 1.1.0 introduced a bug with reloading agents from disks using USR1 and mc-controller

### Enhancements

 * New AES+RSA based security plugin was added
 * Create a new single executable framework and port several mc scripts
 * Security plugins have access to the callerid they are responding to
 * The logging methods have been improved by removing the use of Singletons
 * The STOMP connector can now Base64 encode all sent data to deal with en/decoding issues by the gem
 * The rpcutil agent has a new _ping_ action
 * the _mc ping_ client now supports standard filters
 * DDL documentation has been updated to show you can disable type validations in the DDL
 * Fact plugins can now force fact cache invalidation, the YAML plugin will immediately load new facts when mtime on the file change
 * Improve _1.0.0_ compatibility for _foo=/bar/_ style fact matches at the expense of _1.1.0_ compatibility

### Upgrading

Upgrading should be mostly painless as most things are backward compatible.

We discovered that we broke backward compatibility with _1.0.0_ and _0.4.x_ Fact filters.  A filter in the form
_foo=/bar/_ would be treated as an equality filter and not a regular expression.

This releases fixes this compatibility with older versions at the expense of compatibility with _1.1.0_.  If you
are upgrading from _1.1.0_ keep this in mind and plan accordingly, once you've upgraded a client its requests that
contain these filters will not be correctly parsed on servers running _1.1.0_.

The security plugins have changed slightly, if you wrote your own security plugin the interface to _encodereply_
has changed slightly.  All the bundled security plugins have been updated already and older ones will just
keep working.

### Changes

|Date|Description|Ticket|
|----|-----------|------|
|2011/02/02|Load the DDL from disk once per printrpc call and not for every result|5958|
|2011/02/02|Include full Apache 2 license text|6113|
|2011/01/31|Create a new single executable application framework|5897|
|2011/01/30|Fix backward compatibility with old foo=/bar/ style fact searches|5985|
|2011/01/30|Documentation update to reflect correct default identity behavior|6073|
|2011/01/29|Let the YAML file force fact reloads when the files update|6057|
|2011/01/29|Add the ability for fact plugins to force fact invalidation|6057|
|2011/01/29|Document an approach to disable type validation in the DDL|6066|
|2011/01/19|Add basic filters to the mc-ping command|5933|
|2011/01/19|Add a ping action to the rpcutil agent|5937|
|2011/01/17|Allow MC::RPC#printrpc to print single results|5918|
|2011/01/16|Provide SimpleRPC style results when accessing the MC::Client results directly|5912|
|2011/01/11|Add an option to Base64 encode the STOMP payload|5815|
|2011/01/11|Fix a bug with forcing all facts to be strings|5832|
|2011/01/08|When using reload_agents or USR1 signal no agents would be reloaded|5808|
|2011/01/04|Use the LSB based init script on SUSE|5762|
|2011/01/04|Remove the use of a Singleton in the logging class|5749|
|2011/01/02|Add AES+RSA security plugin|5696|
|2010/12/31|Security plugins now have access to the callerid of the message they are replying to|5745|
|2010/12/30|Allow - in fact names|5727|
|2010/12/29|Treat machines that fail security validation like ones that did not respond|5700|

## 1.1.0 - 2010/12/29

This is the first in a new development series, as such there will be rapid changes
and new features.  We cannot guarantee the changes will be backward compatible but
we will as before try to keep these releases solid and production quality.

Production users who do not wish to have rapid change should use release 1.0.0.

This release focus mainly on getting all the community contributed code into a release
and addressing some issues I had but wasn't comfortable fixing them late in the
previous development series.

Please read these notes carefully we are **removing** some old functionality and changing
some internals, you need to carefully review the text below.

### Bug Fixes

 * The progress bar will now try hard to detect screen size and adjust itself,
   failing back to a dumb mode if it can't work it out.
 * rpcutil timeout was too short when considering slow facts and network latency

### Improvements

 * libdir can now be multiple directories specified with : separation - Thanks to Richard Clamp
 * Logging is now pluggable, 3 logger types are supported - file, syslog and console.  Thanks to
   Nicolas Szalay for the initial Syslog code
 * A new experimental ssh agent based security system.  Thanks to Jordan Sissel
 * New fact matching operators <=, >=, <, >, !=, == and =~. Thanks to Mike Pountney
 * SimpleRPC fact_filter method can now take any valid fact string as input in addition to the old format
 * A message gets logged at startup showing mcollective version and logging level
 * The fact plugin format has been changed, simplified, made thread safe and global caching added.
   This breaks backward compatibility with old fact sources
 * Creating options hashes has been simplified by adding a helper that creates them for you
 * Calculating the client timeout has been improved by including for latency and fact source slowness
 * Audit log lines are now on one line and include a ISO 8601 format date

### Removed Functionality

 * The old MCOLLECTIVE_TIMEOUT and MCOLLECTIVE_DTIMEOUT were removed, a new MCOLLECTIVE_EXTRA_OPTS
   was added which should allow much more flexibility.  Supply any command line options in this var

### Upgrading

Upgrading should be easy the only backward incompatible change is the Facts format.  If you only use
the included YAML plugin the upgrade will just work if you use the packages.  If you use either the
facter or ohai plugins you will need to download new plugins from the community plugin page.

If you wrote your own Facts plugin you will need to change it a bit:

  * The old get_facts method should now be load_facts_from_source
  * The class for facts have to be in the form MCollective::Facts::Foo_facts and the filename should match

This is all, your facts can now be much simpler as threading and caching is handled in the base class.

You can place these new plugins into the plugindir before upgrading.  The old mcollective will not use
these plugins and the new one will not touch the old ones.  This will allow for a clean rollback.

Once the new version is deployed you will immediately have caching on all fact types at 3000 seconds
you can tune this using the fact_cache_time setting in the configuration file.

### Changes

|Date|Description|Ticket|
|----|-----------|------|
|2010/12/28|Adjust the logfile audit format to include local time and all on one line|5694|
|2010/12/26|Improve the SimpleRPC fact_filter helper to support new fact operators|5678|
|2010/12/25|Increase the rpcutil timeout to allow for slow facts|5679|
|2010/12/25|Allow for network and fact source latency when calculating client timeout|5676|
|2010/12/25|Remove MCOLLECTIVE_TIMEOUT and MCOLLECTIVE_DTIMEOUT environment vars in favor of MCOLLECTIVE_EXTRA_OPTS|5675|
|2010/12/25|Refactor the creation of the options hash so other tools don't need to know the internal formats|5672|
|2010/12/21|The fact plugin format has been changed and simplified, the base now provides caching and thread safety|5083|
|2010/12/20|Add parameters <=, >=, <, >, !=, == and =~ to fact selection|5084|
|2010/12/14|Add experimental sshkey security plugin|5085|
|2010/12/13|Log a startup message showing version and log level|5538|
|2010/12/13|Add a console logger|5537|
|2010/12/13|Logging is now pluggable and a syslog plugin was provided|5082|
|2010/12/13|Allow libdir to be an array of directories for agents and ddl files|5253|
|2010/12/13|The progress bar will now intelligently figure out the terminal dimensions|5524|

## 1.0.0 - 2010/12/13

### Release Focus and Notes

This is a bug fix and minor improvement release.

We will maintain the 1.0.x branch as a stable supported branch.  The features
currently in the branch will be frozen and we'll only do bug fixes.

A new 1.1.x series of releases will be done where we will introduce new features.
Once the 1.1.x code base reaches a mature point it will become the new stable
release and so forth.

### Bug Fixes

 * Settings like retry times were ignored in the Stomp connector
 * The default init script had incorrect LSB comments
 * The rpcutil DDL has better validation and will now match all facts

### New Features and Enhancements

 * You can now send RPC requests to a subset of discovered nodes
 * SimpleRPC custom_request can now be used to create fire and forget requests
 * Clients can now cleanly disconnect from the middleware.  Bundled clients have been
   updated.  This should cause fewer exceptions in ActiveMQ logs
 * Rather than big exceptions many clients will now log errors only
 * mc-facts has been reworked to be a SimpleRPC client, this speeds it up significantly
 * Add get_config_item to rpcutil to retrieve a running config value from a server
 * YAML facts are now forced to be all strings and is thread safe
 * On RedHat based systems the requirement for the LSB packages has been removed

The first feature is a major new feature in SimpleRPC.  If you expose a service redundantly
on your network using MCollective you wouldn't always want to send requests to all the
nodes providing the service.  You can now limit the requests to an arbitrary amount
using the new --limit-nodes option which will also take a percentage.  A shortcut -1 has
been added that is the equivalent to --limit-nodes 1

### Backwards Compatibility

This release will be backward compatible with older releases.

### Changes

|Date|Description|Ticket|
|----|-----------|------|
|2010/12/04|Remove the LSB requirements for RedHat systems|5451|
|2010/11/23|Make the YAML fact source thread safe and force all facts to strings|5377|
|2010/11/23|Add get_config_item to rpcutil to retrieve a running config value from a server|5376|
|2010/11/20|Convert mc-facts into a SimpleRPC client|5371|
|2010/11/18|Added GPG signing to Rake packaging tasks (SIGNED=1)|5355|
|2010/11/17|Improve error messages from clients in the case of failure|5329|
|2010/11/17|Add helpers to disconnect from the middleware and update all bundled clients|5328|
|2010/11/16|Correct LSB provides and requires in default init script|5222|
|2010/11/16|Input validation on rpcutil has been improved to match all valid facts|5320|
|2010/11/16|Add the ability to limit the results to a subset of hosts|5306|
|2010/11/15|Add fire and forget mode to SimpleRPC custom_request|5305|
|2010/11/09|General connection settings to the Stomp connector was ignored|5245|

## 0.4.10 - 2010/10/18

### Release Focus and Notes

This is a bug fix and minor improvement release.

### Bug Fixes

 * Multiple RPC proxy classes in the same script would not all share the same command line options
 * Ruby 1.9.x compatibility has been improved
 * A major bug in registration has been fixed, any exception in the registration logic would have
   resulted in a high CPU consuming loop

The last bug is a major issue it will result in the _mcollectived_ consuming lots of CPU, updating to
this version of MCollective is strongly suggested.  Should you run into this problem on a large scale
you can use _mc-controller exit_ to exit all your _mcollectived_ processes at the same time.

### New Features and Enhancements

 * The PSK security plugin can now be configured to set the callerid to a few different values
   useful for cases where you want to do group based RPC Authorization for example.
 * Info logging has been minimised by demoting the 'not targeted at us' message to debug
 * Document the 'exit' option to mc-controller

### Backwards Compatibility

This release will be backward compatible with older releases.

### Changes

|Date|Description|Ticket|
|----|-----------|------|
|2010/10/18|Document exit command to mc-controller|152|
|2010/10/13|Log messages that don't pass the filters at debug level|149|
|2010/10/03|Preserve options in cases where RPC::Client instances exist in the same program|148|
|2010/09/30|Add the ability to set different types of callerid in the PSK plugin|145|
|2010/09/30|Improve Ruby 1.9.x compatibility|142|
|2010/09/29|Improve error handling in registration to avoid high CPU usage loops|143|


## 0.4.9 - 2010/09/21

### Release Focus and Notes

This is a bug fix and minor improvement release.

### Bug Fixes

 * Internal data structure related to Agent meta data has been fixed, no user impact from this
 * When using per-user config files the _rpc-help.erb_ template could not be found
 * The log files will now rotate by default keeping 5 x 2MB files
 * The config were parsed multiple times in complex scripts, this has been eliminated
 * MCollective::RPC loaded a bunch of unneeded stuff into Object, this has been cleaned up
 * Various packaging related tweaks were done

### New Features

 * We ship a new agent called _rpcutil_ with the base system, you can use this agent to get inventory etc from your _mcollectived_.  _mc-inventory_ has been rewritten to use this agent and should serve as a good reference for what you can get from the agent.
 * The DDL now support :boolean style inputs, mc-rpc also turn true/false on the command line into booleans when needed

### Backwards Compatibility

This release will be backward compatible with older releases.

### Changes

|Date|Description|Ticket|
|----|-----------|------|
|2010/09/20|Improve Debian packaging task|140|
|2010/09/20|Add :boolean type support to the DDL|138|
|2010/09/19|Refactor MCollective::RPC to add less unneeded stuff to Object|137|
|2010/09/18|Prevent duplicate config loading with multiple clients active|136|
|2010/09/18|Rotate the log file by default, keeping 5 x 2MB files|135|
|2010/09/18|Write a overview document detailing security of the collective|131|
|2010/09/18|Add MCollective.version, set it during packaging and include it in the rpcutil agent|134|
|2010/09/13|mc-inventory now use SimpleRPC and the rpcutil agent and display server stats|133|
|2010/09/13|Make the path to the rpc-help.erb configurable and set sane default|130|
|2010/09/13|Make the configfile used available in the Config class and add to rpcutil|132|
|2010/09/12|Rework internal statistics and add a rpcutil agent|129|
|2010/09/12|Fix internal memory structures related to agent meta data|128|
|2010/08/24|Update the OpenBSD port for changes in 0.4.8 tarball|125|
|2010/08/23|Fix indention/block error in M:R:Stats|124|
|2010/08/23|Fix permissions in the RPM for files in /etc|123|
|2010/08/23|Fix language in two error messages|122|

## 0.4.8 - 2010/08/20

### Release Focus and Notes

This is a bug fix and minor improvement release.

### Bug Fixes

 * The RPM packages now require redhat-lsb since our RC scripts need it
 * The rake tasks do not attempt to build rpms on all platforms
 * Some plugin missing related exceptions are now handled gracefully
 * The Rakefile had a few warnings cleaned up

### Notable New Features

 * Users can now have a _~/.mcollective_ file which will be preferred over over _/etc/mcollective/client.cfg_ if it exists.  You can still use _--config_ to override.

 * The SSL Security plugin can now use "either YAML or Marshal for serialization":/reference/plugins/security_ssl.html#serialization_method, this means other programming languages can be used as clients.  A sample Perl client is included in the ext directory.  Marshal remains the default for backwards compatibility

 * _mc-inventory_ can now be used to create "custom reports using a small reporting DSL":/reference/ui/nodereports.html, this enable you to build custom reports listing all your machines and gives you access to facts, agents and classes lists.

 * The log level for the _mcollectived_ can be adjusted during run time using the _USR2_ unix process signal.

### Backwards Compatibility

This release will be backward compatible with older releases.  If you choose to use YAML in the SSL plugin you need matching versions on the client.

### Changes

|Date|Description|Ticket|
|----|-----------|------|
|2010/08/19|Fix missing help template in debian packages|90|
|2010/08/18|Clean up some hardlink warnings in the Rakefile|117|
|2010/08/18|Include the website in the main repo and add a simple Rake task|118|
|2010/08/17|Handle exceptions for missing plugins better|115|
|2010/08/17|Add support for ~/.mcollective as a config file|114|
|2010/08/07|SSL security plugin can use either YAML or Marshal|94|
|2010/08/06|Multiple YAML files can now be used as fact source|112|
|2010/08/06|Allow log level to be adjusted at run time with USR2|113|
|2010/07/31|Add basic report scripting support to mc-inventory|111|
|2010/07/06|Removed 'rpm' from the default rake task|109|
|2010/07/06|Add redhat-lsb to the server RPM dependencies|108|

## 0.4.7 - 2010/06/29

### Release Focus and Notes

This is a bug fix and incremental improvement release focusing on small improvements in the DDL mostly.

### Data Definition Language

We've extended the use of the DDL in the RPC client.  We've integrated the DDL into _printrpc_ helper.  The output is dynamic showing field names in human readable format rather than hash dumps.

We're also using color to improve the display of the results, the color display can be disabled with the new _color_ configuration option.

A "screencast of the DDL integration":https://www.youtube.com/watch?v=xikjjXvN6nA and color usage has been recorded.

### Bug Fixes

A serious issue has been fixed with regard to complex agents.  If you attempted to use multiple agents from the same script errors such as duplicate discovery results or simply not working.

The default fact source has been changed to YAML, it was inadvertently set to Facter in the past.

Some previously unhandled exceptions are now being handled correctly and passed onto the clients as failed requests rather than no responses at all.

### Backwards Compatibility

This release will be backward compatible with older releases.  The change to YAML fact source by default might impact you if you did not previously specify a fact source in the configuration files.

### Changes

|Date|Description|Ticket|
|----|-----------|------|
| 2010/06/27 | Change default factsource to YAML|106|
| 2010/06/27 | Added VIM snippets to create DDLs and Agents|102|
| 2010/06/26 | DDL based help now works better with Symbols in in/output|105|
| 2010/06/23 | Whitespace at the end of config lines are now stripped|100|
| 2010/06/22 | printrpc will now inject some colors into results|99|
| 2010/06/22 | Recover from syntax and other errors in agents|98|
| 2010/06/17 | The agent a MC::RPC::Client is working on is now available|97|
| 2010/06/17 | Integrate the DDL with data display helpers like printrpc|92|
| 2010/06/15 | Avoid duplicate topic subscribes in complex clients|95|
| 2010/06/15 | Catch some unhandled exceptions in RPC Agents|96|
| 2010/06/15 | Fix missing help template file from RPM|90|

## 0.4.6 - 2010/06/14

### Release Focus and Notes

This release is a major feature release.

We're focusing mainly on the Stomp connector and on the SimpleRPC agents in this release though a few smaller additions were made.

### Stomp Connector

We've historically been stuck just using RubyGem Stomp 1.1 due to multi threading bugs in the newer releases.  All attempts to contact the authors failed.  Recently though I had some luck and these issues are resolved in the RubyGem Stomp 1.1.6 release.

This means we can take advantage of a lot of new features such as connection pooling for failover/ha and also SSL TLS between nodes and ActiveMQ server.

See "Stomp Connector":/reference/plugins/connector_stomp.html for details.

### RPC Agent Data Description Language

I've been working since around February on building introspection, automatically generated documentation and the ability for user interfaces to be auto generated for agents, even ones you write your self.

This feature is documented in "DDL":/simplerpc/ddl.html but a quick example of a DDL document might help make it clear:

### CLI Utilities changes

  * _mc-facts_ now take all the standard filters so you can make reports for just subsets of machines
  * A new utility _mc-inventory_ has been added, it will show agents, facts and classes for a node
  * _mc-rpc_ has a new option _--agent-help_ that will use the DDL and display auto generated documentation for an agent.
  * _mc-facts_ output is sorted for better readability

### Backwards Compatibility

This release will be backward compatible with older releases, the new Stomp features though require the newer Ruby Gem.

### Changes

|Date|Description|Ticket|
|----|-----------|------|
| 2010/06/12 | Qualify the Process class to avoid clashes in the discovery agent|88|
| 2010/06/12 | Add mc-inventory which shows agents, classes and facts for a node|87|
| 2010/06/11 | mc-facts now supports standard filters|86|
| 2010/06/11 | Add connection pool retry options and SSL for connection|85|
| 2010/06/11 | Add support for specifying multiple stomp hosts for failover|84|
| 2010/06/10 | Tighten up handling of filters to avoid nil's getting into them|83|
| 2010/06/09 | Sort the mc-facts output to be more readable|82|
| 2010/06/08 | Fix deprecation warnings in newer Stomp gems|81|

## 0.4.5 - 2010/06/03

### Release Focus and Notes

This release is a major feature release.

The focus of this release is to finish up some of the more enterprise like features, we now have fine grained Authorization and Authentication and a new security model that uses SSL keys.

### Security Plugin

Vladimir Vuksan contributed the base code of a new "SSL based security plugin":/reference/plugins/security_ssl.html .  This plugin builds on the old PSK plugin but gives each client a unique certificate pair.  The nodes all share a certificate and only store client public keys.  This means that should one node be compromised it cannot be used to control the rest of the network.

### Authorization Plugin

We've developed new hooks and plugins for SimpleRPC that enable you to write "fine grained authorization systems":/simplerpc/authorization.html .  You can do authorization on every aspect of the request and you'll have access to the caller userid as provided by the security plugin.  Combined with the above SSL plugin this can be used to build powerful and secure Authentication and Authorization systems.

A sample plugin can be found "here":http://code.google.com/p/mcollective-plugins/wiki/ActionPolicy

### Enhancements for Web Development

Web apps doesn't tie in well with our discover, request, wait model.  We've made it easier for web apps to maintain their own cached discovery data using the "Registration:/reference/plugins/registration.html system and then based on that do requests that would not require any discovery.

### Fire and Forget requests

It is often desirable to just send a request and not wait for any reply.  We've made it easy to do requests like this] with the addition of a new request parameter on the SimpleRPC client class.

Requests like this will not take any time to do discovery and you will not be able to get results back from the agents.

### Reloading Agents

To make it a bit easier to manage daemons and agents you can now send the _mcollectived_ a _USR1_ signal and it will re-read all it's agents from disk.

### Backwards Compatibility

This release when used with the old style PSK plugin should be perfectly backward compatible with your existing agents.  To use some of the newer features like authorization will require config and/or agent changes.

### Changes

|Date|Description|Ticket|
|----|-----------|------|
| 2010/06/01 | Improve the main discovery agent by adding facts and classes to its inventory action|79|
| 2010/05/30 | Add various helpers to get reports as text instead of printing them|43|
| 2010/05/30 | Add a custom_request method to call SimpleRPC agents with your own discovery|75|
| 2010/05/30 | Refactor RPC::Client to be more generic and easier to maintain|75|
| 2010/05/29 | Fix a small scoping issue in Security::Base|76|
| 2010/05/25 | Add option --no-progress to disable progress bar for SimpleRPC|74|
| 2010/05/23 | Add some missing dependencies to the RPMs|72|
| 2010/05/22 | Add an option _:process_results_ to the client|71|
| 2010/05/13 | Fix help output that still shows old branding|70|
| 2010/04/27 | The supplied generic stompclient now accepts STOMP_PORT in the environment|68|
| 2010/04/26 | Add a SimpleRPC Client helper to reset filters|64|
| 2010/04/26 | Listen for signal USR1 and reload all agents from disk|65|
| 2010/04/12 | Add SimpleRPC Authorization support|63|


## 0.4.4 - 2010/04/03

### Release Focus and Notes

This release is mostly a bug fix release.

We've cleaned up the logs a bit so you'll see fewer exceptions logged, also if you have Rails + Puppet on a node the logs will stay in the standard format.  We are handling some exceptions better which has improved stability of the registration system.

If you do some slow queries in your discovery agent you can bump the timeout up in the config using _plugin.discovery.timeout_.

All the scripts now use _/usr/bin/env ruby_ rather than hardcoded paths to deal better with Ruby's in weird places.

Several other small annoyances was fixed or improved.

### mc-controller

We've always had a tool that let you control a network of mcollective instances remotely, it lagged behind a bit with the core, we've fixed it up and documented it "here":/reference/basic/daemon.html .  You can use it to reload agents from disk without restarting the daemon for example or get stats or shut down the entire mcollective network.

### Backwards Compatibility

No changes that impacts backward compatibility has been made.

### Changes

|Date|Description|Ticket|
|----|-----------|------|
| 2010/03/27 | Make it easier to construct SimpleRPC requests to use with the standard client library|60|
| 2010/03/27 | Manipulating the filters via the helper methods will force rediscovery|59|
| 2010/03/23 | Prevent Activesupport when brought in by Facter from breaking our logs|57|
| 2010/03/23 | Clean up logging for messages not targeted at us|56|
| 2010/03/19 | Add exception handling to the registration base class|55|
| 2010/03/03 | Use /usr/bin/env ruby instead of hardcoded paths|54|
| 2010/02/17 | Improve mc-controller and document it|46|
| 2010/02/08 | Remove some close coupling with Stomp to easy creating of other connectors|49|
| 2010/02/01 | Made the discovery agent timeout configurable using plugin.discovery.timeout|48|
| 2010/01/25 | mc-controller now correctly loads/reloads agents.|45|
| 2010/01/25 | Building packages has been improved to ensure rdocs are always included|44|


## 0.4.3 - 2010/01/24

### Release Focus and Notes

This release fixes a few bugs and introduce a major new SimpleRPC feature for auditing requests.

### Auditing

We've created an "auditing framework for SimpleRPC":/simplerpc/auditing.html, each request gets passed to an audit plugin for processing.  We ship one that simply logs to a file on each node and there's a "community plugin":http://code.google.com/p/mcollective-plugins/wiki/AuditCentralRPCLog that logs everything on a central logging host.

In future we might add auditing to the client libraries so requests will be logged where they are sent as well as auditing of replies being sent, this will be driven by requests from the community though.

### New _fail!_ method for SimpleRPC

Till now while writing agents you can use the _fail_ method to set statuses in the reply, this however did not also raise exceptions and terminate execution of the agent immediately.

Often the existing behavior is required but it did lead to some awkward code when you did want to just exit the agent immediately as well as set a fail status.  We've added a _fail!_ method that works just like _fail_ except it stops execution of your agent immediately.

### Backwards Compatibility

No changes that impacts backward compatibility has been made.

### Changes

|Date|Description|Ticket|
|----|-----------|------|
| 2010/01/23 | Handle ctrl-c during discovery without showing exceptions to users|34|
| 2010/01/21 | Force all facts in the YAML fact source to be strings|41|
| 2010/01/19 | Add SimpleRPCAuditing audit logging to SimpleRPC clients and Agents| |
| 2010/01/18 | The SRPM we provide will now build outside of the Rake environment|40|
| 2010/01/18 | Add a _fail!_ method to RPC::Agent|37|
| 2010/01/18 | mc-rpc can now be used without supplying arguments|38|
| 2010/01/18 | Don't raise an error if no user/pass is given to the stomp connector, try unauthenticated mode|35|
| 2010/01/17 | Improve error message when Regex validation failed on SimpleRPC input|36|


## 0.4.2 - 2010/01/14

### Release Focus and Notes

This release fixes a few bugs, add some command line improvements and brings major changes to the Debian packaging.

### Packaging

Firstly we've had some amazing work done by Riccardo Setti to make us Debian packages that complies with Debian and Ubuntu policy, this release use these new packages.  It has some unfortunate changes to file layout detailed below but overall I think it's a big win to get us in line with Distribution policies and standards.

The only major change is that in the past we used _/usr/libexec/mcollective_ as the libdir, but Debian does not have this directory and it is not in the LFHS anymore so we now use _/usr/share/mcollective/plugins_ as the lib dir.  You need to move your plugins there and update both client and server configs.

The RedHat packages will move to this convention too in the next release since I think it's the better location and complies with LFHS.

### Command Line Improvements

We've streamlined the command line a bit, nothings changed we've just added some flags.

The _--with-class_, _--with-fact_, _--with-agent_ and _--with-identity_ now all have a short form _-C_, _-F_, _-A_ and _-I_ respectively.

We've added a new filter option _--with_ and a short form _-W_ that combines _--with-class_ and _--with-fact_ into one filter type, use case would be:

{% highlight console %}
  % mc-find-hosts -W "/centreon/ country=de roles::dev_server/"
{% endhighlight %}

This would find hosts with class regex matched _/centreon/_, class _roles::dev_server_ and fact matching _country=de_.  Hopefully this saves on some typing.

You can also now set the environment variables _MCOLLECTIVE_TIMEOUT_ and _MCOLLECTIVE_DTIMEOUT_ which saves you from typing _--timeout_ and _--discovery-timeout_ often, especially useful on very fast networks.

### Other fixes and improvements

 * We've added the COPYING file to all the packages
 * We've made the init script more LSB compliant
 * A bug related to discovery in SimpleRPC was fixed

### Backwards Compatibility

The only backwards issue is the Debian packages.  They've been tested to upgrade cleanly but you need to change the config as above.

### Changes

|Date|Description|Ticket|
|----|-----------|------|
| 2010/01/13 | New packaging for Debian provided by Riccardo Setti|29|
| 2010/01/07 | Improved LSB compliance of the init script - thanks Riccardo Setti|32|
| 2010/01/07 | Multiple calls to SimpleRPC client would reset discovered hosts|31|
| 2010/01/04 | Timeouts can now be changed with MCOLLECTIVE_TIMEOUT and MCOLLECTIVE_DTIMEOUT environment vars|25|
| 2010/01/04 | Specify class and fact filters easier with the new -W or --with option|27 |
| 2010/01/04 | Added COPYING file to RPMs and tarball|28|
| 2010/01/04 | Make shorter filter options -C, -I, -A and -F|26|

## 0.4.1 - 2010/01/02

### Release Focus and Notes

This is a bug fix release to address some shortcomings and issues found in Simple RPC.

The main issue is around handling of meta data in agents, the documented approach did not work, we've now solved this by adding a number of hooks into the processing of Simple RPC agents.

We've also made logging and config retrieval a bit easier in agents - and documented this.

You can now call the _mc-rpc_ command a bit easier:

{% highlight console %}
  % mc-rpc --agent helloworld --action echo --argument msg="hello world"
  % mc-rpc helloworld echo msg="hello world"
{% endhighlight %}

The 2 calls are the same, you can pass as many arguments in _key=val_ pairs as needed at the end.

### Backwards Compatibility

No issues with backward compatibility, should be a simple upgrade.

### Changes

|Date|Description|Ticket|
|----|-----------|------|
| 2010/01/02 | Added hooks to plug into the processing of requests, also enabled setting meta data and timeouts|14|
| 2010/01/02 | Created readers for @config and @logger in the SimpleRPC agent|23|
| 2009/12/30 | Don't send out any requests if no nodes were discovered|17|
| 2009/12/30 | Added :discovered and :discovered_nodes to client stats|20|
| 2009/12/30 | Add a empty_filter? helper to the RPC mixin|18|
| 2009/12/30 | Fix formatting bug with progress bar|21|
| 2009/12/29 | Simplify mc-rpc command line|16|
| 2009/12/29 | Fix layout issue when printing hosts that did not respond|15|


## 0.4.0 - 2009/12/29

### Release Focus and Notes

This release introduced a major new feature - Simple RPC - a framework for easily building clients and agents.  More than that it's a set of conventions and standards that will help us build generic clients like web based ones capable of talking to all agents.

We think this feature is ready for wide use, it's well documented and we've done extensive testing.  We'll be porting some of our own code over to it once this release is out and we do anticipate there might be some _0.4.x_ releases to round off a few issues that might remain.  We do not currently have any open tickets against Simple RPC.

We've also added the ability to create more complex queries such as:

{% highlight console %}
--with-class /dev_server/ --with-class /rails/
{% endhighlight %}

This does an _AND_ operation on the puppet classes on the node and finds only nodes with both _/dev_server/_ *AND* _/rails/_ classes.  This new functionality applies to all types of filter.

We've made the _--with-class_ filters more generic in comments, documentation etc with an eye to be more usable in Chef and other Configuration Management environments.

### Backwards Compatibility

Unfortunately introducing the new filtering methods has some backward compatibility issues, if you had clients/agents with code like:

{% highlight ruby %}
   options[:filter]["agent"] = "some agent"
{% endhighlight %}

You should now change that to:

{% highlight ruby %}
   options[:filter]["agent"] << "some agent"
{% endhighlight %}

As each filter is an array now.  If you do not change the code it will still work as before but you will not be able to use the compound filtering feature on filter types that you've forced to be a string and there might be some other undesired side effects.  We've tried though to at least not break old code, they just can't use the new features.

You were also able to test easily in the past if you're running unfiltered using
something like:

{% highlight ruby %}
   if options[:filter] == {}
{% endhighlight %}

Now that's much harder and we've added a helper to make this easier:

{% highlight ruby %}
   if MCollective::Util.empty_filter?(options[:filter])
{% endhighlight %}

This new method is compatible with both the old and new filter method so you can start using it before you finish the first issue mentioned here.

We've also made the class filter more generic, in the past you did class filters like this:

{% highlight ruby %}
   options[:filter]["puppet_class"] << /apache/
{% endhighlight %}

Now you have to adjust it to:

{% highlight ruby %}
   options[:filter]["cf_class"] << /apache/
{% endhighlight %}

Old code will keep working but you should change to this name for filters to be consistent with the rest of the code base.

### Changes

|Date|Description|Ticket|
|----|-----------|------|
| 2009/12/28 | Add support for other configuration management systems in the --with-class filters|13|
| 2009/12/28 | Add a `Util.empty_filter?` to test for an empty filter| |
| 2009/12/27 | Create a new client framework SimpleRPCIntroduction|6|
| 2009/12/27 | Add support for multiple filters of the same type|3|

## 0.3.0 - 2009/12/17

### Release Focus and Notes

Primarily a bug fix release.  Only new feature is to allow the user to create `MCollective::Util::*` classes and put those in the plugins directory.  This is useful for more complex agents and clients.

### Backwards Compatibility

This release should not break any older code, if it does it's a bug.

### Changes

|Date|Description|Ticket|
|----|-----------|------|
|2009/12/16|Improvements for newer versions of Ruby where TERM signal was not handled|7|
|2009/12/07|MCollective::Util is now a module and plugins can drop in util classes in the plugin dir| |
|2009/12/07|The Rakefile now works with rake provided on Debian 4 systems|2|
|2009/12/07|Improvements in the RC script for Debian and older Ubuntu systems|5|

## 0.2.0 - 2009/12/02

### Release Focus and Notes

First numbered release

### Backwards Compatibility

n/a

### Changes

n/a
