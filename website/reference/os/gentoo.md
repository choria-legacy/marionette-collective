---
layout: mcollective
title: Using with Gentoo
disqus: true
---
[Downloads]: http://code.google.com/p/mcollective/downloads/list

# {{page.title}}
For those of you who are running Gentoo Linux, we maintain ebuilds for stomp and mcollective within our public portage overlay.  Here is information on how to access those ebuilds and install mcollective from within portage.

## Installing the local ebuild
You can either clone the Arces portage overlay, or you can extract the ebuild directly into your own overlay.

## Cloning the Arces overlay
The standard location for local portage overlays is _/usr/local/portage_ on Gentoo systems.  Our overlay is designed to fit with the multiple-overlay system introduced by Layman, although it's not part of the Layman repository list.  You can clone the repository with Git from _http://support.arces.net/public/git/arces`_`overlay.git_

{% highlight console %}
[06:59 AM] 82 [~]:adrian% cd /usr/local/portage
[06:59 AM] 83 [/usr/local/portage]:adrian% sudo git clone http://support.arces.net/public/git/arces_overlay.git
Initialized empty Git repository in /usr/local/portage/arces_overlay/.git/
{% endhighlight %}

Adjust _make.conf_ to include the new overlay.

{% highlight bash %}
PORTDIR_OVERLAY="/usr/local/portage"
PORTDIR_OVERLAY="$PORTDIR_OVERLAY /usr/local/portage/arces_overlay"
{% endhighlight %}

Update the _eix_ cache.

{% highlight console %}
[07:06 AM] 93 [/usr/local/portage]:adrian% sudo eix-update
Reading Portage settings ..
Building database (/var/cache/eix) ..
[0] "gentoo" /usr/portage/ (cache: metadata-flat)
     Reading category 154|154 (100%) Finished
[1] "" /usr/local/portage (cache: parse|ebuild*#metadata-flat#assign)
     Reading category 154|154 (100%) EMPTY!
[2] "" /usr/local/portage/arces_overlay (cache: parse|ebuild*#metadata-flat#assign)
     Reading category 154|154 (100%) Finished
Applying masks ..
Calculating hash tables ..
Writing database file /var/cache/eix ..
Database contains 14181 packages in 154 categories.
{% endhighlight %}

At this point you should see the mcollective and stomp packages in portage.

{% highlight console %}
* app-admin/mcollective [1]
     Available versions:  (~)0.4.4-r1{tbz2} (~)0.4.7{tbz2} {-client +server}
     Homepage:            http://marionette-collective.org/
     Description:         Common elements of the Marionette Collective management suite.

* dev-ruby/stomp [1]
     Available versions:  (~)1.1{tbz2} {doc}
     Homepage:            http://stomp.codehaus.org/Ruby+Client
     Description:         A Stomp client written in Ruby.

[1] /usr/local/portage/arces_overlay
{% endhighlight %}

We recommend that you add a cron job to run _git pull_ once a day from within the overlay directory to keep it up to date.

## Extracting the ebuild into your own overlay
If you have your own local portage overlay and would only like to add the ebuilds for mcollective and stomp, you can do so by retrieving them from the [Downloads] page.  Extract them into your local portage overlay directory.  The mcollective package is part of _app-admin_ and the stomp package is part of _dev-ruby_.  The category directories are included in the tarballs, so please extract them from within the top of your local portage overlay.

Once that's done, please update the _eix_ cache as described above, and you should see the packages.

## Installing mcollective
### Keywords
The packages are masked as unstable because they are not part of the Gentoo portage tree.  You can unmask them by adding the following lines to _/etc/portage/package.keywords_, replacing _~arch_ with your architecture (_~x86_, _~amd64_, etc).

{% highlight console %}
dev-ruby/stomp ~arch
app-admin/mcollective ~arch
{% endhighlight %}

### Use flags
You can install mcollective as a client, a server, or both through the portage use flags.  On most of your hosts you'll install mcollective only as a server, which is the default if no use flags are set.  On one or more administrative nodes, you'll want to install mcollective as a client to install the executable files that allow you to interact with all of the remote nodes.  Set these flags in _/etc/portage/package.use_.

{% highlight console %}
app-admin/mcollective -client server
{% endhighlight %}

### Installation
You may now install mcollective and stomp with _emerge_ as you would with any other package.
