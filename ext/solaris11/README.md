Requirements
------------

- Ruby (pkg install pkg:/runtime/ruby-18)
- Header files (pkg install system/header)
- GCC to install JSON (pkg install developer/gcc-3)
- Stomp: gem install stomp
- Ruby-JSON: gem install json

Installation
------------

Clone the github repository and install as root:

    $ cd marionette-collective
    $ make -f ext/solaris11/Makefile install

This will use / as a default destination root directory.

IPS package
-----------

To create an IPS package, follow the excellent guide at:
http://www.neuhalfen.name/blog/2011/07/02/Solaris11-Packaging-IPS_simple_packages/

To create a basic IPS repository (and start the associated services):

    # zfs create rpool/IPS
    # zfs set atime=off rpool/IPS
    # zfs set mountpoint=/IPS rpool/IPS
    # mkdir /IPS/Solaris11
    # svcadm enable application/pkg/server
    # svccfg -s application/pkg/server setprop pkg/inst_root=/IPS/Solaris11
    # svccfg -s application/pkg/server setprop pkg/readonly=false
    # pkgrepo create /IPS/Solaris11/
    # pkgrepo set -s /IPS/Solaris11 publisher/prefix=legrand.im
    # pkgrepo -s /IPS/Solaris11 refresh
    # svcadm refresh application/pkg/server
    # svcadm enable application/pkg/server
    # pkg set-publisher -O http://localhost:80 legrand.im

To create and send the package itself, from the guide above:

    # mkdir ~/package
    # cd <GITHUB>/marionette-collective
    # cat Makefile | sed 's/DESTDIR=$/DESTDIR=~\/package/' > Makefile.package
    # make -f ext/solaris11/Makefile.package install
    # pkg install pkg:/file/gnu-findutils
    # export ROOT=/
    # export description="MCollective"
    # export user="root"
    # export group="root"
    # cd ~/package
    # cat > ../send.sh << "EOF"
    #!/bin/sh
    export PKGSEND="pkgsend -s http://localhost:80"
    eval `$PKGSEND open mcollective@1.1-1`
    $PKGSEND add license ./COPYING license=lorem_ipsum
    $PKGSEND add set name=description value="${description}"
    EOF
    # gfind . -type d -not -name . -printf "\$PKGSEND add dir mode=%m owner=${user} group=${group} path=$ROOT/%h/%f \n"  >> ../send.sh
    # gfind . -type f -not -name LICENSE   -printf "\$PKGSEND add file %h/%f mode=%m owner=${user} group=${group} path=$ROOT/%h/%f \n" >> ../send.sh
    # gfind . -type l -not -name LICENSE   -printf "\$PKGSEND add link path=%h/%f target=%l \n" >> ../send.sh
    # echo '$PKGSEND close' >> ../send.sh
    # sh -x ../send.sh

The package can then be installed with:

    # pkg install pkg://legrand.im/mcollective

Configuration
-------------

There is no packaged configuration; you can use the following example:

    # cat > /etc/mcollective/client.cfg << "EOF"
    topicprefix = /topic/
    main_collective = mcollective
    collectives = mcollective
    libdir = /usr/share/mcollective/plugins
    logfile = /dev/null
    loglevel = info
    # Plugins
    securityprovider = psk
    plugin.psk = unset
    connector = stomp
    plugin.stomp.host = mqserver
    plugin.stomp.port = 6163
    plugin.stomp.user = mcollective
    plugin.stomp.password = changeme
    # Facts
    factsource = yaml
    plugin.yaml = /etc/mcollective/facts.yaml
    EOF

License
------

http://creativecommons.org/publicdomain/zero/1.0/

To the extent possible under law, Mathieu Legrand has waived all copyright and related or
neighboring rights to this work. This work is published from: Singapore.


