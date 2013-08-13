---
layout: default
title: Writing SimpleRPC Agents
---
[WritingAgents]: /mcollective/reference/basic/basic_agent_and_client.html
[SimpleRPCClients]: /mcollective/simplerpc/clients.html
[ResultsandExceptions]: /mcollective/simplerpc/clients.html#Results_and_Exceptions
[SimpleRPCAuditing]: /mcollective/simplerpc/auditing.html
[SimpleRPCAuthorization]: /mcollective/simplerpc/authorization.html
[DDL]: /mcollective/reference/plugins/ddl.html
[WritingAgentsScreenCast]: http://mcollective.blip.tv/file/3808928/
[RPCUtil]: /mcollective/reference/plugins/rpcutil.html
[ValidatorPlugins]: /mcollective/reference/plugins/validator.html

Simple RPC works because it makes a lot of assumptions about how you write agents, we'll try to capture those assumptions here and show you how to apply them to our Helloworld agent.

We've recorded a [tutorial that will give you a quick look at what is involved in writing agents][WritingAgentsScreenCast].

## Conventions regarding Incoming Data

As you've seen in [SimpleRPCClients] our clients will send requests like:

{% highlight ruby %}
mc.echo(:msg => "Welcome to MCollective Simple RPC")
{% endhighlight %}

A more complex example might be:

{% highlight ruby %}
exim.setsender(:msgid => "1NOTVx-00028U-7G", :sender => "foo@bar.com")
{% endhighlight %}

Effectively this creates a hash with the members `:msgid` and `:sender`.

Your data types should be preserved if your Security plugin supports that - the default one does - so you can pass in Arrays, Hashes, OpenStructs, Hashes of Hashes but you should always pass something in and it should be key/value pairs like a Hash expects.

You cannot use the a data item called `:process_results` as this has special meaning to the agent and client.  This will indicate to the agent that the client is'nt going to be waiting to process results.  You might choose not to send back a reply based on this.

## Sample Agent
Here's our sample *Helloworld* agent:

{% highlight ruby linenos %}
module MCollective
  module Agent
    class Helloworld<RPC::Agent
      # Basic echo server
      action "echo" do
        validate :msg, String

        reply[:msg] = request[:msg]
      end
    end
  end
end

{% endhighlight %}

Strictly speaking this Agent will work but isn't considered complete - there's no meta data and no help.

A helper agent called [`rpcutil`][RPCUtil] is included that helps you gather stats, inventory etc about the running daemon.  It's a full SimpleRPC agent including DDL, you can look at it for an example.

### Agent Name
The agent name is derived from the class name, the example code creates *MCollective::Agent::Helloworld* and the agent name would be *helloworld*.

<a name="Meta_Data_and_Initialization">&nbsp;</a>

### Meta Data and Initialization
Simple RPC agents still need meta data like in [WritingAgents], without it you'll just have some defaults assigned, code below adds the meta data to our agent:

**NOTE**: As of version 2.1.1 the `metadata` section is deprecated, all agents must have DDL files with this information in them.

{% highlight ruby linenos %}
module MCollective
  module Agent
    class Helloworld<RPC::Agent
      metadata :name        => "helloworld",
               :description => "Echo service for MCollective",
               :author      => "R.I.Pienaar",
               :license     => "GPLv2",
               :version     => "1.1",
               :url         => "http://projects.puppetlabs.com/projects/mcollective-plugins/wiki",
               :timeout     => 60

      # Basic echo server
      action "echo" do
        validate :msg, String

        reply[:msg] = request[:msg]
      end
    end
  end
end
{% endhighlight %}

The added code sets our creator info, license and version as well as a timeout.  The timeout is how long MCollective will let your agent run for before killing them, this is a very important number and should be given careful consideration.  If you set it too low your agents will be terminated before their work is done.

The default timeout for SimpleRPC agents is *10*.

### Writing Actions
Actions are the individual tasks that your agent can do:

{% highlight ruby linenos %}
action "echo" do
  validate :msg, String

  reply[:msg] = request[:msg]
end
{% endhighlight %}

Creates an action called "echo".  They don't and can't take any arguments.

## Agent Activation
In the past you had to copy an agent only to machines that they should be running on as
all agents were activated regardless of dependencies.

To make deployment simpler agents support the ability to determine if they should run
on a particular platform.  By default SimpleRPC agents can be configured to activate
or not:

{% highlight ini %}
plugin.helloworld.activate_agent = false
{% endhighlight %}

You can also place the following in `/etc/mcollective/plugins.d/helloworld.cfg`:

{% highlight ini %}
activate_agent = false
{% endhighlight %}

This is a simple way to enable or disable an agent on your machine, agents can also
declare their own logic that will get called each time an agent gets loaded from disk.

{% highlight ruby %}
module MCollective
  module Agent
    class Helloworld<RPC::Agent

      activate_when do
        File.executable?("/usr/bin/puppet")
      end
    end
  end
end
{% endhighlight %}

If this block returns false or raises an exception then the agent will not be active on
this machine and it will not be discovered.

When the agent gets loaded it will test if `/usr/bin/puppet` exist and only if it does
will this agent be enabled.

## Help and the Data Description Language
We have a separate file that goes together with an agent and is used to describe the agent in detail, a DDL file for the above echo agent can be seen below:

**NOTE**: As of version 2.1.1 the DDL files are required to be on the the nodes before an agent will be activated

{% highlight ruby linenos %}
metadata :name        => "echo",
         :description => "Echo service for MCollective",
         :author      => "R.I.Pienaar",
         :license     => "GPLv2",
         :version     => "1.1",
         :url         => "http://projects.puppetlabs.com/projects/mcollective-plugins/wiki",
         :timeout     => 60

action "echo", :description => "Echos back any message it receives" do
   input :msg,
         :prompt      => "Service Name",
         :description => "The service to get the status for",
         :type        => :string,
         :validation  => '^[a-zA-Z\-_\d]+$',
         :optional    => false,
         :maxlength   => 30

   output :msg,
          :description => "The message we received",
          :display_as  => "Message"
end
{% endhighlight %}

As you can see the DDL file expand on the basic syntax adding a lot of markup, help and other important validation data.  This information - when available - helps in making more robust clients and also potentially auto generating user interfaces.

The DDL is a complex topic, read all about it in [DDL].

## Validating Input
If you've followed the conventions and put the incoming data in a Hash structure then you can use a few of the provided validators to make sure your data that you received is what you expected.

If you didn't use Hashes for input the validators would not be usable to you.  In future validation will happen automatically based on the [DDL] so I strongly suggest you follow the agent design pattern shown here using hashes.

In the sample action above we validate the *:msg* input to be of type *String*, here are a few more examples:

{% highlight ruby linenos %}
   validate :msg, /[a-zA-Z]+/
   validate :ipaddr, :ipv4address
   validate :ipaddr, :ipv6address
   validate :commmand, :shellsafe
   validate :mode, ["all", "packages"]
{% endhighlight %}

The table below shows the validators we support currently

|Type of Check|Description|Example|
|-------------|-----------|-------|
|Regular Expressions|Matches the input against the supplied regular expression|validate :msg, /\[a-zA-Z\]+/|
|Type Checks|Verifies that input is of a given ruby data type|validate :msg, String|
|IPv4 Checks|Validates an ip v4 address, note 5.5.5.5 is technically a valid address|validate :ipaddr, :ipv4address|
|IPv6 Checks|Validates an ip v6 address|validate :ipaddr, :ipv6address|
|system call safety checks|Makes sure the input is a string and has no &gt;&lt;backtick, semi colon, dollar, ambersand or pipe characters in it|validate :command, :shellsafe|
|Boolean|Ensures a input value is either real boolean true or false|validate :enable, :bool|
|List of valid options|Ensures the input data is one of a list of known good values|validate :mode, \["all", "packages"\]|

All of these checks will raise an InvalidRPCData exception, you shouldn't catch this exception as the Simple RPC framework catches those and handles them appropriately.

We'll make input validators plugins so you can provide your own types of validation easily.

Additionally if can escape strings being passed to a shell, escaping is done in line with the `Shellwords#shellescape` method that is in newer version of Ruby:

{% highlight ruby linenos %}
   safe = shellescape(request[:foo])
{% endhighlight %}

As of version 2.2.0 you can add your own types of validation using [Validator Plugins][ValidatorPlugins].

## Agent Configuration

You can save configuration for your agents in the main server config file:

{% highlight ini %}
 plugin.helloworld.setting = foo
{% endhighlight %}

In your code you can retrieve the config setting like this:

{% highlight ini %}
 setting = config.pluginconf["helloworld.setting"] || ""
{% endhighlight %}

This will set the setting to whatever is the config file of "" if unset.

## Accessing the Input
As you see from the echo example our input is easy to get to by just looking in *request*, this would be a Hash of exactly what was sent in by the client in the original request.

The request object is in instance of *MCollective::RPC::Request*, you can also gain access to the following:

|Property|Description|
|--------|-----------|
|time|The time the message was sent|
|action|The action it is directed at|
|data|The actual hash of data|
|sender|The id of the sender|
|agent|Which agent it was directed at|

Since data is the actual Hash you can gain access to your input like:

{% highlight ruby %}
 request.data[:msg]
{% endhighlight %}

OR

{% highlight ruby %}
request[:msg]
{% endhighlight %}

Accessing it via the first will give you full access to all the normal Hash methods where the 2nd will only give you access to *include?*.

## Running Shell Commands

A helper function exist that makes it easier to run shell commands and gain
access to their `STDOUT` and `STDERR`.

We recommend everyone use this method for calling to shell commands as it forces
`LC_ALL` to `C` as well as wait on all the children and avoids zombies, you can
set unique working directories and shell environments that would be impossible
using simple `system` that is provided with Ruby.

The simplest case is just to run a command and send output back to the client:

{% highlight ruby %}
reply[:status] = run("echo 'hello world'", :stdout => :out, :stderr => :err)
{% endhighlight %}

Here you will have set `reply[:out]`, `reply[:err]` and `reply[:status]` based
on the output from the command.

You can append the output of the command to any string:

{% highlight ruby %}
out = []
err = ""
status = run("echo 'hello world'", :stdout => out, :stderr => err)
{% endhighlight %}

Here the STDOUT of the command will be saved in the variable `out` and not sent
back to the caller.  The only caveat is that the variables `out` and `err` should
have the `<<` method, so if you supplied an array each line of output will be a
single member of the array.  In the example `out` would be an array of lines
while `err` would just be a big multi line string.

By default any trailing new lines will be included in the output and error:

{% highlight ruby %}
reply[:status] = run("echo 'hello world'", :stdout => :out, :stderr => :err)
reply[:stdout].chomp!
reply[:stderr].chomp!
{% endhighlight %}

You can shorten this to:

{% highlight ruby %}
reply[:status] = run("echo 'hello world'", :stdout => :out, :stderr => :err, :chomp => true)
{% endhighlight %}

This will remove a trailing new line from the `reply[:out]` and `reply[:err]`.

If you wanted this command to run from the `/tmp` directory:

{% highlight ruby %}
reply[:status] = run("echo 'hello world'", :stdout => :out, :stderr => :err, :cwd => "/tmp")
{% endhighlight %}

Or if you wanted to include a shell Environment variable:

{% highlight ruby %}
reply[:status] = run("echo 'hello world'", :stdout => :out, :stderr => :err, :environment => {"FOO" => "BAR"})
{% endhighlight %}

The status returned will be the exit code from the program you ran, if the program
completely failed to run in the case where the file doesn't exist, resources were
not available etc the exit code will be -1

You have to set the cwd and environment through these options, do not simply
call `chdir` or adjust the `ENV` hash in an agent as that will not be safe in
the context of a multi threaded Ruby application.

## Constructing Replies

### Reply Data
The reply data is in the *reply* variable and is an instance of *MCollective::RPC::Reply*.

{% highlight ruby %}
reply[:msg] = request[:msg]
{% endhighlight %}

### Reply Status
As pointed out in the [ResultsandExceptions] page results all include status messages and the reply object has a helper to create those.

{% highlight ruby %}
def rmmsg_action
  validate :msg, String
  validate :msg, /[a-zA-Z]+-[a-zA-Z]+-[a-zA-Z]+-[a-zA-Z]+/
  reply.fail "No such message #{request[:msg]}", 1 unless have_msg?(request[:msg])

  # check all the validation passed before doing any work
  return unless reply.statuscode == 0

  # now remove the message from the queue
end

{% endhighlight %}

The number in `reply.fail` corresponds to the codes in [ResultsandExceptions] it would default to `1` so you could just say:

{% highlight ruby %}
reply.fail "No such message #{request[:msg]}" unless have_msg?(request[:msg])
{% endhighlight %}

This is hypothetical action that is supposed to remove a message from some queue, if we do have a String as input that matches our message id's we then check that we do have such a message and if we don't we fail with a helpful message.

Technically this will just set `statuscode` and `statusmsg` fields in the reply to appropriate values.

It won't actually raise exceptions or exit your action though you should do that yourself as in the example here.

There is also a `fail!` instead of just `fail` it does the same basic function but also raises exceptions.  This lets you abort processing of the agent immediately without performing your own checks on `statuscode` as above later on.

## Actions in external scripts
Actions can be implemented using other programming languages as long as they support JSON.

{% highlight ruby %}
action "test" do
  implemented_by "/some/external/script"
end
{% endhighlight %}

The script `/some/external/script` will be called with 2 arguments:

 * The path to a file with the request in JSON format
 * The path to a file where you should write your response as a JSON hash

You can also access these 2 file paths in the `MCOLLECTIVE_REPLY_FILE` and `MCOLLECTIVE_REQUEST_FILE` environment variables

Simply write your reply as a JSON hash into the reply file.

The exit code of your script should correspond to the ones in [ResultsandExceptions].  Any text in STDERR will be
logged on the server at `error` level and used in the text for the fail text.

Any text to STDOUT will be logged on the server at level `info`.

These scripts can be placed in a standard location:

{% highlight ruby %}
action "test" do
  implemented_by "script.py"
end
{% endhighlight %}

This will search each configured libdir for `libdir/agent/agent_name/script.py`. If you specified a full path it will not try to find the file in libdirs.

## Sharing code between agents
Sometimes you have code that is needed by multiple agents or shared between the agent and client.  MCollective has
name space called `MCollective::Util` for this kind of code and the packagers and so forth supports it.

Create a class with your shared code given a name like `MCollective::Util::Yourco` and save this file in the libdir in `util/yourco.rb`

A sample class can be seen here:

{% highlight ruby %}
module MCollective
  module Util
    class Yourco
      def dosomething
      end
    end
  end
end
{% endhighlight %}

You can now use it in your agent or clients by first loading it from the MCollective lib directories:

{% highlight ruby %}
MCollective::Util.loadclass("MCollective::Util::Yourco")

helpers = MCollective::Util::Yourco.new
helpers.dosomething
{% endhighlight %}

## Authorization
You can write a fine grained Authorization system to control access to actions and agents, please see [SimpleRPCAuthorization] for full details.

## Auditing
The actions that agents perform can be Audited by code you provide, potentially creating a centralized audit log of all actions.  See [SimpleRPCAuditing] for full details.

## Logging
You can write to the server log file using the normal logger class:

{% highlight ruby %}
Log.debug ("Hello from your agent")
{% endhighlight %}

You can log at levels `info`, `warn`, `debug`, `fatal` or `error`.

## Data Caching
As of version 2.2.0 there is a system wide Cache you can use to store data that might be costly to create on each request.

The Cache is thread safe and can be used even with multiple concurrent requests for the same agent.

Imagine your agent interacts with a customer database on the node that is slow to read data from but this data does not
change often. Using the cache you can arrange for this be read only every 10 minutes:

{% highlight ruby %}
action "get_customer_data" do
  # Create a new cache called 'customer' with a 600 second TTL,
  # noop if it already exist
  Cache.setup(:customer, 600)

  begin
    customer = Cache.read(:customer, request[:customerid])
  rescue
    customer = Cache.write(:customer, request[:customerid], get_customer(request[:customerid])
  end

  # do something with the customer data
end
{% endhighlight %}

Here we setup a new cache table called `:customer` if it does not already exist, the cache has a 10 minute validity.
We then try to read a cached customer record for `request[:customerid]` and if it's not been put in the cache
before or if it expired I create a new customer record using a method called `get_customer` and then save it
into the cache.

If you have critical code in an agent that can only ever be run once you can use the Mutex from the same cache
to synchronize the code:

{% highlight ruby %}
action "get_customer_data" do
  # Create a new cache called 'customer' with a 600 second TTL,
  # noop if it already exist
  Cache.setup(:customer, 600)

  Cache(:customer).synchronize do
     # Update customer record
  end
end
{% endhighlight %}

Here we are using the same Cache that was previously setup and just gaining access to the Mutex protecting the
cache data.  The code inside the synchronize block will only be run once so you won't get competing updates to
your customer data.

If the lock is held too long by anyone the mcollectived will kill the threads in line with the Agent timeout.

## Processing Hooks
We provide a few hooks into the processing of a message, you've already used this earlier to <a href="#Meta_Data_and_Initialization">set meta data</a>.

You'd use these hooks to add some functionality into the processing chain of agents, maybe you want to add extra logging for audit purposes of the raw incoming message and replies, these hooks will let you do that.

Hook Function Name                        | Description
------------------------------------------|------------------------------------------------------------------------------------------------------
`startup_hook`                            | Called at the end of the initialize method of the `RPC::Agent` base class
`before_processing_hook(msg, connection)` | Before processing of a message starts, pass in the raw message and the `MCollective::Connector` class
`after_processing_hook`                   | Just before the message is dispatched to the client

### `startup_hook`
Called at the end of the `RPC::Agent` standard initialize method use this to adjust meta parameters, timeouts and any setup you need to do.

This will not be called right when the daemon starts up, we use lazy loading and initialization so it will only be called the first time a request for this agent arrives.

### `before_processing_hook`
Called just after a message was received from the middleware before it gets passed to the handlers.  `request` and `reply` will already be set, the msg passed is the message as received from the normal mcollective runner and the connection is the actual connector.

You can in theory send off new messages over the connector maybe for auditing or something, probably limited use case in simple agents.

### `after_processing_hook`
Called at the end of processing just before the response gets sent to the middleware.

This gets run outside of the main exception handling block of the agent so you should handle any exceptions you could raise yourself.  The reason  it is outside of the block is so you'll have access to even status codes set by the exception handlers.  If you do raise an exception it will just be passed onto the runner and processing will fail.
