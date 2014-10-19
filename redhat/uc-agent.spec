%define        __spec_install_post %{nil}
%define          debug_package %{nil}
%define        __os_install_post %{_dbpath}/brp-compress
%define      _topdir %(echo $PWD)/

Summary: uc-agent
Name: uc-agent
Version: 1.0.1
License: APL2
Release: 1

Group: System Environment/Daemons
Vendor: UCLogs, Inc.
URL: http://uclogs.com/
SOURCE0: %{name}-%{version}.tar.gz
Source1: %{name}.init
BuildRoot: /var/tmp/uc-agent/rpmbuild/BUILDROOT
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
mkdir -p  %{buildroot}/opt/uc-agent
cp -a * %{buildroot}/opt/uc-agent
cp -a res/* %{buildroot}
mkdir -p %{buildroot}/etc/init.d
install -m 755 %{S:1} %{buildroot}/etc/init.d/%{name}

%clean
rm -rf %{buildroot}

%post
echo "Configure uc-agent to start, when booting up the OS..."
/sbin/chkconfig --add uc-agent
if [ -f "/var/run/uc-agent/license_key" ]; then
  echo "to restart uc-agent ..."
  /etc/init.d/uc-agent restart
fi

%preun
if [ $1 -eq 0 ] ; then
  ## uninstall
  echo "Stopping uc-agent ..."
  /sbin/service uc-agent stop >/dev/null 2>&1 || :
  /sbin/chkconfig --del uc-agent
fi

%files
%defattr(-,root,root,-)
%config(noreplace) %{_sysconfdir}/uc-agent/uc-agent.conf
/etc/uc-agent/*
/etc/init.d/uc-agent
/opt/uc-agent/*

