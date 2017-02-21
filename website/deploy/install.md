---
title: "Install MCollective"
layout: default
---

[pe_orchestration]: {{pe}}/orchestration_overview.html
[pe_install]: {{pe}}/install_basic.html
[mco_tags]: https://github.com/puppetlabs/marionette-collective/tags
[git_repo]: https://github.com/puppetlabs/marionette-collective
[server_config_best_practices]: /mcollective/configure/server.html#best-practices
[init_lsb]: https://github.com/puppetlabs/marionette-collective/blob/master/mcollective.init
[init_debian]: https://github.com/puppetlabs/marionette-collective/blob/master/ext/debian/mcollective.init
[init_redhat]: https://github.com/puppetlabs/marionette-collective/blob/master/ext/redhat/mcollective.init
[standard]: ./standard.html
[middleware]: ./middleware/
[activemq_connector]: /mcollective/reference/plugins/connector_activemq.html
[activemq_port_config]: /mcollective/deploy/middleware/activemq.html#transport-connectors
[config_server]: /mcollective/configure/server.html
[config_client]: /mcollective/configure/client.html
[deploy_plugins]: ./plugins.html
[enable_repos]: {{puppet}}/reference/puppet_collections.html
[server_libdir]: /mcollective/configure/server.html#platform-defaults
[client_libdir]: /mcollective/configure/client.html#platform-defaults
[deploy]: ./index.html
[semver]: http://semver.org
[puppet-agent]: {{puppet}}/reference/about_agent.html

> **Note:** This page is about installing MCollective, which is part of the larger deployment process. See the [MCollective deployment index][deploy] for the complete picture.
>
> Puppet Enterprise includes MCollective and automates the deployment process. See its [orchestration documentation][pe_orchestration] for details about using MCollective to orchestrate your Puppet Enterprise infrastructure, and its [installation instructions][pe_install] for help installing PE.
>
> For the versions of Puppet agent components that ship with Puppet Enterprise, including the version of MCollective, see [What Gets Installed and Where]({{pe}}/install_what_and_where.html#agent-components-on-all-nodes). For the components shipped with open source Puppet, see [About Puppet Agent][puppet-agent].

To install MCollective:

1.  Install and start your middleware, and configure your firewalls. See the [pre-install instructions](#pre-install) for details.
2.  Install the `puppet-agent` package on servers, and then make sure the `mcollective` service is running.
3.  Install the `puppet-agent` package on admin workstations.

Most Debian-like and Red Hat-like systems, as well as Windows and macOS, can [use the official `puppet-agent` package](#installing-with-the-official-packages) to install MCollective and other Puppet components and prerequisites.

If your systems can't use the official package, [check the system requirements](#system-requirements) and either [build your own](#rolling-custom-rpm-and-debian-packages) or [run from source](#running-from-source).

### Best practices

Use site-wide configuration management software to install and configure MCollective. Since you'll need to install the server daemon on every node in your deployment, and since you'll want each node to be running the same version, you should generally use Puppet or something like it to install MCollective.

### Semantic versioning

All of our open source projects --- including Puppet, Puppet Server, PuppetDB, Facter, and Hiera --- use [semantic versioning ("semver")][semver] for their version numbers. This means that in an `x.y.z` version number, the "y" increases if new features are introduced and the "x" increases if existing features change or get removed.

Our semver promises only refer to the code in a single project; it's possible for packaging or interactions with new "y" releases of other projects to cause new behavior in a "z" upgrade of Puppet.

> **Historical note:** In Puppet versions prior to 3.0.0 and Facter versions prior to 1.7.0, we didn't use semantic versioning.

## Pre-install

1.  Deploy your [middleware system][middleware] before installing MCollective.
2.  Make sure each server's firewall allows MCollective to initiate connections with the middleware server. The port depends on your deployment plan; with the recommended [ActiveMQ connector][activemq_connector], this is usually either 61614 for Stomp/TLS (recommended) or 61613 for unencrypted Stomp, depending on [how you configured ActiveMQ's transport connectors][activemq_port_config].

{% capture postinstall %}[configure the server daemon][config_server], [configure admin workstations][config_client], and [deploy plugins][deploy_plugins]. See the [standard deployment getting started guide][standard] for details.{% endcapture %}

([↑ Back to top](#content))

## System requirements

MCollective can run on almost any \*nix operating system, as well as on Microsoft Windows. It requires Ruby 2.1 or later.

MCollective also requires version **1.2.2 or higher** of the Stomp rubygem.

## Installing with the official packages

Puppet provides an official pre-built [`puppet-agent`][puppet-agent] for Windows, macOS, and the most common Linux-based operating systems. This package installs MCollective along with [Puppet]({{puppet}}), its tools, and its prerequisites.

### Install MCollective

Install the `puppet-agent` package using your operating system's package manager. For details, follow the [Puppet installation process]({{puppet}}/reference/install_pre.html).

### Enable the MCollective service

Ensure that the `mcollective` service is running and is enabled to start at boot. The `mcollective` package installs an init script that works with your system's service management tools.

At this point, MCollective is installed and running, but can't connect to the middleware, accept commands, or execute actions. You should now {{ postinstall }}

### Example

As suggested [in the best practices](#best-practices) and [server configuration reference][server_config_best_practices], use configuration management software like Puppet to deploy MCollective on your nodes. This can be done with a simple or modified package/file/service pattern.

The example below uses a modified pattern that assumes that you:

-   [Manage settings as resources][server_config_best_practices] in a different class.
-   Maintain your own package repository with tested versions of the MCollective packages, allowing you to safely use `ensure => latest` to automatically update packages.
-   Deployed all servers with this local repository enabled.
-   Manage client workstations separately, and only automate deployment on your servers.

``` ruby
class mcollective {
  # Install
  package {'mcollective':
    ensure => latest,
  }

  # Run
  service {'mcollective':
    ensure  => running,
    enable  => true,
    require => Package['mcollective'],
  }

  # Restart the service when any settings change
  Package['mcollective'] -> Mcollective::Setting <| |> ~> Service['mcollective']
}
```

For details about the relationship and collector syntax used to restart the MCollective service on setting changes, see the [collector]({{puppet}}/reference/lang_collectors.html) and [chaining arrow]({{puppet}}/reference/lang_relationships.html#chaining-arrows) references.

([↑ Back to top](#content))

## Rolling custom RPM and Debian packages

If you use a system that doesn't have an official `puppet-agent` package, you can build your own `puppet-agent` package. For more information, see the [puppetlabs/puppet-agent repository on GitHub](https://github.com/puppetlabs/puppet-agent).

([↑ Back to top](#content))

## Running from source

In addition to using our packages or building your own, you can also build MCollective directly from source.

### Obtain the source

Get a copy of the MCollective source by cloning [the GitHub repo][git_repo] or [downloading a tarball][mco_tags].

### Install Ruby and the Stomp gem

Install Ruby, and make sure that your system's Ruby version meets [MCollective's system requirements](#system-requirements). Also, install **version 1.2.2 or higher** of the `stomp` gem.

### Add `mcollective/lib` to Ruby's load path

Ruby must be able to load the contents of the `lib` directory in the MCollective source. There are two main ways to do this:

-   Recursively copy the contents of `lib` into the `site_ruby` directory
-   Put the MCollective source somewhere like `/opt` and use the `RUBYLIB` environment variable to add it to Ruby's load path.

### Copy `mcollective/plugins`

MCollective ships with a set of plugins that it requires for basic functionality. These do not live in its normal lib path, but rather in an external directory specified by the `libdir` setting in MCollective's [server][server_libdir] and [client][client_libdir] configuration files.

Copy the contents of this `plugins` directory to a platform-appropriate place, and **remember the location** for your post-install configuration because you need to specify it in the `libdir` setting.

-   Windows platforms put plugins in `C:\ProgramData\PuppetLabs\mcollective\plugins`.
-   All other systems put plugins in `/opt/puppetlabs/mcollective/plugins`.

Other platforms might use different conventions.

> **Note:** MCollective expects its `libdir` to contain a single directory named `mcollective`, which then contains the rest of the plugin directories. Don't put your plugins in the _parent directory_ of the directory that MCollective checks.
>
> **Example:**
>
>     # /etc/puppetlabs/mcollective/server.cfg
>     # ...
>     libdir = /opt/puppetlabs/mcollective/plugins
>
> -   **Good:** `/opt/puppetlabs/mcollective/plugins/mcollective/agent/discovery.rb`
> -   **Bad:** `/opt/puppetlabs/mcollective/plugins/agent/discovery.rb`

### Add `mcollective/bin` to the path

The root user on each server must be able to execute the `mcollectived` binary. Administrative users must be able to execute the `mco` binary. You should either link these to someplace like `/usr/local/bin` and `/usr/local/sbin`, or add the directory they live in to the appropriate users' `PATH` environment variable.

> **Note:** If you're using Puppet Enterprise, only the `peadmin` user can run the `mco` command. For more information, see the [PE MCollective actions]({{pe}}/orchestration_invoke_cli.html) documentation.

### Roll your own init script

There are several example init scripts in the MCollective source:

-   [A basic LSB-compliant init script][init_lsb]
-   [A Red Hat-like init script][init_redhat]
-   [A Debian-like init script][init_debian]

The `mcollective/ext` directory contains additional files that might help you install and configure the MCollective service on your platform.

At this point, MCollective is installed and running but cannot connect to the middleware, accept commands, or execute any actions. You should now {{ postinstall }}

You won't be able to count on the official package's sensible defaults for MCollective's configuration files, so set the logging and `libdir` settings after installation.

### Installing from source on Windows

We currently have no instructions for installing MCollective from source on Windows. You should investigate the `ext/windows` directory in the MCollective source.

([↑ Back to top](#content))
