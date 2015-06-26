---
title: "MCollective » Deploy » Install MCollective"
layout: default
---

[pe_orchestration]: /pe/latest/orchestration_overview.html
[pe_install]: /pe/latest/install_basic.html
[mco_tags]: https://github.com/puppetlabs/marionette-collective/tags
[git_repo]: https://github.com/puppetlabs/marionette-collective
[rakefile]: https://github.com/puppetlabs/marionette-collective/blob/master/Rakefile
[17804]: http://projects.puppetlabs.com/issues/17804
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
[anchor_official]: #installing-with-the-official-packages
[enable_repos]: /guides/puppetlabs_package_repositories.html
[server_libdir]: /mcollective/configure/server.html#platform-defaults
[client_libdir]: /mcollective/configure/client.html#platform-defaults
[deploy]: ./index.html

Summary
-----

> **Note:** This page is about installing MCollective. Installation is only one step of a many-step deployment process. See the [MCollective deployment index][deploy] for the complete picture.

> ### Puppet Enterprise
>
> Puppet Enterprise includes MCollective, and automates the entire deployment process. See [the PE orchestration documentation][pe_orchestration] for more details; see [the PE installation instructions][pe_install] to install PE.
>
> * Puppet Enterprise 3.0 ships with MCollective 2.2.4.
> * Puppet Enterprise 2.8 ships with MCollective 1.2.1.

Installing MCollective requires the following steps:

- [Make sure your middleware is up and running and your firewalls are in order.](#pre-install)
- Install the `mcollective` package on servers, then make sure the `mcollective` service is running.
- Install the `mcollective-client` package on admin workstations.
- Most Debian-like and Red Hat-like systems can [use the official Puppet Labs packages](#installing-with-the-official-packages). Enable the Puppet Labs repos, or import the packages into your own repos.
    - If you're on Debian/Ubuntu, [mind the missing package dependency.](#install-stomp-gem-debianubuntu)
- If your systems can't use the official packages, [check the system requirements](#system-requirements) and either [build your own](#rolling-custom-rpm-and-deb-packages) or [run from source](#running-from-source).

### Best Practices

Use site-wide configuration management software to install and configure MCollective. Since you'll need to install the server daemon on every node in your deployment, and since you'll want each node to be running the same version, you should generally use Puppet or something like it to install MCollective.

### Version Notes

MCollective uses a three-part "x.y.z" version number.

* The first digit doesn't have a particularly strict definition, but generally increments for major architectural breaks and incompatibilities.
* The second digit indicates whether this is a stable release: **even** numbers are stable and production-ready, and **odd** numbers are unstable development branches in which breaking changes may happen in minor point releases.
* The third digit reperesents the minor point release; in a stable version series, these should only contain bugfixes, and in an unstable series they may contain anything.


* * *

Pre-Install
-----

* Your [middleware system should be deployed][middleware] before installing MCollective.
* Make sure each server's firewall will allow MCollective to initiate connections with the middleware server. The port depends on your deployment plan; with the recommended [ActiveMQ connector][activemq_connector], this will usually be either 61614 for Stomp/TLS (recommended) or 61613 for unencrypted Stomp, depending on [how you configured ActiveMQ's transport connectors][activemq_port_config].


{% capture postinstall %}[configure the server daemon][config_server], [configure admin workstations][config_client], and [deploy plugins][deploy_plugins]. See the [standard deployment getting started guide][standard] for details.{% endcapture %}



([↑ Back to top](#content))

* * *

System Requirements
-----

MCollective can run on almost any \*nix operating system, as well as Microsoft Windows. It requires one of the following Ruby versions:

* 1.9.3
* 1.8.7

Ruby 2 is not officially supported yet, but may work fine. Ruby 1.8.5 can't use TLS when connecting to the middleware, but works fine over unencrypted connections. Ruby 1.8.6 has the same problem as 1.8.5, and somewhat less automated test coverage. Ruby 1.9.0 through 1.9.2 are NOT supported, and are expected to fail.

MCollective also requires the Stomp rubygem, version **1.2.2 or higher.** The instructions below will note when this has to be handled manually.

### Official Packages

Puppet Labs provides official pre-built packages for the most common Linux-based operating systems. If you are running any of these systems, you can use the "[Official Packages][anchor_official]" install instructions.

#### Red Hat Enterprise Linux (and Derivatives)

{% include platforms_redhat_like.markdown %}

#### Fedora

{% include platforms_fedora.markdown %}

#### Debian-Like

{% include platforms_debian_like.markdown %}

([↑ Back to top](#content))

* * *

Installing With the Official Packages
-----

### Install Stomp Gem (Debian/Ubuntu)

The current MCollective packages for Debian and Ubuntu have a missing dependency on the Stomp gem ([issue 17804][17804]). Before installing MCollective, you must install version **1.2.2 or higher** of the Stomp rubygem. Use one of the following, making sure to check the version:

* The distro's `libstomp-ruby` package (older releases)
* The distro's `ruby-stomp` package (newer releases)
* The `stomp` gem

### Enable Repos or Add Packages

To use the official packages, you must first either [enable the Puppet Labs package repositories][enable_repos] on all systems, or import the following packages from our repo into your local repo:

* `mcollective`
* `mcollective-client`
* `mcollective-common`
* `rubygem-stomp` (on Enterprise Linux variants)

### Install MCollective

* On server nodes, install the `mcollective` package.
* On admin workstations, install the `mcollective-client` package.

Both of these packages install `mcollective-common` as a dependency.

### Enable the MCollective Service

Ensure that the `mcollective` service is running and is enabled to start at boot. The `mcollective` package installs an init script that works with your system's normal service tools.

### Done

At this point, MCollective is installed and running, but cannot connect to the middleware, accept commands, or execute any actions. You should now {{ postinstall }}

### Example

As mentioned [above](#best-practices) and [in the server config reference][server_config_best_practices], you should use Puppet or some other configuration management software to deploy MCollective on your server nodes. This can be done with a simple or modified package/file/service pattern.

The example below uses a modified pattern. It assumes:

* You are [managing settings as resources][server_config_best_practices] in a different class.
* You are maintaining your own package repository with pre-tested versions of the MCollective packages, allowing `ensure => latest` to be used safely. All servers were deployed with this local repository enabled.
* You are managing client workstations separately, and only automating deployment on your server nodes.

{% highlight ruby %}
    class mcollective {
      # Manage Stomp gem dependency on Debian/Ubuntu
      package {'stomp':
        ensure   => '1.2.2',
        provider => gem,
        before   => Package['mcollective'],
      }

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
      # (see http://docs.puppetlabs.com/puppet/latest/reference/lang_collectors.html and
      # http://docs.puppetlabs.com/puppet/latest/reference/lang_relationships.html#chaining-arrows
      # for syntax details)
      Package['mcollective'] -> Mcollective::Setting <| |> ~> Service['mcollective']
    }
{% endhighlight %}

([↑ Back to top](#content))

* * *


Rolling Custom RPM and Deb Packages
-----

If you use an RPM-based or deb-based Linux distribution not supported by the official Puppet Labs packages, you can build your own packages with the same automated tooling Puppet Labs uses.

More detailed instructions on this are forthcoming; for the time being, [obtain a copy of the source][mco_tags] and do a quick read-through of the [Rakefile][]. The relevant tasks are named `deb` and `rpm`.

Once you have packages, they will behave much like the official ones; follow the [same instructions above.](#installing-with-the-official-packages)

([↑ Back to top](#content))

* * *

Running From Source
-----

On platforms not supported by the official packages or the underlying RPM and deb tooling, you can run MCollective directly from source.

### Obtain Source

Get a copy of the MCollective source, either by cloning [the GitHub repo][git_repo] or [downloading a tarball][mco_tags].

### Install Ruby and the Stomp Gem

Make sure Ruby is installed and that your system's Ruby version meets [MCollective's system requirements](#system-requirements).

Install **version 1.2.2 or higher** of the `stomp` rubygem.

### Add `mcollective/lib` to Ruby's Load Path

Ruby must be able to load the contents of the `lib` directory in the MCollective source. There are two main ways to do this:

* Recursively copy the contents of `lib` into the `site_ruby` directory
* Put the MCollective source somewhere like `/opt` and use the `RUBYLIB` environment variable to add it to Ruby's load path.

### Put `mcollective/plugins` Somewhere Sensible

MCollective ships with a set of plugins it requires for basic functionality; these do not live in its normal lib path, but in an external directory specified by the `libdir` setting in MCollective's [server][server_libdir] and [client][client_libdir] config files.

You should copy the contents of this `plugins` directory to some platform-appropriate place; **remember the location** for your post-install configuration, since you need to specify it in the `libdir` setting. Red Hat-like platforms put plugins in `/usr/libexec/mcollective`. Debian-like platforms put it in `/usr/share/mcollective/plugins`. Your platform may have its own conventions.

> **Note:** MCollective expects its `libdir` to contain a single directory named `mcollective`, which then contains the rest of the plugin directories. Be sure to not accidentally put your plugins in the directory _above_ the one MCollective will look in.
>
> **Example:**
>
>     # /etc/mcollective/server.cfg
>     # ...
>     libdir = /usr/libexec/mcollective
>
> * Good: `/usr/libexec/mcollective/mcollective/agent/discovery.rb`
> * Bad: `/usr/libexec/mcollective/agent/discovery.rb` (This would only work if you had set a `libdir` of `/usr/libexec`.)

### Add `mcollective/bin` to the Path

The root user on each server node must be able to execute the `mcollectived` binary. Admin users must be able to execute the `mco` binary. You should either copy these to someplace like `/usr/local/bin` and `/usr/local/sbin`, or add the directory they live in to the appropriate users' `PATH` environment variable.

### Roll Your Own Init Script

There are several example init scripts in the MCollective source:

* [A basic LSB-compliant init script][init_lsb]
* [A Red Hat-like init script][init_redhat]
* [A Debian-like init script][init_debian]

There may be other helpful files for your platform in the `mcollective/ext` directory. Use some combination of these to make a platform-appropriate init script for the MCollective server daemon.

### Done

At this point, MCollective is installed and running, but cannot connect to the middleware, accept commands, or execute any actions. You should now {{ postinstall }}

Unlike with the official packages, you won't be able to count on sensible defaults for the config files, so take special note of the logging settings and `libdir` setting.


([↑ Back to top](#content))


* * *


Installing on Windows
-----

We currently have no instructions for installing MCollective on Windows. You should investigate the `ext/windows` directory in the MCollective source. If you've used MCollective on Windows, we'd love to hear about your experience, especially any unexpected pitfalls you ran into. Email <docs@puppetlabs.com>.

