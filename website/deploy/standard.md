---
title: "MCollective » Deploy » Standard Deployment"
subtitle: "Getting Started: Standard MCollective Deployment"
layout: default
---

[inpage_step_one]: #step-1-create-and-collect-credentials
[vagrant_demo]: ./demo.html
[overview_roles]: /mcollective/overview_components.html
[security_overview]: /mcollective/security.html
[activemq_clustering]: /mcollective/reference/integration/activemq_clusters.html
[subcollectives]: /mcollective/reference/basic/subcollectives.html
[activemq_filters]: ./middleware/activemq.html#destination-filtering
[puppet]: /puppet/
[overview_use_puppet]: ./index.html#best-practices
[puppetlabs_repos]: /guides/puppetlabs_package_repositories.html
[activemq_install]: http://activemq.apache.org/getting-started.html
[activemq_config]: ./middleware/activemq.html
[activemq_example]: https://raw.github.com/puppetlabs/marionette-collective/master/ext/activemq/examples/single-broker/activemq.xml
[certdir]: /references/latest/configuration.html#certdir
[privatekeydir]: /references/latest/configuration.html#privatekeydir
[ssldir]: /references/latest/configuration.html#ssldir
[activemq_authorization]: ./middleware/activemq.html#authorization-group-permissions
[install_mcollective]: ./install.html
[puppet_template]: /guides/templating.html
[puppet_lang_notification]: /puppet/latest/reference/lang_relationships.html#ordering-and-notification
[file]: /references/latest/type.html#file
[actionpolicy_docs]: https://docs.puppetlabs.com/mcollective/plugin_directory/authorization_action_policy.html
[actionpolicy]: https://github.com/puppetlabs/mcollective-actionpolicy-auth
[server_config]: /mcollective/configure/server.html
[client_config]: /mcollective/configure/client.html
[javaks]: http://forge.puppetlabs.com/puppetlabs/java_ks


Summary
-----

This getting started guide will help you deploy a standard MCollective environment. [Jump to the first step][inpage_step_one], or keep reading for some context.

> **Note:** If you've never used MCollective before, [start with the Vagrant-based demo toolkit instead][vagrant_demo]. This guide is meant for production-grade deployments, and requires a bit of building before you can do a simple `mco ping` command.

> ### Puppet Enterprise
>
> Puppet Enterprise includes MCollective, and automates the entire deployment process. See [the PE orchestration documentation][pe_orchestration] for more details; see [the PE installation instructions][pe_install] to install PE.
>
> * Puppet Enterprise 3.0 ships with MCollective 2.2.4.
> * Puppet Enterprise 2.8 ships with MCollective 1.2.1.

[pe_orchestration]: /pe/latest/orchestration_overview.html
[pe_install]: /pe/latest/install_basic.html

### What is an MCollective Deployment?

[See the MCollective components overview][overview_roles] for an introduction to the parts that make up an MCollective deployment.

### Why "Standard?"

MCollective is very pluggable, but the developers and community have settled on some common conventions for the most important configuration options. These defaults work very well for most new users, and create a good foundation for future expansion and reconfiguration.

The Standard MCollective Deployment
-----

### Architecture and Configuration

In summary, these are the architecture and configuration conventions that make up the standard MCollective deployment:

* Middleware and connector: **ActiveMQ**
    * One ActiveMQ server (expandable later)
    * CA-verified TLS
    * No extra subcollectives
    * One ActiveMQ user account/password for all MCollective traffic
* Security plugin: **SSL** (authentication only)
* Credentials:
    * Certificate/key pair for each client user (for both connector and security plugins)
    * One shared certificate/key pair for all servers (for security plugin)
    * Pre-existing Puppet certificate/key pair on each server (for connector plugin)
        * Alternately, you can use the shared server certificate/key for both the connector and security plugins; unique certificates aren't strictly necessary.
* Authorization: **ActionPolicy plugin**

### Security Model

* [See here for a deeper explanation of MCollective's various layers of security.][security_overview]

In brief, this is what MCollective's security model looks like with these conventions in place:

#### Transport Level

* The TLS between MCollective servers/clients and the ActiveMQ server **encrypts traffic,** preventing passive sniffing of sensitive data in requests and replies.
* Since the TLS is CA-verified, it also **prevents man-in-the-middle attacks** targeting the middleware.
* Requiring both a password and a signed certificate to connect to the middleware helps **prevent unauthorized access to decrypted text.** The password is easier to change, the certificate is harder to steal, and together they offer reasonable security. (For these credentials to be secure, we expect that you've made it reasonably difficult for attackers to gain root on your systems.)
* The middleware connection does not identify clients; this happens at the application level.

#### Application Level

With the SSL security plugin, each client user has a unique key pair and all servers share a single key pair. Each server node holds a collection of all authorized client public keys.

* When clients issue requests, they sign the payload and TTL with their private key; servers do the same when they send replies. This **strongly identifies individual clients** and **identifies servers as a group.** (An authorized server could theoretically impersonate another authorized server; in the common use cases for MCollective, this isn't a significant concern.)
* Servers will reject requests signed by any key that isn't in their collection of authorized clients. This acts as **coarse-grained client authorization.** (Note especially that the shared server key pair cannot be used to send requests, which is an advantage over the weaker PSK security plugin.)
* The ActionPolicy plugin allows **fine-grained client authorization** at the per-action level. (This relies on the client authentication provided by the SSL security plugin.)
* Servers also check the signature of the request payload and TTL, which **protects against message tampering and replay attacks.**

#### Summary

These measures focus mainly on strict control over who can command your infrastructure and protection of sensitive information in transit. They assume that authorized servers and clients are both sufficiently trusted to view all sensitive information passing through the middleware.

This is suitable for most use cases. If some authorized servers are untrustworthy, there are opportunities for them to send misleading replies and bogus traffic, but they can't command other nodes.


### Future Expansion

Later, you may need to [expand to a cluster of ActiveMQ servers][activemq_clustering]; at that point, you might also:

* [Divide your nodes into subcollectives][subcollectives]
* [Filter traffic between datacenters][activemq_filters]
* [Do per-user ActiveMQ authorization][activemq_authorization]

If you have already used modular Puppet code to set up a standard deployment, these changes can be incremental instead of a complete overhaul.


([↑ Back to top](#content))


Steps to Deploy
-----

You need to do the following to deploy MCollective:

1. Create and collect credentials
2. Deploy and configure middleware
3. Install MCollective (on both servers and admin workstations)
4. Configure servers
5. Configure clients
6. Deploy plugins

This process isn't 100% linear, but that's the general order in which these tasks should be approached.

### Best Practices

**Use [Puppet][] or some other form of configuration management to deploy MCollective.** See [the deployment overview][overview_use_puppet] for why this is important.

We don't currently have drop-in Puppet code for a standard MCollective deployment, so you'll have to do some building.


([↑ Back to top](#content))


[step1]: #step-1-create-and-collect-credentials

## Step 1: Create and Collect Credentials

Credentials are the biggest area of shared global configuration in MCollective. Get them sorted before doing much else.

A standard deployment uses the following credentials:

Credential                                             | Used By:
-------------------------------------------------------|-------------------------------------------------
ActiveMQ username/password                             | Middleware, servers, clients
CA certificate                                         | Middleware, servers, clients
Signed certificate and private key for **ActiveMQ**    | Middleware
Signed certificate and private key for each **server** | Servers
Signed certificate and private key for each **user**   | Clients (both parts), servers (certificate only)
Shared server public and private key                   | Servers (both parts), clients (public key only)


### What Are These?

* ActiveMQ ↔ MCollective traffic uses CA-signed X.509 certificates for encryption and verification. These are just like the certs Puppet uses.
    * Unlike Puppet, we aren't using the certificate DN/CN for authentication --- the CA verification is solely to make man-in-the-middle attacks more difficult.
* The SSL security plugin (on servers and clients) uses RSA public/private key pairs (or anything else readable by openssl) to do authentication, coarse-grained authorization, and message signing. The public portion is flexible: it can be either a raw RSA key, or a signed SSL certificate. The plugin identifies keys by filename.
* If you're using Puppet, you can re-use its certificate authority, and use it to sign certificates.
* On MCollective nodes, all credentials should be in .pem format; on the middleware, some extra conversion is needed.

### Walkthrough / Checklist

Make sure you've covered each of the following credentials, and keep track of the credentials for use in future steps. This guide assumes you're using Puppet as your certificate authority. If you aren't, you'll need to generate each credential some other way.

> **Directories:** Below, we refer to directories called [`$certdir`][certdir] and [`$privatekeydir`][privatekeydir] --- these are defined by Puppet settings of the same names. Their locations may vary by platform, so you can locate them with `sudo puppet agent --configprint certdir,privatekeydir` (on an agent node) or `sudo puppet master --configprint certdir,privatekeydir` (on the CA master).

* **PASSWORD:** _Do:_ Decide on a username for connecting to ActiveMQ; we suggest `mcollective`. Create a strong arbitrary password for this user.
* **CA:** _Already done:_ Every node already has a local copy of the Puppet CA; you can use it directly. It's always located at `$certdir/ca.pem`.
* **ACTIVEMQ CERT:** _Decide:_ You can either re-use the ActiveMQ server's existing puppet agent certificate, or generate a new certificate on the CA puppet master with `sudo puppet cert generate activemq.example.com` (this name cannot conflict with an existing certificate name). In either case, find the certificate and private key at `$certdir/<NAME>.pem` and `$privatekeydir/<NAME>.pem`.
* **SHARED SERVER KEYS:** _Do:_ On the CA puppet master, generate a new certificate with `sudo puppet cert generate mcollective-servers`. (If you use a different name, substitute it for "mcollective-servers" everywhere we mention it below. Note that the name can only use letters, numbers, periods, and hyphens.) <!-- lib/mcollective/security/base.rb#214 --> Retrieve the certificate and private key from `$certdir/mcollective-servers.pem` and `$privatekeydir/mcollective-servers.pem`.
* **SERVER CERTS:** _Already done:_ Every server node already has its own puppet agent certificate. You can re-use it. The certificate and key are located at `$certdir/<NAME>.pem` and `$privatekeydir/<NAME>.pem`.
* **CLIENT CERTS:** _Do:_ You will need to continually create client credentials as you add new admin users.
    * For the first admin user --- yourself --- you can generate a certificate on the CA puppet master with `sudo puppet cert generate <NAME>` (letters, numbers, periods, and hyphens only) and retrieve the cert and key from `$certdir/<NAME>.pem` and `$privatekeydir/<NAME>.pem`; delete the CA's copy of the private key once you've retrieved it.
    * For future admin users, you need to build a process for issuing and distributing credentials. [See "Managing Client Credentials" below][client_creds] for notes about this.

> **Deployment status:** Nothing has happened yet.


([↑ Back to top](#content))


## Step 2: Deploy and Configure Middleware

As ever, note that you'll have an easier time later if you perform these steps with Puppet or something like it. We suggest using a template for the activemq.xml file and using the [`java_ks`][javaks] resource type for the keystores.

1. Install ActiveMQ 5.5 or higher on your ActiveMQ server. If you are using Fedora or a relative of Red Hat Enterprise Linux, enable [the Puppet Labs package repos][puppetlabs_repos] and install the `activemq` package. The most recent versions of Debian and Ubuntu have ActiveMQ packages, and you may be able to install `activemq` without enabling any extra repos. For other systems, [adapt the instructions from the ActiveMQ documentation][activemq_install], or roll your own packages.
2. Locate the activemq.xml file. Replace it with the [example config file][activemq_example] from the MCollective source. You will be editing this example activemq.xml file to suit your deployment in the next four steps.
3. [Change the passwords][activemq_passwords] for the admin user and the `mcollective` user. For the MCollective user, **use the password from the list of credentials above.**
4. [Change the port and protocol][activemq_transports] on the stomp transport connector to `stomp+nio+ssl://0.0.0.0:61614?needClientAuth=true&amp;transport.enabledProtocols=TLSv1,TLSv1.1,TLSv1.2`, since we'll be using CA-verified TLS. (If you are running ActiveMQ before 5.9.x, set it to `stomp+ssl://0.0.0.0:61614?needClientAuth=true&amp;transport.enabledProtocols=TLSv1,TLSv1.1,TLSv1.2` instead; the stomp+nio+ssl protocol have had several bugs in earlier releases.)
5. Follow the [ActiveMQ keystores guide][activemq_keystores], using **the CA certificate and the ActiveMQ certificate/key.** (See list of credentials above.)
6. [Write an `sslContext` element][activemq_sslcontext] in the activemq.xml file to use the keystores you created. (If you are using ActiveMQ 5.5, make sure you are arranging elements alphabetically to work around the XML validation bug.)
7. Start or restart the ActiveMQ service.
8. Ensure that the server's firewall allows inbound traffic on port 61614.

[activemq_keystores]: ./middleware/activemq_keystores.html
[activemq_sslcontext]: ./middleware/activemq.html#tls-credentials
[activemq_transports]: ./middleware/activemq.html#transport-connectors
[activemq_passwords]: ./middleware/activemq.html#authentication-users-and-groups

For more details about configuring ActiveMQ, see the [ActiveMQ config reference for MCollective users][activemq_config]. It's fairly exhaustive, and is mostly for users doing things like networks of brokers and traffic filtering; for a standard deployment, you just need to change the passwords and configure TLS.

> **Deployment status:** The middleware is fully ready, but nothing is using it yet.


([↑ Back to top](#content))


## Step 3: Install MCollective

[See the "Install MCollective" page for complete instructions.][install_mcollective] In summary:

* Install the `mcollective` package on your server nodes.
* Install the `mcollective-client` package on your admin workstations.
* If you don't have official packages for your OS, you may need to [run from source][from_source].
* Make sure you install the same version everywhere.

[from_source]: ./install.html#running-from-source

> **Deployment status:** MCollective is installed, but isn't ready to do anything at this point. The `mcollective` service will probably refuse to start since it lacks a connector and security plugin.


([↑ Back to top](#content))


## Step 4: Configure Servers

To configure servers, you'll need to:

* Locate and place the credentials
* Populate the fact file
* Write the server config file, with appropriate settings

### Locate and Place Credentials

[As mentioned above in Step 1][step1], servers need the CA, an individual certificate and key, the shared server keypair, and every authorized client certificate.

* If you're using Puppet, the CA, individual cert, and individual key are already present.
* Put a copy of the shared public key at `/etc/mcollective/server_public.pem`.
* Put a copy of the shared private key at `/etc/mcollective/server_private.pem`.
* Create a `/etc/mcollective/clients` directory and put a copy of every client certificate in it. You will need to maintain this directory centrally, and keep it up to date on every server as you add and delete admin users. (E.g. as a [file resource][file] with `ensure => directory, recurse => true`.)

### Populate the Fact File

Every MCollective server will need to populate the `/etc/mcollective/facts.yaml` file with a cache of its facts. (You can get by without this file, but doing so will limit your ability to filter requests.)

Make sure you include a resource like the following in the Puppet code you're using to deploy MCollective:

{% highlight ruby %}
    file{"/etc/mcollective/facts.yaml":
      owner    => root,
      group    => root,
      mode     => 400,
      loglevel => debug, # reduce noise in Puppet reports
      content  => inline_template("<%= scope.to_hash.reject { |k,v| k.to_s =~ /(uptime_seconds|timestamp|free)/ }.to_yaml %>"), # exclude rapidly changing facts
    }
{% endhighlight %}

### Write the Server Config File

The server config file is located at `/etc/mcollective/server.cfg`.

[as_resources]: /mcollective/configure/server.html#best-practices

> See the [server configuration reference][server_config] for complete details about the server's config file, including its format and available settings.

This config file has many settings that should be identical across the deployment, and several settings that must be unique per server, which is why we suggest managing it with Puppet. If your site uses only a few agent plugins and they don't require a lot of configuration, you can use a [template][puppet_template]; otherwise, we recommend [managing each setting as a resource.][as_resources]

**Be sure to always restart the `mcollective` service after editing the config file.** In your Puppet code, you can do this with a [notification relationship][puppet_lang_notification].

#### Server Settings for a Standard Deployment

This example template snippet shows the settings you need to use in a standard deployment. Converting it to [settings-as-resources][as_resources] would be fairly straightforward.

(Note that it assumes an [`$ssldir`][ssldir] of `/var/lib/puppet/ssl`, which might differ in your Puppet setup. This template also requires variables named `$activemq_server` and `$activemq_mcollective_password`.)

    {% highlight erb %}
    <% ssldir = '/var/lib/puppet/ssl' %>
    # /etc/mcollective/server.cfg

    # ActiveMQ connector settings:
    connector = activemq
    direct_addressing = 1
    plugin.activemq.pool.size = 1
    plugin.activemq.pool.1.host = <%= @activemq_server %>
    plugin.activemq.pool.1.port = 61614
    plugin.activemq.pool.1.user = mcollective
    plugin.activemq.pool.1.password = <%= @activemq_mcollective_password %>
    plugin.activemq.pool.1.ssl = 1
    plugin.activemq.pool.1.ssl.ca = <%= ssldir %>/certs/ca.pem
    plugin.activemq.pool.1.ssl.cert = <%= ssldir %>/certs/<%= scope.lookupvar('::clientcert') %>.pem
    plugin.activemq.pool.1.ssl.key = <%= ssldir %>/private_keys/<%= scope.lookupvar('::clientcert') %>.pem
    plugin.activemq.pool.1.ssl.fallback = 0

    # SSL security plugin settings:
    securityprovider = ssl
    plugin.ssl_client_cert_dir = /etc/mcollective/clients
    plugin.ssl_server_private = /etc/mcollective/server_private.pem
    plugin.ssl_server_public = /etc/mcollective/server_public.pem

    # Facts, identity, and classes:
    identity = <%= scope.lookupvar('::fqdn') %>
    factsource = yaml
    plugin.yaml = /etc/mcollective/facts.yaml
    classesfile = /var/lib/puppet/state/classes.txt

    # No additional subcollectives:
    collectives = mcollective
    main_collective = mcollective

    # Registration:
    # We don't configure a listener, and only send these messages to keep the
    # Stomp connection alive. This will use the default "agentlist" registration
    # plugin.
    registerinterval = 600

    # Auditing (optional):
    # If you turn this on, you must arrange to rotate the log file it creates.
    rpcaudit = 1
    rpcauditprovider = logfile
    plugin.rpcaudit.logfile = /var/log/mcollective-audit.log

    # Authorization:
    # If you turn this on now, you won't be able to issue most MCollective
    # commands, although `mco ping` will work. You should deploy the
    # ActionPolicy plugin before uncommenting this; see "Deploy Plugins" below.

    # rpcauthorization = 1
    # rpcauthprovider = action_policy
    # plugin.actionpolicy.allow_unconfigured = 1

    # Logging:
    logger_type = file
    loglevel = info
    logfile = /var/log/mcollective.log
    keeplogs = 5
    max_log_size = 2097152
    logfacility = user

    # Platform defaults:
    # These settings differ based on platform; the default config file created by
    # the package should include correct values. If you are managing settings as
    # resources, you can ignore them, but with a template you'll have to account
    # for the differences.
    <% if scope.lookupvar('::osfamily') == 'RedHat' -%>
    libdir = /usr/libexec/mcollective
    daemonize = 1
    <% elsif scope.lookupvar('::osfamily') == 'Debian' -%>
    libdir = /usr/share/mcollective/plugins
    daemonize = 1
    <% else -%>
    # INSERT PLATFORM-APPROPRIATE VALUES FOR LIBDIR AND DAEMONIZE
    <% end %>
{% endhighlight %}

> **Deployment status:** The servers are ready, connected to the middleware, and will accept and process requests from authorized clients. The authorized clients don't exist yet.


([↑ Back to top](#content))


## Step 5: Configure Clients

Unlike servers, clients will probably run with per-user configs on admin workstations, and will have to be configured partially by hand. (If you are running any automated clients, you'll want to deploy those with config management; most of the principles covered below will still apply.)

To configure clients, each new admin user will need to:

* Request, retrieve, and place their credentials
* Write the client config file, with appropriate sitewide and per-user settings

Unless the client will be run by root or a system user, we recommend putting the client config file at `~/.mcollective` and supporting files like credentials in `~/.mcollective.d`.

### Managing Client Credentials

[client_creds]: #managing-client-credentials

For your first admin user, you can manually generate a certificate (as suggested in Step 1) and add it to the authorized clients directory that you're syncing to servers with Puppet. However, this does not scale beyond one or two users.

When a new admin user joins your team, you need a documented process that does ALL of the following:

- Issues the user a signed SSL certificate, while assuring the user that no one else has _ever_ had custody of their private key.
- Adds a copy of the user's certificate to every MCollective server.
- Gives the user a copy of the shared server public key, the CA cert, and the ActiveMQ username/password.

> **Note:** The filename of the **public key** must be identical on both the client and the servers. The client uses the filename to set the caller ID in its requests, and the servers use the request's caller ID to choose which public key file to validate it with.

This will have to be at least partially manual, but if you've used the Puppet CA to issue certificates, you can pretty easily patch together and document a process using the existing Puppet tools.

Below, we outline a suggested process. It assumes a flat hierarchy of admins where everyone can command all servers, with any additional restrictions being handled by the ActionPolicy plugin (see "Step 6: Deploy Plugins" below) rather than the certificate distribution process.

#### Example Client Onboarding Process

1. The new user should have Puppet installed on their workstation (or the server from which they will be issuing mco commands). It does not need to be managing their workstation, it just needs to be present.
2. The new user should run the following commands on their workstation --- note that the name can only use letters, numbers, periods, and hyphens:

        $ mkdir -p ~/.mcollective.d/credentials
        $ puppet certificate generate <NAME> --ssldir ~/.mcollective.d/credentials --ca-location remote --ca_server <CA PUPPET MASTER>

    (Note the use of the `puppet certificate` command, which isn't the same thing as the `puppet cert` command. This specific invocation will send a certificate signing request to the CA while safeguarding the private key.)
3. The new user should tell the MCollective admins which name they used, and optionally the fingerprint of the CSR they submitted.
4. The MCollective admins should run `sudo puppet cert sign <NAME>` on the CA puppet master, then copy the certificate from `$certdir/<NAME>.pem` into the directory of authorized client keys that is being synced to the MCollective servers; each server will recognize the new user after its next Puppet run.
5. The MCollective admins should tell the new user that they have signed the certificate request, and give them the ActiveMQ password and a partially filled-out client config file containing the relevant hostnames and ports. (See "Write the Client Config File" below.)
6. The new user should run the following commands on their workstation:

        $ puppet certificate find <NAME> --ssldir ~/.mcollective.d/credentials --ca-location remote --ca_server <CA PUPPET MASTER>
        $ puppet certificate find mcollective-servers --ssldir ~/.mcollective.d/credentials --ca-location remote --ca_server <CA PUPPET MASTER>
        $ puppet certificate find ca --ssldir ~/.mcollective.d/credentials --ca-location remote --ca_server <CA PUPPET MASTER>

7. The new user should copy the partial client config file they were provided to `~/.mcollective` on their workstation, and finish filling it out as described below.

After all these steps, and following a Puppet run on each MCollective server, the new user should be able to issue valid mco commands.


### Write the Client Config File

For admin users running commands on a workstation, the client config file is located at `~/.mcollective`. For system users (e.g. for use in automated scripts), it is located at `/etc/mcollective/client.cfg`.

> See the [client configuration reference][client_config] for complete details about the client config file, including its format and available settings.

This config file has many settings that should be identical across the deployment, and several settings that must be unique per user. To save your new users time, we recommend giving them a partial config file with settings like the ActiveMQ hostname/port/password already entered; this way, they only have to fill in the paths to their unique credentials. The settings that must be modified by each user are:

* `plugin.activemq.pool.1.ssl.ca`
* `plugin.activemq.pool.1.ssl.cert`
* `plugin.activemq.pool.1.ssl.key`
* `plugin.ssl_server_public`
* `plugin.ssl_client_private`
* `plugin.ssl_client_public`

#### Client Settings for a Standard Deployment

After receiving this partial config file, a new user should fill out the credential paths, substituting `<HOME>` for the fully qualified path to their home directory and `<NAME>` for the name of the certificate they requested. (Note that MCollective cannot expand shorthand paths to the home directory --- `~/.mcollective.d/credentials...` --- so you must use fully qualified paths.)

    # ~/.mcollective
    # or
    # /etc/mcollective/client.cfg

    # ActiveMQ connector settings:
    connector = activemq
    direct_addressing = 1
    plugin.activemq.pool.size = 1
    plugin.activemq.pool.1.host = <ActiveMQ SERVER HOSTNAME>
    plugin.activemq.pool.1.port = 61614
    plugin.activemq.pool.1.user = mcollective
    plugin.activemq.pool.1.password = <ActiveMQ PASSWORD>
    plugin.activemq.pool.1.ssl = 1
    plugin.activemq.pool.1.ssl.ca = <HOME>/.mcollective.d/credentials/certs/ca.pem
    plugin.activemq.pool.1.ssl.cert = <HOME>/.mcollective.d/credentials/certs/<NAME>.pem
    plugin.activemq.pool.1.ssl.key = <HOME>/.mcollective.d/credentials/private_keys/<NAME>.pem
    plugin.activemq.pool.1.ssl.fallback = 0

    # SSL security plugin settings:
    securityprovider = ssl
    plugin.ssl_server_public = <HOME>/.mcollective.d/credentials/certs/mcollective-servers.pem
    plugin.ssl_client_private = <HOME>/.mcollective.d/credentials/private_keys/<NAME>.pem
    plugin.ssl_client_public = <HOME>/.mcollective.d/credentials/certs/<NAME>.pem

    # Interface settings:
    default_discovery_method = mc
    direct_addressing_threshold = 10
    ttl = 60
    color = 1
    rpclimitmethod = first

    # No additional subcollectives:
    collectives = mcollective
    main_collective = mcollective

    # Platform defaults:
    # These settings differ based on platform; the default config file created
    # by the package should include correct values or omit the setting if the
    # default value is fine.
    libdir = /usr/libexec/mcollective
    helptemplatedir = /etc/mcollective

    # Logging:
    logger_type = console
    loglevel = warn


> **Deployment status:** MCollective is **fully functional.** Any configured admin user can run `mco ping` to discover nodes, use the `mco inventory` command to search for more detailed information, and use the `mco rpc` command to trigger actions from installed agents (currently only the `rpcutil` agent). See the [mco command-line interface documentation][cli_docs] for more detailed information on filtering and addressing commands.
>
> However, it can't yet do much other than collect inventory info. To perform more useful functions, you must install agent plugins on each server and admin workstation. Additionally, if you want to do per-action authorization for certain dangerous commands, you will need to install and configure the ActionPolicy plugin.


([↑ Back to top](#content))


## Step 6: Deploy plugins

To let MCollective do anything beyond retrieving inventory data, you must deploy various plugins to all of your server and client nodes. You will usually also want to write custom agent plugins to serve business purposes in your infrastructure.

### Install ActionPolicy

For a long-lived standard deployment, we recommend that you deploy the ActionPolicy authorization plugin to all servers.

By default, the standard deployment allows **all** authorized clients to execute **all** actions on **all** servers. This is reasonable as long as MCollective's capabilities are limited, but as you hire more admin staff and deploy agent plugins that can cause significant changes to production servers, you may wish to begin limiting who can execute what. ActionPolicy allows you to distribute policy files for specific agents, which will restrict the set of users able to run a given action.

1. [Download the ActionPolicy plugin at its GitHub repo.][actionpolicy]
2. Install it on all **servers** using the [libdir copy install method][plugin_libdir].
3. Uncomment the `rpcauthorization`, `rpcauthprovider`, and `plugin.actionpolicy.allow_unconfigured` settings in the server config file.
4. As needed, write per-agent policy files and distribute them to servers. [See the ActionPolicy documentation for details on how to write policies.][actionpolicy_docs]

#### Notes

* The SSL security plugin sets the message caller ID to `cert=<NAME>`, where `<NAME>` is the filename of the client's public key file without the `.pem` extension. This string (including the `cert=`) can be used as the second field of a policy line. (The ActionPolicy documentation uses `uid=` for its examples, which is a caller ID set by the PSK security plugin.)
* With the configuration [shown above in the server config file](#server-settings-for-a-standard-deployment), ActionPolicy is opt-in **per agent.** If you don't distribute any policy files, MCollective will continue to work as before, with no additional authorization.
* Since policy files define which servers their rules apply to (based on facts and other metadata), they can safely be distributed to all servers.

[plugin_libdir]: ./plugins.html#method-2-copying-plugins-into-the-libdir
[plugin_packages]: ./plugins.html#method-1-installing-plugins-with-native-packages

### Install Agent Plugins

Agent plugins do all of MCollective's heavy lifting. All parts of an agent need to be installed on servers, and the DDL file needs to be installed on clients.

You can:

* Install any number of pre-existing agents. See [the mcollective-plugins wiki][mcollective_plugins_wiki] for a list of the most common ones. You will probably want to install at least the `puppet`, `package`, and `service` agents.
* [Develop your own agent plugins][agent_writing] to serve site-specific purposes. These can help with application deployments, automate routine tasks like retrying mail queues, collect complex inventory information in real time, and more. [See the documentation on writing agent plugins for more info.][agent_writing]

For more information on how to install these agents, [see "Installing and Packaging MCollective Plugins."](./plugins.html) Specifically:
    * [Installing plugins with packages][plugin_packages]
    * [Installing plugins by copying into the libdir][plugin_libdir]

[agent_writing]: /mcollective/simplerpc/agents.html
[mcollective_plugins_wiki]: https://docs.puppetlabs.com/mcollective/plugin_directory/

### Learn MCollective's Command Line Interface

* [See here for general info on using MCollective's `mco` CLI client.][cli_docs]
* [See here for additional info about filtering requests.][filter_docs]

[cli_docs]: /mcollective/reference/basic/basic_cli_usage.html
[filter_docs]: /mcollective/reference/ui/filters.html

> **Deployment status:** MCollective can do anything you've written or downloaded plugins for, on any number of servers, filtered and grouped by arbitrary metadata.
