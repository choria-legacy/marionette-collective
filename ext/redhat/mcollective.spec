%{!?ruby_sitelib: %global ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")}
%define release %{rpm_release}%{?dist}

Summary: Application Server for hosting Ruby code on any capable middleware
Name: mcollective
Version: %{version}
Release: %{release}
Group: System Environment/Daemons
License: ASL 2.0
URL: http://puppetlabs.com/mcollective/introduction/
Source0: http://downloads.puppetlabs.com/mcollective/%{name}-%{version}.tgz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires: ruby
BuildRequires: ruby(abi) = 1.8
Requires: mcollective-common = %{version}-%{release}
Packager: R.I.Pienaar <rip@devco.net>
BuildArch: noarch

%package common
Summary: Common libraries for the mcollective clients and servers
Group: System Environment/Libraries
Requires: ruby
Requires: ruby(abi) = 1.8
Requires: rubygems
Requires: rubygem(stomp)

%description common
The Marionette Collective:

Common libraries for the mcollective clients and servers

%package client
Summary: Client tools for the mcollective Application Server
Requires: mcollective-common = %{version}-%{release}
Group: Applications/System

%description client
The Marionette Collective:

Client tools for the mcollective Application Server

%description
The Marionette Collective:

Server for the mcollective Application Server

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
%{__install} -d -m0755  %{buildroot}/%{ruby_sitelib}/mcollective
%{__install} -d -m0755  %{buildroot}/usr/bin
%{__install} -d -m0755  %{buildroot}/usr/sbin
%{__install} -d -m0755  %{buildroot}/etc/init.d
%{__install} -d -m0755  %{buildroot}/usr/libexec/mcollective/
%{__install} -d -m0755  %{buildroot}/etc/mcollective
%{__install} -d -m0755  %{buildroot}/etc/mcollective/plugin.d
%{__install} -d -m0755  %{buildroot}/etc/mcollective/ssl
%{__install} -d -m0755  %{buildroot}/etc/mcollective/ssl/clients
%{__install} -m0755 bin/mcollectived %{buildroot}/usr/sbin/mcollectived
%{__install} -m0640 etc/server.cfg.dist %{buildroot}/etc/mcollective/server.cfg
%{__install} -m0644 etc/client.cfg.dist %{buildroot}/etc/mcollective/client.cfg
%{__install} -m0444 etc/facts.yaml.dist %{buildroot}/etc/mcollective/facts.yaml
%{__install} -m0444 etc/rpc-help.erb %{buildroot}/etc/mcollective/rpc-help.erb
%if 0%{?suse_version}
%{__install} -m0755 mcollective.init %{buildroot}/etc/init.d/mcollective
%else
%{__install} -m0755 ext/redhat/mcollective.init %{buildroot}/etc/init.d/mcollective
%endif


cp -R lib/* %{buildroot}/%{ruby_sitelib}/
cp -R plugins/* %{buildroot}/usr/libexec/mcollective/
cp bin/mc-* %{buildroot}/usr/sbin/
cp bin/mco %{buildroot}/usr/bin/
chmod 0755 %{buildroot}/usr/sbin/*

%clean
rm -rf %{buildroot}

%post
/sbin/chkconfig --add mcollective || :

%postun
if [ "$1" -ge 1 ]; then
	/sbin/service mcollective condrestart &>/dev/null || :
fi

%preun
if [ "$1" = 0 ] ; then
  /sbin/service mcollective stop > /dev/null 2>&1
  /sbin/chkconfig --del mcollective || :
fi

%files common
%doc COPYING
%{ruby_sitelib}/mcollective.rb
%{ruby_sitelib}/mcollective
/usr/libexec/mcollective/mcollective/agent
/usr/libexec/mcollective/mcollective/audit
/usr/libexec/mcollective/mcollective/connector
/usr/libexec/mcollective/mcollective/facts
/usr/libexec/mcollective/mcollective/registration
/usr/libexec/mcollective/mcollective/security
%dir /etc/mcollective
%dir /etc/mcollective/ssl
%config/etc/mcollective/rpc-help.erb

%files client
%attr(0755, root, root)/usr/sbin/mc-call-agent
%attr(0755, root, root)/usr/bin/mco
%doc COPYING
%config(noreplace)/etc/mcollective/client.cfg
/usr/libexec/mcollective/mcollective/application
/usr/libexec/mcollective/mcollective/pluginpackager

%files
%doc COPYING
/usr/sbin/mcollectived
/etc/init.d/mcollective
%config(noreplace)/etc/mcollective/server.cfg
%config(noreplace)/etc/mcollective/facts.yaml
%dir /etc/mcollective/ssl/clients
%config(noreplace)/etc/mcollective/plugin.d

%changelog
* Tue Nov 03 2009 R.I.Pienaar <rip@devco.net>
- First release
