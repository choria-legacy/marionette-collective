beaker tests for validation of MCollective in puppet-agent

This repository creates a single-node install of MCollective with ActiveMQ

It assumes beaker and vagrant locally available.

# Usage

    gem install beaker
    ./run.sh

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
