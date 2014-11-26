---
layout: default
title: Writing Fact Plugins
toc: false
---
[SimpleRPCAuthorization]: /mcollective/simplerpc/authorization.html
[Registration]: registration.html

Fact plugins are used during discovery whenever you run the agent with queries like *-W country=de*.

The default setup uses a YAML file typically stored in */etc/puppetlabs/agent/mcollective/facts.yaml* to read facts; usually, you'll configure Puppet or a background task to write this file using data from Facter. If you're using some other tool to profile system data, you can either configure it to write a similar YAML file or write a **fact plugin** to access that tool directly.

Facts at the moment should be simple *variable = value* style flat hashes, where `value` is a string; structured facts aren't supported.

## Details
Implementing a facts plugin is made simple by inheriting from *MCollective::Facts::Base*, in that case you just need to provide 1 method, the YAML plugin code can be seen below:

For releases in the 1.0.x release cycle and older, use this plugin format:

{% highlight ruby linenos %}
module MCollective
    module Facts
        require 'yaml'

        # A factsource that reads a hash of facts from a YAML file
        class Yaml<Base
            def self.get_facts
                config = MCollective::Config.instance

                facts = {}

                YAML.load_file(config.pluginconf["yaml"]).each_pair do |k, v|
                    facts[k] = v.to_s
                end

                facts
            end
        end
    end
end
{% endhighlight %}

For releases 1.1.x and onward use this format:

{% highlight ruby linenos %}
module MCollective
    module Facts
        require 'yaml'

        class Yaml_facts<Base
            def load_facts_from_source
                config = MCollective::Config.instance

                facts = {}

                YAML.load_file(config.pluginconf["yaml"]).each_pair do |k, v|
                    facts[k] = v.to_s
                end

                facts
            end
        end
    end
end
{% endhighlight %}

If using the newer format in newer releases of mcollective you do not need to worry about caching or
thread safety as the base class does this for you.  You can force reloading of facts by creating a
*force_reload?* method that should return *true* or *false*.  Returning *true* will force the cache
to be rebuilt.

You can see that all you have to do is provide *self.get_facts* which should return a Hash as described above.

There's a sample using Puppet Labs Facter on the plugins project if you wish to see an example that queries an external fact source.

Once you've written your plugin you can save it in the plugins directory and configure mcollective to use it:

{% highlight ini %}
factsource = yaml
{% endhighlight %}

This will result in *MCollective::Facts::Yaml* or *MCollective::Facts::Yaml_facts* being used as source for your facts.
