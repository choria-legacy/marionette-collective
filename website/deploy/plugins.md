---
layout: default
title: "MCollective » Deploy » Installing Plugins"
Subtitle: "Installing and Packaging MCollective Plugins"
---

[puppet_agent]: https://github.com/puppetlabs/mcollective-puppet-agent
[server_config]: /mcollective/configure/server.html
[client_config]: /mcollective/configure/client.html
[servers]: /mcollective/overview_components.html#servers
[clients]: /mcollective/overview_components.html#clients
[puppetlabs_repos]: /guides/puppetlabs_package_repositories.html
[libdir_onpage]: #copying-plugins-into-the-libdir
[makepackages_onpage]: #packaging-custom-plugins
[verify_onpage]: #verifying-installed-agent-plugins
[types_onpage]: #about-plugins--available-plugin-types
[choria]: http://choria.io/

Summary
-----

MCollective has several kinds of plugins (most notably **agents** and **applications**), all of which go in the directory specified by the `libdir` setting from the [server][server_config] and [client][client_config] config files.

Pre-built packages are no longer provided in [the Puppet Labs apt and yum repos][puppetlabs_repos]. Installation via Puppet modules is preferred, and can be facilitated by [the Choria project][choria]. Puppet Enterprise comes with a predefined set of plugins.

Not all plugins can be installed with those methods, so alternatively you can:

* [Put files directly into the libdir][libdir_onpage]

You may also want to:

* [Create packages from your own plugins][makepackages_onpage]


### About Plugins / Available Plugin Types

Most of what MCollective actually does is handled via a plugin. Each kind of plugin may need to be installed on [servers][], [clients][], or both.

Type           | Which systems               | Function
---------------|-----------------------------|-------------------------------------------------------------------------
agent          | servers, clients (DDL only) | Executing actions
aggregate      | clients                     | Formatting results
application    | clients                     | CLI subcommands (for sending requests, etc.)
audit          | servers                     | Logging actions
connector      | servers, clients            | Interfacing with middleware
data           | servers, clients (DDL only) | Enabling new kinds of metadata for filtering
discovery      | clients                     | Acquiring a list of nodes that match a filter
facts          | servers                     | Enabling fact metadata for filtering
pluginpackager | clients                     | Building OS-appropriate packages to install other plugins
registration   | servers                     | Sending heartbeat and metadata to some form of inventory database
security       | servers, clients            | Serializing and validating messages
util           | servers, clients            | Various, usually supporting other plugins; includes authorization plugins
validator      | servers, clients            | Validating input formats before sending a request

This may seem like a lot to manage, but the general experience is:

* Most users write custom agent plugins.
    * Validator and aggregate plugins can be useful when writing advanced agents.
* Many users write _some_ application plugins, but most agents don't need anything beyond the built-in `rpc` application.
* Custom discovery and data plugins can useful if you need faster or more versatile discovery, but aren't necessary if the existing discovery features suit you.
* It's rare to write or install custom plugins of the other types.


Copying Plugins Into the Libdir
-----

For older agent plugins, certain non-agent plugins (such as authorization), and most custom plugins, you will need to install by copying files directly into MCollective's `libdir`.

### About the Libdir

All MCollective plugins belong in the `libdir`, which is specified by the setting of the same name in the [client][client_config] and [server][server_config] config files.

The default libdir created by the MCollective install process varies per platform:

Platform          | Default libdir
------------------|---------------------------------
Windows           | `C:\ProgramData\Puppetlabs\mcollective\plugins`
Other             | `/opt/puppetlabs/mcollective/plugins`

The libdir is arranged like a standard Ruby lib directory: It always contains a single directory called `mcollective`, which contains a directory for each [type of plugin (see above)][types_onpage]; each of these directories contains any number of `.rb` and `.ddl` (and sometimes `.erb`) files.

In the general case, this means plugin files should be named `<LIBDIR>/mcollective/<TYPE>/<NAME>.(rb|ddl|erb)`. The `util` directory may include some extra directory levels.

As an example, here are the platform-appropriate destinations for two of the files installed by the `package` agent:

* On Windows systems:
    * `C:\ProgramData\Puppetlabs\mcollective\plugins\mcollective\agent\package.rb`
    * `C:\ProgramData\Puppetlabs\mcollective\plugins\mcollective\agent\package.ddl`
* On other systems:
    * `/opt/puppetlabs/mcollective/plugins/mcollective/agent/package.rb`
    * `/opt/puppetlabs/mcollective/plugins/mcollective/agent/package.ddl`

> **Note:** The `mcollective` directory goes _inside_ the libdir, whatever the libdir's path is. In the Red Hat case, this means the complete path contains the string `mcollective/mcollective`; be careful not to accidentally skip the second `mcollective`.

### Copying From Source

Most public MCollective plugins are developed and published in a source repository (e.g. on GitHub) that mimics the structure of the `<LIBDIR>/mcollective` directory --- that is, the repo will have an `agent` directory, an `application` directory, etc. You can ignore any Rakefiles, READMEs, or `spec` directories.

If you come across a repository that has `lib` at the top level you
will need to treat lib/mcollective as the repository root and then
continue with the following instructions.

> **Note:** Servers and clients will not need every file for a given _plugin set_ --- you can consult [the plugin types table above][types_onpage] to see which parts should go where.
>
> Alternately, you can just copy everything in the plugin's repo to every client and server --- nothing bad will happen from installing unused components.

1. **Copy** every file in the plugin source (or just the server-appropriate files) to the corresponding location in the libdir of each [server][servers] node that should have it. E.g. `agent/package.rb` should be copied to `<LIBDIR>/mcollective/agent/package.rb`, etc.
    * Since this must happen across a large number of servers, you should generally use Puppet or other configuration management to copy the files.
2. **Restart** the `mcollective` server daemon on every server.
3. **Copy** every file in the plugin source (or just the client-appropriate files) to the corresponding location in each [client][clients] system's libdir.
    * Since client systems are often admin or developer workstations, this may or may not be automatable; at the least, you should maintain a list of which plugins are in use at your site, so that your admins can keep their clients up to date.
4. Optionally, [**verify** the installation][verify_onpage] on some proportion of your clients and servers.


### Example

To demonstrate, this is what you would do to install the [puppet agent plugin][puppet_agent] on a collection of Red Hat-like servers and clients.

The [repository][puppet_agent] for the puppet plugin set is laid out as follows:

    ├── CHANGELOG.md
    ├── README.md
    ├── Rakefile
    ├── agent
    │   ├── puppet.ddl
    │   └── puppet.rb
    ├── aggregate
    │   ├── boolean_summary.ddl
    │   └── boolean_summary.rb
    ├── application
    │   └── puppet.rb
    ├── data
    │   ├── puppet_data.ddl
    │   ├── puppet_data.rb
    │   ├── resource_data.ddl
    │   └── resource_data.rb
    ├── spec
    │   ├── agent
    │   │   └── puppet_agent_spec.rb
    │   ├── aggregate
    │   │   └── boolean_summary_spec.rb
    │   ├── application
    │   │   └── puppet_spec.rb
    │   ├── data
    │   │   ├── puppet_data_spec.rb
    │   │   └── resource_data_spec.rb
    │   ├── fixtures
    │   │   └── last_run_summary.yaml
    │   ├── spec.opts
    │   ├── spec_helper.rb
    │   ├── util
    │   │   ├── puppet_agent_mgr
    │   │   │   └── common_spec.rb
    │   │   ├── puppet_agent_mgr_spec.rb
    │   │   ├── puppetrunner_spec.rb
    │   │   ├── v2
    │   │   │   ├── manager_spec.rb
    │   │   │   └── unix_spec.rb
    │   │   └── v3
    │   │       ├── manager_spec.rb
    │   │       └── unix_spec.rb
    │   └── validator
    │       ├── puppet_resource_validator_spec.rb
    │       ├── puppet_server_address_validator_spec.rb
    │       ├── puppet_tags_validator_spec.rb
    │       └── puppet_variable_validator_spec.rb
    ├── util
    │   ├── puppet_agent_mgr
    │   │   ├── common.rb
    │   │   ├── v2
    │   │   │   ├── manager.rb
    │   │   │   ├── unix.rb
    │   │   │   └── windows.rb
    │   │   └── v3
    │   │       ├── manager.rb
    │   │       ├── unix.rb
    │   │       └── windows.rb
    │   ├── puppet_agent_mgr.rb
    │   └── puppetrunner.rb
    └── validator
        ├── puppet_resource_validator.ddl
        ├── puppet_resource_validator.rb
        ├── puppet_server_address_validator.ddl
        ├── puppet_server_address_validator.rb
        ├── puppet_tags_validator.ddl
        ├── puppet_tags_validator.rb
        ├── puppet_variable_validator.ddl
        └── puppet_variable_validator.rb

On Red Hat-like OSes, you would install these files in the following locations:

#### Servers

    /opt/puppetlabs/mcollective/plugins/mcollective/agent/puppet.ddl
    /opt/puppetlabs/mcollective/plugins/mcollective/agent/puppet.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/data/puppet_data.ddl
    /opt/puppetlabs/mcollective/plugins/mcollective/data/puppet_data.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/data/resource_data.ddl
    /opt/puppetlabs/mcollective/plugins/mcollective/data/resource_data.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/util/puppet_agent_mgr/common.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/util/puppet_agent_mgr/v2/manager.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/util/puppet_agent_mgr/v2/unix.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/util/puppet_agent_mgr/v2/windows.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/util/puppet_agent_mgr/v3/manager.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/util/puppet_agent_mgr/v3/unix.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/util/puppet_agent_mgr/v3/windows.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/util/puppet_agent_mgr.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/util/puppetrunner.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/validator/puppet_resource_validator.ddl
    /opt/puppetlabs/mcollective/plugins/mcollective/validator/puppet_resource_validator.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/validator/puppet_server_address_validator.ddl
    /opt/puppetlabs/mcollective/plugins/mcollective/validator/puppet_server_address_validator.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/validator/puppet_tags_validator.ddl
    /opt/puppetlabs/mcollective/plugins/mcollective/validator/puppet_tags_validator.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/validator/puppet_variable_validator.ddl
    /opt/puppetlabs/mcollective/plugins/mcollective/validator/puppet_variable_validator.rb


#### Clients

    /opt/puppetlabs/mcollective/plugins/mcollective/agent/puppet.ddl
    /opt/puppetlabs/mcollective/plugins/mcollective/aggregate/boolean_summary.ddl
    /opt/puppetlabs/mcollective/plugins/mcollective/aggregate/boolean_summary.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/application/puppet.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/data/puppet_data.ddl
    /opt/puppetlabs/mcollective/plugins/mcollective/data/resource_data.ddl
    /opt/puppetlabs/mcollective/plugins/mcollective/util/puppet_agent_mgr/common.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/util/puppet_agent_mgr/v2/manager.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/util/puppet_agent_mgr/v2/unix.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/util/puppet_agent_mgr/v2/windows.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/util/puppet_agent_mgr/v3/manager.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/util/puppet_agent_mgr/v3/unix.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/util/puppet_agent_mgr/v3/windows.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/util/puppet_agent_mgr.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/util/puppetrunner.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/validator/puppet_resource_validator.ddl
    /opt/puppetlabs/mcollective/plugins/mcollective/validator/puppet_resource_validator.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/validator/puppet_server_address_validator.ddl
    /opt/puppetlabs/mcollective/plugins/mcollective/validator/puppet_server_address_validator.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/validator/puppet_tags_validator.ddl
    /opt/puppetlabs/mcollective/plugins/mcollective/validator/puppet_tags_validator.rb
    /opt/puppetlabs/mcollective/plugins/mcollective/validator/puppet_variable_validator.ddl
    /opt/puppetlabs/mcollective/plugins/mcollective/validator/puppet_variable_validator.rb


Packaging Custom Plugins
-----

You can use the `mco plugin package` command to generate OS-appropriate packages (limited to Red Hat and Debian-like systems) for your own agent plugins.

[The Choria project][choria] can also be used with `mco plugin package` to generate Puppet modules for plugins.

Note that the packaging tool uses each system's native tools to build packages --- it doesn't necessarily support building, for example, .deb and .rpm packages on a Mac.


Verifying Installed Agent Plugins
-----

To verify that an **agent plugin** is correctly installed you can do the following. (Verifying other types of plugins can be harder; we suggest looking in the debug logs)

### Check List of Agents

The `mco inventory <NODE NAME>` command includes a list of the agents installed on the node:

{% highlight console %}
$ mco inventory some.node
Inventory for some.node:

   Server Statistics:
                      Version: 0.4.10
                   Start Time: Mon Nov 29 16:38:28 +0000 2010
                  Config File: /etc/mcollective/server.cfg
                   Process ID: 5387
               Total Messages: 10196
      Messages Passed Filters: 7108
            Messages Filtered: 3088
                 Replies Sent: 7107
         Total Processor Time: 25.95 seconds
                  System Time: 7.0 seconds

   Agents:
      cassandrabackup discovery       echo
      filemgr         nrpe            package
      process         puppetd         rpchelper
      rpctest         rpcutil         service
{% endhighlight %}

### Check Agent Version Info

You can also use the `agent_inventory` action of the `rpcutil` agent to see more complete info for each agent:


{% highlight console %}
$ mco rpc rpcutil agent_inventory -I some.node
Determining the amount of hosts matching filter for 2 seconds .... 1

 * [ ============================================================> ] 1 / 1


some.node:
   Agents:
        [{:url=>"https://docs.puppetlabs.com/mcollective/",
          :version=>"1.0",
          :name=>"Utilities and Helpers for SimpleRPC Agents",
          :agent=>"rpcutil",
          :description=> "General helpful actions that expose stats and internals to SimpleRPC clients",
          :author=>"R.I.Pienaar <rip@devco.net>",
          :timeout=>3,
          :license=>"Apache License, Version 2.0"}]

Finished processing 1 / 1 hosts in 100.70 ms
{% endhighlight %}

### Check Agent Docs on Client

On the client, if you installed a DDL file, you can look up the help for an agent:

{% highlight console %}
$ mco plugin doc rpcutil
Utilities and Helpers for SimpleRPC Agents
==========================================

General helpful actions that expose stats and internals to SimpleRPC clients

      Author: R.I.Pienaar <rip@devco.net>
     Version: 1.0
     License: Apache License, Version 2.0
     Timeout: 3
   Home Page: https://docs.puppetlabs.com/mcollective/



ACTIONS:
========
   agent_inventory, daemon_stats, get_config_item, get_fact, inventory

   agent_inventory action:
   -----------------------
       Inventory of all agents on the server

       INPUT:

       OUTPUT:
           agents:
              Description: List of agents on the server
               Display As: Agents
{% endhighlight %}

### Examine Debug Output in Log File

[log_settings]: /mcollective/configure/server.html#logging

If you start the server daemon with a `loglevel` setting of `debug`, the log (usually the file specified by [the `logfile` setting][log_settings]) should contain a bunch of lines like:

    D, [2010-11-30T21:33:33.144290 #5753] DEBUG -- : 5753 pluginmanager.rb:83:in `loadclass': Loading MCollective::Agent::Service from mcollective/agent/service.rb
    D, [2010-11-30T21:33:33.144786 #5753] DEBUG -- : 5753 pluginmanager.rb:36:in `<<': Registering plugin service_agent with class MCollective::Agent::Service
    D, [2010-11-30T21:33:33.144928 #5753] DEBUG -- : 5753 stomp.rb:150:in `subscribe': Subscribing to /topic/mcollective.service.command


### Check Presence of Agent Across All Nodes

Finally, since agents are a common filter criteria, you can find all nodes that are running your agent:

{% highlight console %}
$ mco find -A someagent
host1.example.com
host2.example.com
host3.example.com
{% endhighlight %}
