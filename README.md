# The Marionette Collective

## Deprecation Notice

This repository holds legacy code related to The Marionette Collective project.  That project has been deprecated by Puppet Inc and the code donated to the Choria Project.

Please review the [Choria Project Website](https://choria.io) and specifically the [MCollective Deprecation Notice](https://choria.io/mcollective) for further information and details about the future of the MCollective project.

## Overview

The Marionette Collective aka. mcollective is a framework to build server orchestration or parallel job execution systems.

For documentation please see https://docs.puppet.com/mcollective

## Developing

The documentation above details how MCollective works and many of its extension points.

### Spec Tests

To run spec tests
```
bundle install
bundle exec rake test
```

### Acceptance Tests

To run acceptance tests, see [this][acceptance].

### Development Environment (MacOS)

Setup ActiveMQ using acceptance config:
```
brew install activemq
cp acceptance/files/activemq.* /usr/local/opt/activemq/libexec/conf
activemq start
```

ActiveMQ can later by stopped with `activemq stop`. ActiveMQ logs are located at
`/usr/local/opt/activemq/libexec/data/activemq.log`.

Setup MCollective with acceptance config:
```
mkdir -p ~/.puppetlabs/etc/mcollective/ssl-clients
cp acceptance/files/client.* ~/.puppetlabs/etc/mcollective
cp acceptance/files/server.* ~/.puppetlabs/etc/mcollective
cp acceptance/files/ca_crt.pem ~/.puppetlabs/etc/mcollective
cp acceptance/files/client.crt ~/.puppetlabs/etc/mcollective/ssl-clients/client.pem
ln -s ~/.puppetlabs/etc/mcollective/client.cfg ~/.mcollective
```

Modify `client.cfg` to work on the local machine:
* Change the `ssl_server_public`, `ssl_client_private`, `ssl_client_public`
paths to point to `~/.puppetlabs/etc/mcollective/{server.crt,client.key,client.pem}`.
* Change the `activemq.pool.1.ssl.{ca,cert,key}` paths to
`~/.puppetlabs/etc/mcollective/{ca_crt.pem,client.crt,client.key}`.
Note that `~` needs to be expanded to the full path. Also, that `client.pem` doesn't
point to an actual file is intentional (I don't fully understand why).

Create `server.cfg`, updating `<user>`:
```
main_collective = mcollective
collectives = mcollective
logger_type = console
loglevel = info
daemonize = 0

securityprovider = ssl
plugin.ssl_server_private = /Users/<user>/.puppetlabs/etc/mcollective/server.key
plugin.ssl_server_public = /Users/<user>/.puppetlabs/etc/mcollective/server.crt
plugin.ssl_client_cert_dir = /Users/<user>/.puppetlabs/etc/mcollective/ssl-clients

connector = activemq
plugin.activemq.pool.size = 1
plugin.activemq.pool.1.host = activemq
plugin.activemq.pool.1.port = 61613
plugin.activemq.pool.1.user = mcollective
plugin.activemq.pool.1.password = marionette
plugin.activemq.pool.1.ssl = true
plugin.activemq.pool.1.ssl.ca = /Users/<user>/.puppetlabs/etc/mcollective/ca_crt.pem
plugin.activemq.pool.1.ssl.cert = /Users/<user>/.puppetlabs/etc/mcollective/server.crt
plugin.activemq.pool.1.ssl.key = /Users/<user>/.puppetlabs/etc/mcollective/server.key
```

The configuration above uses `activemq` as the name of the ActiveMQ broker. MCollective
will enforce that the SSL certificate presented by the server matches the name it's trying
to connect to. To use the configuration above, traffic to `activemq` must be redirected to
the local host. On most machines, that can be accomplished with
```
sudo echo "127.0.0.1   activemq" >> /etc/hosts
```

From the root of this repository, test the setup by running a server
```
RUBYLIB=lib bundle exec bin/mcollectived --config ~/.puppetlabs/etc/mcollective/server.cfg
```
and client
```
RUBYLIB=lib bundle exec bin/mco ping
```

Note that it may be useful to change the `loglevel` in `client.cfg` to debug issues with
`mco ping`.

To enable specific plugins, you may need to set `libdir` in `server.cfg` and add plugin-specific configuration.
