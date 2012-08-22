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
%{__install} -d -m0755  %{buildroot}%{_bindir}
%{__install} -d -m0755  %{buildroot}%{_sbindir}
%{__install} -d -m0755  %{buildroot}%{_sysconfdir}/init.d
%{__install} -d -m0755  %{buildroot}%{_libexecdir}/mcollective/
%{__install} -d -m0755  %{buildroot}%{_sysconfdir}/mcollective
%{__install} -d -m0755  %{buildroot}%{_sysconfdir}/mcollective/plugin.d
%{__install} -d -m0755  %{buildroot}%{_sysconfdir}/mcollective/ssl
%{__install} -d -m0755  %{buildroot}%{_sysconfdir}/mcollective/ssl/clients
%{__install} -m0755 bin/mcollectived %{buildroot}%{_sbindir}/mcollectived
%{__install} -m0640 etc/server.cfg.dist %{buildroot}%{_sysconfdir}/mcollective/server.cfg
%{__install} -m0644 etc/client.cfg.dist %{buildroot}%{_sysconfdir}/mcollective/client.cfg
%{__install} -m0444 etc/facts.yaml.dist %{buildroot}%{_sysconfdir}/mcollective/facts.yaml
%{__install} -m0444 etc/rpc-help.erb %{buildroot}%{_sysconfdir}/mcollective/rpc-help.erb
%{__install} -m0444 etc/data-help.erb %{buildroot}%{_sysconfdir}/mcollective/data-help.erb
%{__install} -m0444 etc/discovery-help.erb %{buildroot}%{_sysconfdir}/mcollective/discovery-help.erb
%{__install} -m0444 etc/metadata-help.erb %{buildroot}%{_sysconfdir}/mcollective/metadata-help.erb
%if 0%{?suse_version}
%{__install} -m0755 mcollective.init %{buildroot}%{_sysconfdir}/init.d/mcollective
%else
%{__install} -m0755 ext/redhat/mcollective.init %{buildroot}%{_sysconfdir}/init.d/mcollective
%endif


cp -R lib/* %{buildroot}/%{ruby_sitelib}/
cp -R plugins/* %{buildroot}%{_libexecdir}/mcollective/
cp bin/mc-* %{buildroot}%{_sbindir}/
cp bin/mco %{buildroot}%{_bindir}/
chmod 0755 %{buildroot}%{_sbindir}/*

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
%{_libexecdir}/mcollective/mcollective
%dir %{_sysconfdir}/mcollective
%dir %{_sysconfdir}/mcollective/ssl
%config%{_sysconfdir}/mcollective/rpc-help.erb
%config%{_sysconfdir}/mcollective/data-help.erb
%config%{_sysconfdir}/mcollective/discovery-help.erb

%files client
%attr(0755, root, root)%{_sbindir}/mc-call-agent
%attr(0755, root, root)%{_bindir}/mco
%doc COPYING
%config(noreplace)%{_sysconfdir}/mcollective/client.cfg
%{_libexecdir}/mcollective/mcollective/application
%{_libexecdir}/mcollective/mcollective/pluginpackager

%files
%doc COPYING
%{_sbindir}/mcollectived
%{_sysconfdir}/init.d/mcollective
%config(noreplace)%{_sysconfdir}/mcollective/server.cfg
%config(noreplace)%{_sysconfdir}/mcollective/facts.yaml
%dir %{_sysconfdir}/mcollective/ssl/clients
%config(noreplace)%{_sysconfdir}/mcollective/plugin.d

%changelog
* Tue Nov 03 2009 R.I.Pienaar <rip@devco.net>
- First release
