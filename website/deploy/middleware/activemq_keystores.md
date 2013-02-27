---
title: "MCollective » Deploy » Middleware » ActiveMQ Keystores"
subtitle: "Setting Up Keystores For ActiveMQ"
layout: default
---

[tls]: ./activemq.html#tls-credentials

Since ActiveMQ runs on the JVM, [configuring it to use TLS encryption/authentication][tls] requires a pair of Java keystores; it can't just use the normal PEM format certificates and keys used by Puppet and MCollective. 

Java keystores require some non-obvious steps to set up, so this guide provides full instructions, including both a [manual method](#manually-creating-keystores) and a [Puppet method](#creating-keystores-with-puppet).


## Step 0: Obtain Certificates and Keys

ActiveMQ needs the following credentials:

* A copy of the site's CA certificate
* A certificate signed by the site's CA
* A private key to match its certificate

These can come from anywhere, but the CA has to match the one used by MCollective. 

The easiest approach is to re-use your site's Puppet cert infrastructure, since it's already everywhere and has tools for issuing and signing arbitrary certificates.

As ever, remember to **protect the private key.**

### Option A: Re-Use the Node's Puppet Agent Certificate

On your ActiveMQ server:

* Locate the ssldir by running `sudo puppet agent --configprint ssldir`.
* Copy the following files to your working directory, making sure to give unique names to the cert and private key:
    * `<ssldir>/certs/ca.pem`
    * `<ssldir>/certs/<node name>.pem`
    * `<ssldir>/private_keys/<node name>.pem`

### Option B: Get a New Certificate from the Puppet CA

On your CA puppet master:

* Run `sudo puppet cert generate activemq.example.com`, substituting some name for your ActiveMQ server. Unlike with a puppet master, the cert's common name can be anything; it doesn't have to be the node's hostname or FQDN.
* Locate the ssldir by running `sudo puppet master --configprint ssldir`.
* Retrieve the following files and copy them to a working directory on your ActiveMQ server, making sure to give unique names to the cert and private key:
    * `<ssldir>/certs/ca.pem`
    * `<ssldir>/certs/activemq.example.com.pem`
    * `<ssldir>/private_keys/activemq.example.com.pem`

### Option C: Do Whatever You Want

If you have some other CA infrastructure, you can use that instead.

You can now:

* [Manually create the keystores](#manually-creating-keystores)
* [Use Puppet to create the keystores](#creating-keystores-with-puppet)

## Manually Creating Keystores

We need a **"truststore"** and a **"keystore."** We also need a **password** for each. (You can use the same password for both stores.)

Remember the password(s) for later, because it needs to [go in the activemq.xml file][tls]. 

### Step 1: Truststore

The truststore determines which certificates are allowed to connect to ActiveMQ. If you import a CA cert into it, ActiveMQ will trust any certificate signed by that CA.

> You could also _not_ import a CA, and instead import every individual certificate you want to allow. If you do that, you're on your own, but the commands should be similar.

In the working directory with your PEM-format credentials, run the following command. Replace `ca.pem` with whatever you named your copy of the CA cert, and use the password when requested.

{% highlight console %}
$ sudo keytool -import -alias "My CA" -file ca.pem -keystore truststore.jks
Enter keystore password:
Re-enter new password:
.
.
.
Trust this certificate? [no]:  y
Certificate was added to keystore
{% endhighlight %}

The truststore is now done.

If you want, you can compare fingerprints:

{% highlight console %}
$ sudo keytool -list -keystore truststore.jks
Enter keystore password:

Keystore type: JKS
Keystore provider: SUN

Your keystore contains 1 entry

my ca, Mar 30, 2012, trustedCertEntry,
Certificate fingerprint (MD5): 99:D3:28:6B:37:13:7A:A2:B8:73:75:4A:31:78:0B:68

$ sudo openssl x509 -in ca.pem -fingerprint -md5
MD5 Fingerprint=99:D3:28:6B:37:13:7A:A2:B8:73:75:4A:31:78:0B:68
{% endhighlight %}


### Step 2: Keystore

The keystore contains the ActiveMQ broker's certificate and private key, which it uses to identify itself to the applications that connect to it.

In the working directory with your PEM-format credentials, run the following commands. Substitute the names of your key and certificate files where necessary, and the common name of your ActiveMQ server's certificate for `activemq.example.com`.

These commands use both an "export/source" password and a "destination" password. The export/source password is never used again after this series of commands.

{% highlight console %}
$ sudo cat activemq_private.pem activemq_cert.pem > temp.pem
$ sudo openssl pkcs12 -export -in temp.pem -out activemq.p12 -name stomp.my.net
Enter Export Password:
Verifying - Enter Export Password:
$sudo keytool -importkeystore  -destkeystore keystore.jks -srckeystore activemq.p12 -srcstoretype PKCS12 -alias activemq.example.com
Enter destination keystore password:
Re-enter new password:
Enter source keystore password:
{% endhighlight %}

The keystore is now done.

If you want, you can compare fingerprints:

{% highlight console %}
$ sudo keytool -list -keystore keystore.jks
Enter keystore password:

Keystore type: JKS
Keystore provider: SUN

Your keystore contains 1 entry

activemq.example.com, Mar 30, 2012, PrivateKeyEntry,
Certificate fingerprint (MD5): 7E:2A:B4:4D:1E:6D:D1:70:A9:E7:20:0D:9D:41:F3:B9

$ sudo openssl x509 -in activemq_cert.pem -fingerprint -md5
MD5 Fingerprint=7E:2A:B4:4D:1E:6D:D1:70:A9:E7:20:0D:9D:41:F3:B9
{% endhighlight %}

### Step 3: Finish

Move the keystore and truststore to ActiveMQ's config directory. Make sure they are owned by the ActiveMQ user and unreadable to any other users. [Configure ActiveMQ to use them in its `sslContext`.][tls] **Double-check** that you've made activemq.xml world-unreadable, since it now contains sensitive credentials.

## Creating Keystores with Puppet

If you're managing your ActiveMQ server with Puppet anyway, you can use the [puppetlabs/java_ks module](http://forge.puppetlabs.com/puppetlabs/java_ks) to handle the format conversion.

This approach is more work for a single permanent ActiveMQ server, but less work if you intend to deploy multiple ActiveMQ servers or eventually change the credentials.

### Step 1: Install the `java_ks` Module

On your puppet master, run `sudo puppet module install puppetlabs/java_ks`.

### Step 2: Create a Puppet Class

The class to manage the keystores should do the following:

* Make sure the PEM cert and key files are present and protected.
* Declare a pair of `java_ks` resources.
* Manage the mode and ownership of the keystore files.

The code below is an example, but it will work fine if you put it in a module (example file location in the first comment) and set its parameters when you declare it. The name of the class (and its home module) can be changed as needed.


{% highlight ruby %}
    # /etc/puppet/modules/activemq/manifests/keystores.pp
    class activemq::keystores (
      $keystore_password, # required

      # User must put these files in the module, or provide other URLs
      $ca = 'puppet:///modules/activemq/ca.pem',
      $cert = 'puppet:///modules/activemq/cert.pem',
      $private_key = 'puppet:///modules/activemq/private_key.pem',

      $activemq_confdir = '/etc/activemq',
      $activemq_user = 'activemq',
    ) {

      # ----- Restart ActiveMQ if the SSL credentials ever change       -----
      # ----- Uncomment if you are fully managing ActiveMQ with Puppet. -----

      # Package['activemq'] -> Class[$title]
      # Java_ks['activemq_cert:keystore'] ~> Service['activemq']
      # Java_ks['activemq_ca:truststore'] ~> Service['activemq']


      # ----- Manage PEM files -----

      File {
        owner => root,
        group => root,
        mode  => 0600,
      }
      file {"${activemq_confdir}/ssl_credentials":
        ensure => directory,
        mode   => 0700,
      }
      file {"${activemq_confdir}/ssl_credentials/activemq_certificate.pem":
        ensure => file,
        source => $cert,
      }
      file {"${activemq_confdir}/ssl_credentials/activemq_private.pem":
        ensure => file,
        source => $private_key,
      }
      file {"${activemq_confdir}/ssl_credentials/ca.pem":
        ensure => file,
        source => $ca,
      }


      # ----- Manage Keystore Contents -----

      # Each keystore should have a dependency on the PEM files it relies on.

      # Truststore with copy of CA cert
      java_ks { 'activemq_ca:truststore':
        ensure       => latest,
        certificate  => "${activemq_confdir}/ssl_credentials/ca.pem",
        target       => "${activemq_confdir}/truststore.jks",
        password     => $keystore_password,
        trustcacerts => true,
        require      => File["${activemq_confdir}/ssl_credentials/ca.pem"],
      }

      # Keystore with ActiveMQ cert and private key
      java_ks { 'activemq_cert:keystore':
        ensure       => latest,
        certificate  => "${activemq_confdir}/ssl_credentials/activemq_certificate.pem",
        private_key  => "${activemq_confdir}/ssl_credentials/activemq_private.pem",
        target       => "${activemq_confdir}/keystore.jks",
        password     => $keystore_password,
        require      => [
          File["${activemq_confdir}/ssl_credentials/activemq_private.pem"],
          File["${activemq_confdir}/ssl_credentials/activemq_certificate.pem"]
        ],
      }


      # ----- Manage Keystore Files -----

      # Permissions only.
      # No ensure, source, or content.

      file {"${activemq_confdir}/keystore.jks":
        owner   => $activemq_user,
        group   => $activemq_user,
        mode    => 0600,
        require => Java_ks['activemq_cert:keystore'],
      }
      file {"${activemq_confdir}/truststore.jks":
        owner   => $activemq_user,
        group   => $activemq_user,
        mode    => 0600,
        require => Java_ks['activemq_ca:truststore'],
      }
    
    }
{% endhighlight %}


### Step 3: Assign the Class to the ActiveMQ Server

...using your standard Puppet site tools.

### Step 4: Finish

[Configure ActiveMQ to use the keystores in its `sslContext`][tls], probably with the Puppet template you're using to manage activemq.xml.  **Double-check** that you've made activemq.xml world-unreadable, since it now contains sensitive credentials.
