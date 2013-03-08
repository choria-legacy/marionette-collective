---
layout: default
title: ActiveMQ TLS
toc: false
---

[keystores]: /mcollective/deploy/middleware/activemq_keystores.html
[sslcontext]: /mcollective/deploy/middleware/activemq.html#tls-credentials
[transport]: /mcollective/deploy/middleware/activemq.html#transport-connectors

[activemq_connector]: /mcollective/reference/plugins/connector_activemq.html
[stomp_connector]: /mcollective/reference/plugins/connector_stomp.html

In order to achieve end to end encryption, we use TLS encryption between
ActiveMQ, the nodes, and the client.

## Full CA-Verified TLS (Recommended)

As of MCollective 2.0.0 and Stomp 1.2.2, it's possible to configure MCollective and ActiveMQ to only accept connections to peers with certificates signed by a shared CA. This requires:

* MCollective 2.0.0 or newer
* ActiveMQ 5.5.0 or newer
* Stomp gem 1.2.2 or newer
* The [activemq connector][activemq_connector] plugin (included with MCollective 2.0.0 and newer)


### Configure ActiveMQ to Use TLS

Do the following steps to get ActiveMQ configured:

* Follow [the ActiveMQ keystores guide][keystores] to create Java keystores for ActiveMQ.
* [Configure activemq.xml's `<sslContext>` element to point at the keystores.][sslcontext]
* [Configure the proper URIs in the broker's transport connectors.][transport]
* Restart ActiveMQ.

At this point, MCollective servers and clients should be unable to connect to ActiveMQ, since they do not yet have credentials configured.

### Configuring MCollective Servers

For the MCollective daemon you can use your existing Puppet certificates by editing the _server.cfg_

{% highlight ini %}
connector = activemq
plugin.activemq.base64 = yes
plugin.activemq.pool.size = 2
plugin.activemq.pool.1.host = stomp.my.net
plugin.activemq.pool.1.port = 61614
plugin.activemq.pool.1.user = mcollective
plugin.activemq.pool.1.password = secret
plugin.activemq.pool.1.ssl = 1
plugin.activemq.pool.1.ssl.ca = /var/lib/puppet/ssl/ca/ca_crt.pem
plugin.activemq.pool.1.ssl.key = /var/lib/puppet/ssl/private_keys/fqdn.pem
plugin.activemq.pool.1.ssl.cert = /var/lib/puppet/ssl/certs/fqdn.pem
{% endhighlight %}

Fix the paths to the private key and certificate; they will be named after each machine's Puppet certname. You can discover a node's certname by running `sudo puppet agent --configprint certname`.

### Configuring MCollective Clients

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
plugin.activemq.pool.1.port = 61614
plugin.activemq.pool.1.user = ripienaar
plugin.activemq.pool.1.password = secret
plugin.activemq.pool.1.ssl = 1
plugin.activemq.pool.1.ssl.ca = /home/rip/.mcollective.d/ca_crt.pem
plugin.activemq.pool.1.ssl.key = /home/rip/.mcollective.d/ripienaar-private.pem
plugin.activemq.pool.1.ssl.cert = /home/rip/.mcollective.d/ripienaar-cert.pem
{% endhighlight %}

If you are using the SSL or AES security plugins you can use these same files using the _/home/rip/.mcollective.d/ripienaar.pem_
as the public key for those plugins.

### Troubleshooting Common Errors

You will get some obvious errors from this code if any files are missing, but the errors from SSL validation will be pretty
hard to understand.

There are two main scenarios where ActiveMQ will reject an MCollective conneciton:

#### MCollective Uses Wrong CA to Verify ActiveMQ Cert

When the client connects using a CA set in _plugin.activemq.pool.1.ssl.ca_ that does not match the one
in the ActiveMQ _truststore.jks_:

{% highlight console %}
failed: SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed
{% endhighlight %}

And in the ActiveMQ log:

{% highlight console %}
Transport failed: javax.net.ssl.SSLHandshakeException: Received fatal alert: unknown_ca
{% endhighlight %}

#### MCollective Certs Aren't Signed by the Right CA

When your client has the correct CA but his certificates are not signed by that CA:

{% highlight console %}
failed: SSL_connect returned=1 errno=0 state=SSLv3 read finished A: sslv3 alert certificate unknown
{% endhighlight %}

And in the ActiveMQ log:

{% highlight console %}
sun.security.validator.ValidatorException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
{% endhighlight %}

## Anonymous TLS (Deprecated)

This configuration only works with the now-deprecated [stomp connector][stomp_connector]. New users should avoid it. 

### Configure ActiveMQ to Use Anonymous TLS

* Follow [the ActiveMQ keystores guide][keystores] to create a Java keystore for ActiveMQ. You can skip the truststore. 
* [Configure activemq.xml's `<sslContext>` element to point at the keystore.][sslcontext] You can skip the `trustStore` and `trustStorePassword` attributes.
* [Configure the proper URIs in the broker's transport connectors][transport], but leave off the `?needClientAuth=true` portion.
* Restart ActiveMQ.


### Configure MCollective Servers and Clients

The last step is to tell MCollective to use the SSL connection, to do this you
need to use the pool-style stomp settings, even if you just have 1 ActiveMQ
in your pool:

{% highlight ini %}
plugin.stomp.pool.size = 1
plugin.stomp.pool.host1 = stomp.your.com
plugin.stomp.pool.port1 = 61614
plugin.stomp.pool.user1 = mcollective
plugin.stomp.pool.password1 = secret
plugin.stomp.pool.ssl1 = true
{% endhighlight %}

You should now verify with tcpdump or wireshark that the connection and traffic
really is all encrypted.
