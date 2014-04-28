---
layout: default
title: "MCollective » Deploy » Demo Toolkit"
subtitle: "Demo MCollective With Vagrant"
toc: false
---

[mco_vagrant]: https://github.com/ripienaar/mcollective-vagrant
[readme]: https://github.com/ripienaar/mcollective-vagrant/blob/master/README.md
[vagrant_download]: http://www.vagrantup.com/downloads.html
[vagrant_install]: http://docs.vagrantup.com/v2/installation/index.html
[vagrant_docs]: http://docs.vagrantup.com


> If you've never used MCollective before, start here.

This is a Vagrant-based demo environment that you can quickly get running on your own hardware. On a reasonably powerful server (around 32GB of memory), you can easily run a couple dozen nodes; on a modern-ish laptop, you can probably get at least five, maybe as many as ten.

The demo creates a fully functional MCollective deployment. It has a lightweight middleware and low security, but enables all major MCollective features, including direct addressing, multiple discovery methods, and several agent plugins.

Getting Started
-----

1. [Download Vagrant][vagrant_download] and [install it][vagrant_install] on the machine that will be hosting the demo VMs. You may need to install VirtualBox first.
2. Go to the [mcollective-vagrant repository on GitHub][mco_vagrant]. Clone the repo to your host machine, and follow the instructions in the [README][].

