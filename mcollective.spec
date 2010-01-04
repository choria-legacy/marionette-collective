%define ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%define release %{rpm_release}%{?dist}

Summary: Application Server for hosting Ruby code on any capable middleware
Name: mcollective
Version: %{version}
Release: %{release}
Group: System Tools
License: Apache License, Version 2
URL: http://marionette-collective.org/
Source0: %{name}-%{version}.tgz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires: ruby
Requires: rubygems
Requires: rubygem-stomp
Requires: mcollective-common = %{version}-%{release}
Packager: R.I.Pienaar <rip@devco.net>
BuildArch: noarch

%package common
Summary: Common libraries for the mcollective clients and servers
Group: System Tools

%description common
The Marionette Collective:

Common libraries for the mcollective clients and servers

%package client
Summary: Client tools for the mcollective Application Server
Requires: mcollective-common = %{version}-%{release}
Group: System Tools

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
%{__install} -d -m0755  %{buildroot}/usr/sbin
%{__install} -d -m0755  %{buildroot}/etc/init.d
%{__install} -d -m0755  %{buildroot}/usr/libexec/mcollective/
%{__install} -d -m0755  %{buildroot}/etc/mcollective
%{__install} -m0755 mcollectived.rb %{buildroot}/usr/sbin/mcollectived
%{__install} -m0440 etc/server.cfg.dist %{buildroot}/etc/mcollective/server.cfg
%{__install} -m0444 etc/client.cfg.dist %{buildroot}/etc/mcollective/client.cfg
%{__install} -m0444 etc/facts.yaml.dist %{buildroot}/etc/mcollective/facts.yaml
%{__install} -m0755 mcollective.init %{buildroot}/etc/init.d/mcollective

cp -R lib/* %{buildroot}/%{ruby_sitelib}/
cp -R plugins/* %{buildroot}/usr/libexec/mcollective/
cp mc-* %{buildroot}/usr/sbin/
chmod 0755 %{buildroot}/usr/sbin/mc-*

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
/usr/libexec/mcollective
%dir /etc/mcollective

%files client
%attr(0755, root, root)/usr/sbin/mc-*
%doc COPYING
%config(noreplace)/etc/mcollective/client.cfg

%files
%doc COPYING
/usr/sbin/mcollectived
/etc/init.d/mcollective
%config(noreplace)/etc/mcollective/server.cfg
%config(noreplace)/etc/mcollective/facts.yaml

%changelog
* Tue Nov 03 2009 R.I.Pienaar <rip@devco.net> 
- First release
