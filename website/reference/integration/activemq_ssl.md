---
layout: default
title: ActiveMQ TLS
toc: false
---

[keystores]: /mcollective/deploy/middleware/activemq_keystores.html
[sslcontext]: /mcollective/deploy/middleware/activemq.html#tls-credentials
[transport]: /mcollective/deploy/middleware/activemq.html#transport-connectors

[activemq_connector]: /mcollective/reference/plugins/connector_activemq.html
[ssl_security]: /mcollective/reference/plugins/security_ssl.html
[aes_security]: /mcollective/reference/plugins/security_aes.html

You can configure MCollective and ActiveMQ to do end-to-end encryption over TLS. This allows you to use MCollective's fast and efficient [SSL security plugin][ssl_security] instead of the slow and hard to configure [AES security plugin][aes_security]. 

There are two main approaches:

* [CA-verified TLS](#ca-verified-tls) encrypts traffic, and also lets you restrict middleware connections --- only nodes with valid certificates from the site's CA can connect.
* [Anonymous TLS](#anonymous-tls) encrypts messages to prevent casual traffic sniffing, and will prevent the passwords MCollective uses to connect to ActiveMQ from being stolen. However, it doesn't check whether nodes are allowed to connect, so you have to trust your username and password security.

This feature requires:

* MCollective 2.0.0 or newer
* ActiveMQ 5.5.0 or newer
* Stomp gem 1.2.2 or newer
* The [activemq connector][activemq_connector] plugin (included with MCollective 2.0.0 and newer)

## CA-Verified TLS

**(Recommended For Most Users)**

### Summary

This approach configures MCollective and ActiveMQ to only accept connections when the peer has a certificate signed by the site's CA. 

**Benefits:**

This approach gives extra security, and your MCollective servers will generally already have the credentials they need since you can re-use Puppet certificates.

**Drawbacks:**

You will need to go out of your way to issue keys and certificates to your admin users, which is an extra step when onboarding a new admin.


### Step 1: Configure ActiveMQ to Use TLS

Do the following steps to get ActiveMQ configured:

* Follow [the ActiveMQ keystores guide][keystores] to create Java keystores for ActiveMQ.
* [Configure activemq.xml's `<sslContext>` element to point at the keystores.][sslcontext]
* [Configure the proper URIs in the broker's transport connectors.][transport]
* Restart ActiveMQ.

At this point, MCollective servers and clients should be unable to connect to ActiveMQ, since they do not yet have credentials configured.

### Step 2: Configure MCollective Servers

For the MCollective daemon you can use your existing Puppet certificates by editing the _server.cfg_ file:

{% highlight ini %}
connector = activemq
# Optional:
# plugin.activemq.base64 = yes
plugin.activemq.pool.size = 1
plugin.activemq.pool.1.host = stomp.example.com
plugin.activemq.pool.1.port = 61614
plugin.activemq.pool.1.user = mcollective
plugin.activemq.pool.1.password = secret
plugin.activemq.pool.1.ssl = true
plugin.activemq.pool.1.ssl.ca = /var/lib/puppet/ssl/ca/ca_crt.pem
plugin.activemq.pool.1.ssl.key = /var/lib/puppet/ssl/private_keys/<NAME>.pem
plugin.activemq.pool.1.ssl.cert = /var/lib/puppet/ssl/certs/<NAME>.pem
{% endhighlight %}

* Set the correct paths to each node's private key and certificate; they will be named after the node's Puppet certname and located in the ssldir.
    * You can locate a node's private key by running `sudo puppet agent --configprint hostprivkey`, the certificate with `sudo puppet agent --configprint hostcert`, and the CA certificate with `sudo puppet agent --configprint localcacert`.
* Set the correct username and password.

### Step 3: Configure MCollective Clients

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
# Optional:
# plugin.activemq.base64 = yes
plugin.activemq.pool.size = 1
plugin.activemq.pool.1.host = stomp.example.com
plugin.activemq.pool.1.port = 61614
plugin.activemq.pool.1.user = ripienaar
plugin.activemq.pool.1.password = secret
plugin.activemq.pool.1.ssl = true
plugin.activemq.pool.1.ssl.ca = /home/rip/.mcollective.d/ca_crt.pem
plugin.activemq.pool.1.ssl.key = /home/rip/.mcollective.d/ripienaar-private.pem
plugin.activemq.pool.1.ssl.cert = /home/rip/.mcollective.d/ripienaar-cert.pem
{% endhighlight %}

If you are using the SSL security plugin, you can use these same files by setting `/home/rip/.mcollective.d/ripienaar.pem` as the public key.

### Finish: Verify Encryption

If you want to be sure of this, you should now verify with tcpdump or wireshark that the connection and traffic
really is all encrypted.

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





## Anonymous TLS

**(Less Recommended)**

### Summary

This approach configures MCollective and ActiveMQ to encrypt traffic via TLS, but accept connections from anyone.

**Benefits:**

This approach requires less configuration, especially when adding new admin users.

**Drawbacks:**

This approach has some relative security drawbacks. Depending on your site's security needs, these may not concern you --- since MCollective's application-level security plugins will prevent an attacker from issuing agent commands and owning your servers, attacks like those below would only result in denial of service plus some leakage of inventory data via lower-level discovery protocols.

* Although attackers can't sniff MCollective's ActiveMQ passwords, there's nothing to prevent them from logging in if they steal a password through some other means. (With CA-verified TLS, on the other hand, they would also require a private key and certificate, which provides some additional security depth.)
* An attacker able to run a man-in-the-middle attack at your site could fool your MCollective servers into trusting a malicious ActiveMQ server. 


### Step 1: Configure ActiveMQ to Use Anonymous TLS

* Follow [the ActiveMQ keystores guide][keystores] to create a Java keystore for ActiveMQ. _You can skip the truststore._ 
* [Configure activemq.xml's `<sslContext>` element to point at the keystore.][sslcontext] _You can skip the `trustStore` and `trustStorePassword` attributes._
* [Configure the proper URIs in the broker's transport connectors][transport], but _leave off the `?needClientAuth=true` portion._
* Restart ActiveMQ.


### Step 2: Configure MCollective Servers and Clients

Set the following settings in the `server.cfg` and `client.cfg` (or `~/.mcollective`) files:

{% highlight ini %}
connector = activemq
# Optional:
# plugin.activemq.base64 = yes
plugin.activemq.pool.size = 1
plugin.activemq.pool.1.host = stomp.example.com
plugin.activemq.pool.1.port = 61614
plugin.activemq.pool.1.user = mcollective
plugin.activemq.pool.1.password = secret
plugin.activemq.pool.1.ssl = true
plugin.activemq.pool.1.ssl.fallback = true
{% endhighlight %}

The `plugin.activemq.pool.1.ssl.fallback` setting tells the plugin that it is allowed to:

* Connect to an unverified server
* Connect without presenting its own SSL credentials

...if it is missing any of the `.ca` `.cert` or `.key` settings or cannot find the files they reference. If the settings _are_ present (and point to correct files), MCollective will try to do a verified connection.


### Finish: Verify Encryption

If you want to be sure of this, you should now verify with tcpdump or wireshark that the connection and traffic
really is all encrypted.
