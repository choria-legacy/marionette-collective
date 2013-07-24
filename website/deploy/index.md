---
title: "MCollective » Deployment"
layout: default
---

[deploy_summary_in_page]: #deployment-process
[vagrant_demo]: ./demo.html
[standard_deploy]: ./standard.html
[middleware]: ./middleware/
[install]: ./install.html
[config_server]: /mcollective/configure/server.html
[config_client]: /mcollective/configure/client.html
[plugin_deploy]: ./plugins.html
[puppet]: /puppet/

Summary
-----

Getting started with MCollective takes more than just installing --- it has multiple components, with interdependent configuration, installed across your infrastructure.

Which is to say: Deploying MCollective isn't difficult, but it requires some planning. You should play with a **demo,** **read** a little, then **deploy.**

### Demo

* If you've never used MCollective before, [try the Vagrant-based demo toolkit][vagrant_demo]. It will quickly get you a full MCollective environment with a dozen or so nodes, so you can get used to the client interface and perhaps write a simple agent plugin.

### Read

* [Read the deployment overview](/mcollective/overview_components.html) to meet the components of MCollective (servers, clients, and middleware).
* Understand the steps of deploying MCollective ([see summary below][deploy_summary_in_page]).

### Deploy

* [Follow the "standard deployment" getting started guide][standard_deploy]. These conventions will get you a very secure and high-performance starter deployment. You can customize MCollective in depth later when you need to.
* If you have special needs and know what you're doing, you can design a custom deployment. Decide on a middleware type and topology, decide on a security plugin, and follow the steps of the deployment process outlined below.

> ### Puppet Enterprise
>
> Puppet Enterprise includes MCollective, and automates the entire deployment process. See [the PE orchestration documentation][pe_orchestration] for more details; see [the PE installation instructions][pe_install] to install PE.
>
> * Puppet Enterprise 3.0 ships with MCollective 2.2.4.
> * Puppet Enterprise 2.8 ships with MCollective 1.2.1.

[pe_orchestration]: /pe/latest/orchestration_overview.html
[pe_install]: /pe/latest/install_basic.html


Deployment Process
-----

In general, you need to do the following to deploy MCollective:

1. Collect credentials and global configuration
2. [Deploy and configure middleware][middleware]
3. [Install MCollective][install] (on both servers and admin workstations)
4. [Configure servers][config_server]
5. [Configure clients][config_client]
6. [Deploy plugins][plugin_deploy]

The [standard deployment getting started guide][standard_deploy] goes into greater detail on each of these steps, and describes the deployment that most users should start with.

If you are deploying in an unusual way or at a very large scale, you will probably still want to use the standard guide as a starting point. At each major step, you can take detours to configure, e.g., multiple middleware servers, alternate middleware, multiple subcollectives, etc.

Best Practices
-----

### Use Configuration Management

**Use [Puppet][] or some other form of configuration management to deploy MCollective.** It is the textbook example for why you need config management:

* It has multiple components that run on many different machines.
* It has pieces of global configuration that must be set harmoniously, everywhere.
* Most of its settings are identical for machines in a given role (e.g. every server), but some of its settings have per-system differences. This is easy to manage with a template, and incredibly frustrating to manage by hand.
* Its configuration _will_ change over time, and the changes affect many many systems at once. (New/updated agents must be deployed to all servers; when a new admin user is introduced, every server must be made aware of their permissions.)

In summary, its configuration requirements are strict, and configuration drift will cause it to stop working. Use Puppet.

We don't currently have drop-in Puppet code for deploying MCollective, so you'll have to build several parts of your deployment yourself. In the [standard deployment getting-started guide][standard_deploy], we give suggestions on Puppet code wherever possible. We also hope to have something a bit more standardized in the future.

### Design For Human Capabilities

The most succinct way to say this is: Don't build a 10,000 node collective with no subcollectives.

Beyond a certain population size, messing up an important command gets very expensive. It also becomes hard to understand and process the data a normal command returns.

After about 1000 or 2000 nodes, it's best to to split the deployment into subcollectives and have commands default to a subset of machines, reserving whole-infrastructure commands for the cases where they're explicitly needed. You can also make commands targeting many machines safer by running them with `--batch SIZE`, which offers a chance to cancel out if you make a mistake.

