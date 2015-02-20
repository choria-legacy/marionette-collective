---
layout: default
title: Aggregate Plugins
---
[DDL]: /mcollective/reference/plugins/ddl.html
[Examples]: https://github.com/puppetlabs/marionette-collective/tree/master/lib/mcollective/aggregate

## Overview
MCollective Agents return data and we try to provide as much usable user
interface for free. To aid in this we require agents to have [DDL][] files that
describe the data that the agent returns.

DDL files are used to configure the client but also to assist with user
interface generation.  They are used to ask questions that an action needs but
also to render the results when the replies come in.  For example we turn
*:freecpu* into "Free CPU" when displaying the data based on the DDL.

Previously if data that agents returned required any summarization this had to
be done using a custom application.  Here is an example from *mco nrpe*:

{% highlight console %}
% mco nrpe check_load
.
.
Finished processing 25 / 25 hosts in 556.48 ms

              OK: 25
         WARNING: 0
        CRITICAL: 0
         UNKNOWN: 0
{% endhighlight %}

Here to get the summary of results displayed in a way that has contextual
relevance to the nrpe plugin a custom application had to be written and anyone
who interacts with the agent using other RPC clients would not get the benefit
of this summary.

By using aggregate plugins and updating the DDL we can now provide such a
summary in all result sets and display it using the *mco rpc* application and
any calls to *printrpc*.

{% highlight console %}
% mco rpc nrpe runcommand command=check_load
Discovering hosts using the mongo method .... 25

 * [============================================================> ] 25 / 25

Summary of Exit Code:

            OK : 25
       WARNING : 0
       UNKNOWN : 0
      CRITICAL : 0


Finished processing 25 / 25 hosts in 390.70 ms
{% endhighlight %}

Here you get a similar summary as before, all that had to be done was a simple
aggregate plugin be written and distributed with your clients.

The results are shown as above using *printrpcstats* but you can also get access to
the raw data so you can decide to render it in some other way - perhaps using a
graph on a web interface.

We provide a number of aggregate plugins with MCollective and anyone can write
more.

For examples that already use functions see the *rpcutil* agent - its
*collective_info*, *get_fact*, *daemon_stats* and *get_config_item* actions all
have summaries applied.

*NOTE:* This feature is available since version 2.1.0

## Using existing plugins

### Updating the DDL
At present MCollective supplies 3 plugins *average()*, *summary()* and *sum()*
you can use these in any agent, here is an example from the *rpcutil* agent DDL
file:

{% highlight ruby %}
action "get_config_item", :description => "Get the active value of a specific config property" do
    output :value,
           :description => "The value that is in use",
           :display_as => "Value"

    summarize do
        aggregate summary(:value)
    end
end
{% endhighlight %}

We've removed a few lines from this example DDL block leaving only the relevant
lines.  You can see the agent outputs data called *:value* and we reference that
output in the summary function *summary(:value)*, the result would look like
this:

### Viewing summaries on the CLI
{% highlight console %}
% mco rpc rpcutil get_config_item item=collectives
.
.
dev8
   Property: collectives
      Value: ["mcollective", "uk_collective"]

Summary of Value:

      mcollective = 25
    uk_collective = 15
    fr_collective = 9
    us_collective = 1

Finished processing 25 / 25 hosts in 349.70 ms
{% endhighlight %}

You can see that the value in this case contains arrays, the *summary()*
function produce the table in the output showing the data distribution.

### Producing summaries in your own clients
You can enable the same display in your own code, here is ruby code that has the
same affect as the CLI call above:

{% highlight ruby %}
require 'mcollective'

include MCollective::RPC

c = rpcclient("rpcutil")

printrpc c.get_config_item(:item => "collectives")

printrpcstats :summarize => true
{% endhighlight %}

Without passing in the *:summarize => true* you would not see the summaries

### Getting access to the raw summary results
If you wanted to do something else entirely like produce a graph on a web page
of the summaries you can get access to the raw data, here's some ruby code to
show all computed summaries:

{% highlight ruby %}
require 'mcollective'

include MCollective::RPC

c = rpcclient("rpcutil")
c.progress = false

c.get_config_item(:item => "collectives")

c.stats.aggregate_summary.each do |summary|
  puts "Summary of type: %s" % summary.result_type
  puts "Display format: '%s'" % summary.aggregate_format
  puts
  pp summary.result
end
{% endhighlight %}

As you can see you will get an array of summaries this is because each DDL can
use many aggregate calls, this would be an array of all the computed summaries:

{% highlight console %}
Summary of type: collection
Display format: '%13s = %s'

{:type=>:collection,
 :value=>
  {"mcollective"=>25,
   "fr_collective"=>9,
   "us_collective"=>1,
   "uk_collective"=>15},
 :output=>:value}
{% endhighlight %}

There are 2 types of result *:collection* and *:numeric*, in the case of numeric
results the :value would just be a number.

The *aggregate_format* is either a user supplied format or a dynamically
computed format to display the summary results on the console.  In this case
each pair of the hash should be displayed using the format to produce a nice
right justified list of keys and values.

## Writing your own function
We'll cover writing your own function by looking at the Nagios one from earlier
in this example.  You can look at [the functions supplied with
MCollective][Examples] for more examples using other types than the one below.

First lets look at the DDL for the existing *nrpe* Agent:

{% highlight ruby %}
action "runcommand", :description => "Run a NRPE command" do
    input :command,
          :prompt      => "Command",
          :description => "NRPE command to run",
          :type        => :string,
          :validation  => '\A[a-zA-Z0-9_-]+\z',
          :optional    => false,
          :maxlength   => 50

    output :output,
           :description => "Output from the Nagios plugin",
           :display_as  => "Output",
           :default     => ""

    output :exitcode,
           :description  => "Exit Code from the Nagios plugin",
           :display_as   => "Exit Code",
           :default      => 3

    output :perfdata,
           :description  => "Performance Data from the Nagios plugin",
           :display_as   => "Performance Data",
           :default      => ""
end
{% endhighlight %}

You can see it will return an *:exitcode* item and from the default value you
can gather this is going to be a number.  Nagios defines 4 possibly exit codes
for a Nagios plugin and we need to convert this *:exitcode* into a string like
WARNING, CRITICAL, UNKNOWN or OK.

Usually when writing any kind of summarizer for an array of results your code
might contain 3 phases.

Given a series of Nagios results like this:

{% highlight ruby %}
[
 {:exitcode => 0, :output => "OK", :perfdata => ""},
 {:exitcode => 2, :output => "failure", :perfdata => ""}
]
{% endhighlight %}

You would write a nagios_states() function that does roughly this:

{% highlight ruby %}
def nagios_states(results)
  # set initial values
  result = {}
  status_map = ["OK", "WARNING", "CRITICAL", "UNKNOWN"]
  status_map.each {|s| result[s] = 0}

  # loop over all the data, increment the count for OK etc
  results.each do |result|
    status = status_map[result[:exitcode]]
    result[status] += 1
  end

  # return the result hash, {"OK" => 1, "CRITICAL" => 1, "WARN" => 0, "UNKNOWN" => 0}
  return result
end
{% endhighlight %}

You could optimise the code but you can see there are 3 major stages in the life
of this code.

 * Set initial values for the return data
 * Loop the data building up the state
 * Return the data.

Given this, here is our Nagios exitcode summary function, it is roughly the same
code with a bit more boiler plate to plugin into mcollective, but the same code
can be seen:

{% highlight ruby %}
module MCollective
  class Aggregate
    class Nagios_states<Base
      # Before function is run processing
      def startup_hook
        # :collection or :numeric
        @result[:type] = :collection

        # set default aggregate_format if it is undefined
        @aggregate_format = "%10s : %s" unless @aggregate_format

        @result[:value] = {}

        @status_map = ["OK", "WARNING", "CRITICAL", "UNKNOWN"]
        @status_map.each {|s| @result[:value][s] = 0}

      end

      # Determines the average of a set of numerical values
      def process_result(value, reply)
        if value
          status = @status_map[value]
          @result[:value][status] += 1
        else
          @result["UNKNOWN"] += 1
        end
      end

      # Post processing hook that returns the summary result
      def summarize
        result_class(@result[:type]).new(@result, @aggregate_format, @action)
      end
    end
  end
end
{% endhighlight %}

This shows that an aggregate function has the same 3 basic parts.  First we set
the initial state using the *startup_hook*.  We then process each result as it
comes in from the network using *process_result*.  Finally we turn that into a
the result objects that you saw earlier in the ruby client examples using the
*summarize* method.

### *startup_hook*
Each function needs a startup hook, without one you'll get exceptions.  The
startup hook lets you set up the initial state.

The first thing to do is set the type of result this will be.  Currently we
support 2 types of result either a plain number indicated using *:numeric* or a
complex *:collection* type that can be a hash with keys and values.

Functions can take display formats in the DDL, in this example we set
*@aggregate_format* to a *printf* default that would display a table of results
but we still let the user supply his own format.

We then just initialize the result hash to and build a map from the English
representation of the Nagios status codes.

### *process_result*
Every reply that comes in from the network gets passed into your
*process_result* method.  The first argument will be just the single value the
DDL indicates you are interested in but you'll also get the whole rely so you
can get access to other reply values and such.

This gets called each time, we just look at the value and increment each Nagios
status or treat it as an unknown - in case the result data is missformed.

### *summarize*
The summarize method lets you take the state you built up and convert that into
an answer.  The summarize method is optional what you see here is the default
action if you do not supply one.

The *result_class* method accepts either *:collection* or *:numeric* as
arguments and it is basically a factory for the correct result structure.

### Deploy and update the DDL
You should deploy this function into your *libdir/aggregate* directory called
*nagios_states.rb* on the client machines - no harm deploying it everywhere
though.

Update the DDL so it looks like:

{% highlight ruby %}
action "runcommand", :description => "Run a NRPE command" do
    .
    .
    .

    if respond_to?(:summarize)
        summarize do
            aggregate nagios_states(:exitcode)
        end
    end
end
{% endhighlight %}

Add the last few lines - we check that we're running in a version of MCollective
that supports this feature and then we call our function with the *:exitcode*
results.
