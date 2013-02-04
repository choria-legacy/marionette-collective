---
layout: default
title: ActiveMQ TLS
toc: false
---
[Security]: http://activemq.apache.org/security.html
[Registration]: /mcollective/reference/plugins/registration.html
[Wildcard]: http://activemq.apache.org/wildcards.html

In order to achieve end to end encryption we use TLS encryption between
ActiveMQ, the nodes and the client.

To set this up you need to Java Keystore, the instructions here work for Java
1.6 either Sun or OpenJDK based.

## Full CA verified TLS between Stomp >= 1.2.2 and ActiveMQ
As of MCollective 2.0.0 and Stomp 1.2.2 it's possible to setup a TLS setup
that will only accept clients with certificates signed by a CA shared with
your clients and your ActiveMQ server like the one provided by Puppet.

You can only use this setup using the ActiveMQ specific connector plugin, not using
the generic Stomp one.

These examples will use the Puppet CA to generate the certificates but you can
use any CA as long as you have PEM format keys and certificates.

### Create ActiveMQ certificates and keystores
With this setup we need the following:

 * A certificate and keys for the ActiveMQ - we will call the ActiveMQ instance stomp.my.net
 * A Certificate Authority certificate
 * A key store for the ActiveMQ certificates
 * A trust store instructing ActiveMQ what connections to trust

First we create the trust store, we load in our CA file which will instruct ActiveMQ
to trust any certificate signed by the Puppet CA. You could also load in each individual
certificate for every client if you wanted to be really strict about it.

{% highlight bash %}
# keytool -import -alias "My CA" -file /var/lib/puppet/ssl/ca/ca_crt.pem -keystore truststore.jks
Enter keystore password:
Re-enter new password:
.
.
.
Trust this certificate? [no]:  y
Certificate was added to keystore
{% endhighlight %}

You can view your certificate:

{% highlight bash %}
# keytool -list -keystore truststore.jks
Enter keystore password:

Keystore type: JKS
Keystore provider: SUN

Your keystore contains 1 entry

my ca, Mar 30, 2012, trustedCertEntry,
Certificate fingerprint (MD5): 99:D3:28:6B:37:13:7A:A2:B8:73:75:4A:31:78:0B:68
{% endhighlight %}

Note the MD5 fingerprint, you can verify this is the one from your CA:

{% highlight bash %}
# openssl x509 -in /var/lib/puppet/ssl/ca/ca_crt.pem -fingerprint -md5
MD5 Fingerprint=99:D3:28:6B:37:13:7A:A2:B8:73:75:4A:31:78:0B:68
{% endhighlight %}

Now we create the certificate for our ActiveMQ machine and store that in the key store

{% highlight bash %}
# puppet cert generate stomp.my.net
notice: stomp.my.net has a waiting certificate request
notice: Signed certificate request for stomp.my.net
notice: Removing file Puppet::SSL::CertificateRequest stomp.my.net at '/var/lib/puppet/ssl/ca/requests/stomp.my.net.pem'
notice: Removing file Puppet::SSL::CertificateRequest stomp.my.net at '/var/lib/puppet/ssl/certificate_requests/stomp.my.net.pem'
{% endhighlight %}

And then we convert it into a format keytool can understand and import it:

{% highlight bash %}
# cat /var/lib/puppet/ssl/private_keys/stomp.my.net.pem /var/lib/puppet/ssl/certs/stomp.my.net.pem > temp.pem
# openssl pkcs12 -export -in temp.pem -out activemq.p12 -name stomp.my.net
Enter Export Password:
Verifying - Enter Export Password:
# keytool -importkeystore  -destkeystore keystore.jks -srckeystore activemq.p12 -srcstoretype PKCS12 -alias stomp.my.net
Enter destination keystore password:
Re-enter new password:
Enter source keystore password:
{% endhighlight %}

You can validate this was correct:

{% highlight bash %}
# keytool -list -keystore keystore.jks
Enter keystore password:

Keystore type: JKS
Keystore provider: SUN

Your keystore contains 1 entry

stomp.my.net, Mar 30, 2012, PrivateKeyEntry,
Certificate fingerprint (MD5): 7E:2A:B4:4D:1E:6D:D1:70:A9:E7:20:0D:9D:41:F3:B9

# puppet cert fingerprint stomp.my.net --digest=md5
MD5 Fingerprint=7E:2A:B4:4D:1E:6D:D1:70:A9:E7:20:0D:9D:41:F3:B9
{% endhighlight %}

### Configure ActiveMQ
We need to tell ActiveMQ to read the stores we made:

{% highlight xml %}
<sslContext>
   <sslContext
   	keyStore="keystore.jks" keyStorePassword="secret"
   	trustStore="truststore.jks" trustStorePassword="secret"
   />
</sslContext>
{% endhighlight %}

And we need to tell ActiveMQ to only accept fully verified connections:

{% highlight xml %}
<transportConnectors>
    <transportConnector name="openwire" uri="tcp://0.0.0.0:6166"/>
    <transportConnector name="stompssl" uri="stomp+ssl://0.0.0.0:6164?needClientAuth=true"/>
</transportConnectors>
{% endhighlight %}

If you were to attempt to connect a mcollectived or client using the anonymous setup
detailed above that should fail as we have not yet setup credentials for the mcollectived
or mcollective client to use.

### Setting up mcollectived

For the MCollective daemon you can use your existing Puppet certificates by editing the _server.cfg_

{% highlight ini %}
connector = activemq
plugin.activemq.base64 = yes
plugin.activemq.pool.size = 2
plugin.activemq.pool.1.host = stomp.my.net
plugin.activemq.pool.1.port = 6164
plugin.activemq.pool.1.user = mcollective
plugin.activemq.pool.1.password = secret
plugin.activemq.pool.1.ssl = 1
plugin.activemq.pool.1.ssl.ca = /var/lib/puppet/ssl/ca/ca_crt.pem
plugin.activemq.pool.1.ssl.key = /var/lib/puppet/ssl/private_keys/fqdn.pem
plugin.activemq.pool.1.ssl.cert = /var/lib/puppet/ssl/certs/fqdn.pem
{% endhighlight %}

Fix the paths to the private key and certificate, they will be named after your machines FQDN.

### Setting up mcollective clients

Each client will now need a TLS certificate issued by the Puppet CA in order to be able to
connect to the ActiveMQ:

{% highlight bash %}
# puppet cert generate ripienaar
notice: ripienaar has a waiting certificate request
notice: Signed certificate request for ripienaar
notice: Removing file Puppet::SSL::CertificateRequest ripienaar at '/var/lib/puppet/ssl/ca/requests/ripienaar.pem'
notice: Removing file Puppet::SSL::CertificateRequest ripienaar at '/var/lib/puppet/ssl/certificate_requests/ripienaar.pem'
{% endhighlight %}

Copy the certificates to your user:

{% highlight bash %}
# mkdir /home/rip/.mcollective.d
# cp /var/lib/puppet/ssl/ca/ca_crt.pem /home/rip/.mcollective.d/
# cp /var/lib/puppet/ssl/private_keys/ripienaar.pem /home/rip/.mcollective.d/ripienaar-private.pem
# cp /var/lib/puppet/ssl/public_keys/ripienaar.pem /home/rip/.mcollective.d/ripienaar.pem
# cp /var/lib/puppet/ssl/certs/ripienaar.pem /home/rip/.mcollective.d/ripienaar-cert.pem
# chown -R rip:rip /home/rip/.mcollective.d
{% endhighlight %}

You can now configure the mcollective client config in _/home/rip/.mcollective_ to use these:

{% highlight ini %}
connector = activemq
plugin.activemq.base64 = yes
plugin.activemq.pool.size = 2
plugin.activemq.pool.1.host = stomp.my.net
plugin.activemq.pool.1.port = 6164
plugin.activemq.pool.1.user = ripienaar
plugin.activemq.pool.1.password = secret
plugin.activemq.pool.1.ssl = 1
plugin.activemq.pool.1.ssl.ca = /home/rip/.mcollective.d/ca_crt.pem
plugin.activemq.pool.1.ssl.key = /home/rip/.mcollective.d/ripienaar-private.pem
plugin.activemq.pool.1.ssl.cert = /home/rip/.mcollective.d/ripienaar-cert.pem
{% endhighlight %}

If you are using the SSL or AES security plugins you can use these same files using the _/home/rip/.mcollective.d/ripienaar.pem_
as the public key for those plugins.

### Common Errors

You will get some obvious errors from this code if any files are missing, but the errors fro SSL validation will be pretty
hard to understand.

There are only 2 scenarios here:

#### ActiveMQ rejects the client
When the client connects using a CA set in _plugin.activemq.pool.1.ssl.ca_ that does not match the one
in the ActiveMQ _truststore.jks_:

{% highlight console %}
failed: SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed
{% endhighlight %}

And in the ActiveMQ log:

{% highlight console %}
Transport failed: javax.net.ssl.SSLHandshakeException: Received fatal alert: unknown_ca
{% endhighlight %}

When your client has the correct CA but his certificates are not signed by that CA:

{% highlight console %}
failed: SSL_connect returned=1 errno=0 state=SSLv3 read finished A: sslv3 alert certificate unknown
{% endhighlight %}

And in the ActiveMQ log:

{% highlight console %}
sun.security.validator.ValidatorException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
{% endhighlight %}

## Basic anonymous TLS between Stomp and ActiveMQ

### Create a keystore with existing certs
If you have an exiting PKI deployment, you can probably reuse Puppet ones too the main
point is that you already have a key and signed cert signed by some CA and you
now want to create a Java Keystore follow these steps:

{% highlight bash %}
# cat /etc/pki/host.key /etc/pki/ca.pem /etc/pki/host.cert >cert.pem
# openssl pkcs12 -export -in cert.pem -out activemq.p12 -name `hostname`
# keytool -importkeystore -deststorepass secret -destkeypass secret -destkeystore keystore.jks -srckeystore activemq.p12 -srcstoretype PKCS12 -alias `hostname`
{% endhighlight %}

The above steps will create a standard Java keystore in _keystore.jks_ which you
should store in your ActiveMQ config directory.  It will have a password
_secret_ you should change this.

### Configure ActiveMQ

To let ActiveMQ load your keystore you should add the following to the
_activemq.xml_ file:

{% highlight xml %}
<sslContext>
   <sslContext keyStore="keystore.jks" keyStorePassword="secret" />
</sslContext>
{% endhighlight %}

And you should add a SSL stomp listener, you should get port 6164 opened:

{% highlight xml %}
<transportConnectors>
    <transportConnector name="openwire" uri="tcp://0.0.0.0:6166"/>
    <transportConnector name="stomp" uri="stomp://0.0.0.0:6163"/>
    <transportConnector name="stompssl" uri="stomp+ssl://0.0.0.0:6164"/>
</transportConnectors>
{% endhighlight %}

### Configure MCollective

The last step is to tell MCollective to use the SSL connection, to do this you
need to use the new pool based configuration, even if you just have 1 ActiveMQ
in your pool:

{% highlight ini %}
plugin.stomp.pool.size = 1
plugin.stomp.pool.host1 = stomp.your.com
plugin.stomp.pool.port1 = 6164
plugin.stomp.pool.user1 = mcollective
plugin.stomp.pool.password1 = secret
plugin.stomp.pool.ssl1 = true
{% endhighlight %}

You should now verify with tcpdump or wireshark that the connection and traffic
really is all encrypted.
