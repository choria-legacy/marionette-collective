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
