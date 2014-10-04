%define        __spec_install_post %{nil}
%define          debug_package %{nil}
%define        __os_install_post %{_dbpath}/brp-compress
%define      _topdir %(echo $PWD)/

Summary: ma-agent
Name: ma-agent
Version: 1.0.2
License: APL2
Release: 1

Group: System Environment/Daemons
Vendor: Metrics At, Inc.
URL: http://metricsat.com/
SOURCE0: %{name}-%{version}.tar.gz
Source1: %{name}.init
BuildRoot: /var/tmp/ma-agent/rpmbuild/BUILDROOT
AutoReqProv: no


Requires: /usr/sbin/useradd /usr/sbin/groupadd
Requires: /sbin/chkconfig
Requires(post): /sbin/chkconfig
Requires(post): /sbin/service
Requires(preun): /sbin/chkconfig
Requires(preun): /sbin/service

%description
%{summary}

%prep
%setup -q

%build
# Empty section.

%install
rm -rf %{buildroot}
mkdir -p  %{buildroot}/opt/ma-agent
cp -a * %{buildroot}/opt/ma-agent
cp -a res/* %{buildroot}
mkdir -p %{buildroot}/etc/init.d
install -m 755 %{S:1} %{buildroot}/etc/init.d/%{name}

%clean
rm -rf %{buildroot}

%post
echo "Configure ma-agent to start, when booting up the OS..."
/sbin/chkconfig --add ma-agent
echo "adding 'ma-agent' group..."
getent group ma-agent >/dev/null || /usr/sbin/groupadd  ma-agent
echo "adding 'ma-agent' user..."
getent passwd ma-agent >/dev/null || \
  /usr/sbin/useradd -g ma-agent -s /bin/bash -c 'ma-agent' ma-agent
if [ -f "/etc/ma-agent/license_key" ]; then
  echo "to restart ma-agent ..."
  /etc/init.d/ma-agent restart
fi

%preun
if [ $1 -eq 0 ] ; then
  ## uninstall
  echo "Stopping ma-agent ..."
  /sbin/service ma-agent stop >/dev/null 2>&1 || :
  /sbin/chkconfig --del ma-agent
fi

%files
%defattr(-,root,root,-)
%config(noreplace) %{_sysconfdir}/ma-agent/ma-agent.conf
/etc/ma-agent/*
/etc/init.d/ma-agent
/opt/ma-agent/*

