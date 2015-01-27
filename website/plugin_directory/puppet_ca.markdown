---
layout: normal
title: "MCollective Plugin: Puppet CA Agent"
---

This agent lets you sign, list, revoke and clean certificates on your Puppet Certificate Authorities

Installation
============

 * The source is on [GitHub](https://github.com/puppetlabs/mcollective-plugins/tree/master/agent/puppetca/)


Usage
=====

The commands available are shown below:

List:
-----

<pre>
% mco rpc puppetca list
Determining the amount of hosts matching filter for 2 seconds .... 2

 * [ ============================================================> ] 2 / 2


puppet1.your.net:
         Signed:
           ["host1.your.net",
            "host2.your.net"]
         Waiting CSRs:
           ["host3.your.net"]

puppet2.your.net:
         Signed:
           ["host4.your.net",
            "host5.your.net"]
         Waiting CSRs:
           []
</pre>

Sign:
-----

<pre>
% mco rpc puppetca sign certname=host3.your.net
Determining the amount of hosts matching filter for 2 seconds .... 2

 * [ ============================================================> ] 2 / 2


puppet2.your.net                  Request Aborted
   No cert found to sign

puppet1.your.net
   Result: notice: Signed certificate request for host3.your.net
           notice: Removing file Puppet::SSL::CertificateRequest host3.your.net at '/var/lib/puppet/ssl/ca/requests/host3.your.net.pem'


Finished processing 2 / 2 hosts in 1207.45 ms
</pre>

Revoke:
-------

Note how puppetca doesn't behave too well when you ask it to revoke a certificate that doesn't exist, doesn't cause problems though

<pre>
% mco rpc puppetca revoke certname=host3.your.net
Determining the amount of hosts matching filter for 2 seconds .... 2

 * [ ============================================================> ] 2 / 2


puppet1.your.net                  
   Result: notice: Revoked certificate with serial 156

puppet2.your.net
   Result: notice: Revoked certificate with serial # Inventory of signed certificates
</pre>

Clean
-----

<pre>
% mco rpc puppetca clean certname=host3.your.net
Determining the amount of hosts matching filter for 2 seconds .... 2

 * [ ============================================================> ] 2 / 2


monitor3.your.net                  
   Result: Removed signed cert: /var/lib/puppet/ssl/ca/signed/host3.your.net.pem.


Finished processing 2 / 2 hosts in 355.97 ms
