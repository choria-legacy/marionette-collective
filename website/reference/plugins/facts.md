---
layout: mcollective
title: Writing Fact Plugins
disqus: true
---
[SimpleRPCAuthorization]: /simplerpc/authorization.html
[Registration]: registration.html

## {{page.title}}

Fact plugins are used during discovery whenever you run the agent with queries like *-W country=de*.

The default setup uses a YAML file typically stored in */etc/mcollective/facts.yaml* to read facts.  There are however many fact systems like Reductive Labs Facter and Opscode Ohai or you can come up with your own.  The facts plugin type lets you write code to access these tools.

Facts at the moment should be simple *variable = value* style flat Hashes, if you have a hierarchical fact system like Ohai you can flatten them into *var.subvar = value* style variables.

### Details
Implementing a facts plugin is made simple by inheriting from *MCollective::Facts::Base*, in that case you just need to provide 1 method, the YAML plugin code can be seen below:

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

You can see that all you have to do is provide *self.get_facts* which should return a Hash as described above.

Important to note that we only support strings for fact values, in this example we force all values in the YAML file to string since discovery from the client can only be done based on strings.

There's a sample using Reductive Labs Facter on the plugins project if you wish to see an example that queries an external fact source.

Once you've written your plugin you can save it in the plugins directory and configure mcollective to use it:

{% highlight ini %}
factsource = yaml
{% endhighlight %}

This will result in *MCollective::Facts::Yaml* being used as source for your facts.
