---
layout: normal
title: "MCollective Plugin: Facter via YAML"
---

# Overview


This method of accessing facts is what we recommend for Puppet users, it's faster and deals better with some strange issues in Facter.

Essentially we use Puppet to dump the data it gathers during normal runs into a YAML file and just use the MCollective YAML fact source to read this data.  This avoids an extreme slowdown from Facter running on every mcollective invocation, plus it lets you get any in-scope variables (for example, parameters from your external node classifier) available as mcollective filters for free. 

# Creating the YAML

In your Puppet manifests create a class similar to below: (Thanks to Dave Ta for this recipe, and to Jesse Throwe for the Ruby 1.9 fix)

<pre>
class mcollective::facts ()
{
  #The facts.yaml file resource is generated in its own dedicated class
  #By doing this, the file produced isn't polluted with unwanted in scope class variables.
 
  ##Bring in as many variables as you want from other classes here.
  #This makes them available to mcollective for use in filters.
  #eg
  #$class_variable = $class::variable
 
  #mcollective doesn't work with arrays, so use the puppet-stdlib join function
  #eg
  #$ntp_servers = join($ntp::servers, ",")
 
  file{'/etc/mcollective/facts.yaml':
   owner    => root,
   group    => root,
   mode     => 400,
   content => template('mcollective/facts.yaml.erb'),
  }
}
</pre>


## facts.yaml.erb
<pre>
<%=
    # remove dynamic facts
    obj = scope.to_hash.reject {|k,v| k.to_s =~ /^(uptime.*|rubysitedir|_timestamp|memoryfree.*|swapfree.*|title|name|caller_module_name|module_name)$/ }

    arr = obj.sort
    out = "---\n"
    arr.each do |element|
      entry = {element[0] => element[1]}
      out += entry.to_yaml.split(/\n/)[1..-1].join("\n") + "\n"
    end

    out
%>
</pre>

Apply this to all the nodes that run MCollective.

# Configure MCollective

Add the following lines to <em>server.cfg</em>

<pre>
factsource = yaml
plugin.yaml = /etc/mcollective/facts.yaml
</pre>

# Verify

<pre>
% mc-inventory some.node
Inventory for some.node:

   Server Statistics:
                      Version: 0.4.10
                   Start Time: Mon Nov 29 16:38:28 +0000 2010
                  Config File: /etc/mcollective/server.cfg
                   Process ID: 5387
               Total Messages: 9254
      Messages Passed Filters: 6443
            Messages Filtered: 2811
                 Replies Sent: 6442
         Total Processor Time: 23.27 seconds
                  System Time: 6.19 seconds

<snip>

   Facts:
      architecture => i386
      clientcert => some.node
      clientversion => 2.6.3
      country => de
</pre>
