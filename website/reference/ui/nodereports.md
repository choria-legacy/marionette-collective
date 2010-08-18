---
layout: mcollective
title: Node Reports
disqus: true
---

# {{page.title}}

 * TOC Placeholder
 {:toc}

As we have all facts, classes and agents for nodes we can do some custom reporting on all of these.

We've added a tool - *mc-inventory* - that has a very simple scriptable report language.

**Note: This is an emerging feature, the scripting language is likely to change**

## Node View
To obtain a full inventory for a given node you can run mc-inventory like this:

{% highlight console %}
 % mc-inventory your.node.com
 Inventory for your.node.com:
 
    Agents:
       discovery       echo            nrpe           
       package         process         puppetd        
       rpctest         service                        
 
    Configuration Management Classes:
       aliases                        apache
       <snip>
 
    Facts:
       architecture => i386
       country => de
       culturemotd => 1
       customer => rip
       diskdrives => xvda
       <snip>
{% endhighlight %}

This gives you a good idea of all the details available for a node.

## Custom Reports

**NOTE: This feature will only be in version 1.0.0**

You can create little scriptlets and pass them into *mc-inventory* with the *--script* option.

You have the following data available to your reports:

<table>
<tr><th>Variable</th><th>Description</th></tr>
<tr><td>time</td><td>The time the report was started, normal Ruby Time object</td></tr>
<tr><td>identity</td><td>The sender id</td></tr>
<tr><td>facts</td><td>A hash of facts</td></tr>
<tr><td>agents</td><td>An array of agents</td></tr>
<tr><td>classes</td><td>An array of CF Classes</td></tr>
</table>

### printf style reports

Lets say you now need a report of all your IBM hardware listing hostname, serial number and product name you can write a scriptlet like this:

{% highlight ruby linenos %}
inventory do
    format "%s:\t\t%s\t\t%s"

    fields { [ identity, facts["serialnumber"], facts["productname"] ] }
end
{% endhighlight %}

And if saved as _inventory.mc_ run it like this:

{% highlight console %}
 % mc-inventory -W "productname=/IBM|BladeCenter/" --script inventory.mc
 xx12:           99xxx21         BladeCenter HS22 -[7870B3G]-
 xx9:            99xxx46         BladeCenter HS22 -[7870B3G]-
 xx10:           99xxx29         BladeCenter HS22 -[7870B3G]-
 yy1:            KDxxxFR         IBM System x3655 -[79855AY]-
 xx5:            99xxx85         IBM eServer BladeCenter HS21 -[8853GLG]-
 <snip>
{% endhighlight %}

We'll add more capabilities in the future, for now you can access *facts* as a hash, *agents* and *classes* as arrays as well as *identity* as a string.


### Perl format style reports
To use this you need to install the *formatr* gem, once that's installed you can create a report scriptlet like below:

{% highlight ruby linenos %}
formatted_inventory do
    page_length 20

    page_heading <<TOP

            Node Report @<<<<<<<<<<<<<<<<<<<<<<<<<
                        time

Hostname:         Customer:     Distribution:
-------------------------------------------------------------------------
TOP

    page_body <<BODY

@<<<<<<<<<<<<<<<< @<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
identity,    facts["customer"], facts["lsbdistdescription"]
                                @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                facts["processor0"]
BODY
end
{% endhighlight %}

Here we create a paged report - 20 nodes per page - with a heading section and a 2 line report per node with identity, customer, distribution and processor.

The output looks like this:

{% highlight console %}
 % mc-inventory -W "/dev_server/" --script inventory.mc
 
             Node Report Sun Aug 01 10:30:57 +0100
 
 Hostname:         Customer:     Distribution:
 -------------------------------------------------------------------------
 
 dev1.one.net      rip           CentOS release 5.5 (Final)
                                 AMD Athlon(tm) 64 X2 Dual Core Processor
 
 dev1.two.net      xxxxxxx       CentOS release 5.5 (Final)
                                 AMD Athlon(tm) 64 X2 Dual Core Processor
{% endhighlight %}

Writing these reports are pretty ugly I freely admit, however it avoids designing our own reporting engine and it's pretty good for kicking out simple reports.  You can see the *perlform* man page for details of the reporting layouts, ours is pretty close to that thanks to Formatr
