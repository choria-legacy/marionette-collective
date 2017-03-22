beaker tests for validation of MCollective in puppet-agent

# WARNING

![There be Dragons](http://upload.wikimedia.org/wikipedia/commons/thumb/b/bc/Chinese_black_dragon.svg/235px-Chinese_black_dragon.svg.png)

**WARNING:** Under NO circumstances should you use **any** of the
certificate files located in the /acceptance directory or any of
its subdirectories in a production system. The private keys are
publicly available and **will** result in an insecure environment

# Files directory

/files contains pre-generated certificates and configuration files
that are used by the acceptance test pre-suites in order to quickly
facilitate a running environment on the system under test. The
certificates in the /files directory are for testing purposes only
and are publicly available.

These files were generated using the command outlined below, in the
*SSL setup* section.

# SSL setup

/ssl is a puppet master's ssl directory.  Selected files from this
have been copied into the files/ directory, either directly as .pem
files, or combined into java truststores.

Commands used to set it up:

    puppet master --ssldir=`pwd`/ssl
    puppet cert --ssldir=`pwd`/ssl generate activemq
    puppet cert --ssldir=`pwd`/ssl generate mcollective-client
    puppet cert --ssldir=`pwd`/ssl generate mcollective-server

    keytool -storepasswd -storepass notsecret -import -alias 'puppet ca' -file ssl/ca/ca_crt.pem -keystore files/activemq.truststore
    cat ssl/private_keys/activemq.pem ssl/certs/activemq.pem > activemq.combined.pem
    openssl pkcs12 -password pass:notsecret -export -in activemq.combined.pem -out activemq.p12 -name activemq.example.com
    keytool -importkeystore -destkeystore files/activemq.keystore -deststorepass notsecret -srckeystore activemq.p12 -srcstoretype PKCS12 -srcstorepass notsecret -alias activemq.example.com
    rm activemq.combined.pem activemq.p12

    cp ssl/ca/ca_crt.pem files/ca_crt.pem
    cp ssl/certs/mcollective-server.pem files/server.crt
    cp ssl/private_keys/mcollective-server.pem files/server.key
    cp ssl/certs/mcollective-client.pem files/client.crt
    cp ssl/private_keys/mcollective-client.pem files/client.key

# Running with Rake

The rake task `ci:test:aio` will provision, install, and execute the tests
for you. It requires the environment variable for the sha of the puppet-agent
version that should be installed during testing.

The minimal invocation of this task would be:
```
bundle exec rake ci:test:aio  SHA=1.8.2
```

Typically, this task would be invoked against a development build with a
specific host target in mind. Given that we would like to test the MCO
functionality in the latest nightly build of puppet-agent on an Ubuntu 16.04
x86_64 instance, the command would be:
```
bundle exec rake ci:test:aio  SHA=nightly TEST_TARGET=ubuntu1604-64mco_master.a
```

## Environment variables
The following environment variables are used in conjunction with the
`ci:test:aio` rake task:

SHA  _required_
    :  Build identifier of puppet-agent version to be installed, release tag
    or full SHA, (e.g. `nightly`, `1.8.2`,
    `aa3068e6859a695167a4b7ac06584b4d4ace525f`).

SUITE_VERSION
    :  If the SHA used is a development build, then this variable must be
    specified, (e.g. 1.8.2.62.gaa3068e).

TEST_TARGET
    :  Beaker-hostgenerator string used to dynamically create a Beaker hosts
    file. The `mco_master` role must be part of this string. If left
    unspecified, this will default to `windows2012r2-64mco_master.a`.

MASTER_TEST_TARGET
    :  Beaker-hostgenerator string used to dynamically create a Beaker hosts
    file. If unspecified, this will default to `redhat7-64ma`.

BEAKER_HOSTS
    :  Path to an existing Beaker hosts file to be used.

ACTIVEMQ_SOURCE
    :  A url from which to download pre-built ActiveMQ binaries. Together with
    ACTIVEMQ_VERSION, specifies where to get binaries. The default uses an
    internal Puppet mirror, externally you should use http://apache.osuosl.org.
    Note that osuosl only hosts the latest releases. Setting this will attempt
    to fetch a package from $ACTIVEMQ_SOURCE/activemq/$ACTIVEMQ_VERSION/apache-activemq-$ACTIVEMQ_VERSION-bin.tar.gz
    (or .zip on Windows).

ACTIVEMQ_VERSION
    :  The version of ActiveMQ requested.
