%define        __spec_install_post %{nil}
%define          debug_package %{nil}
%define        __os_install_post %{_dbpath}/brp-compress
%define      _topdir %(echo $PWD)/

Summary: uc-agent
Name: uc-agent
Version: 1.0.2
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
## make sure /var/uc-agent directory was created
if [ -f "/var/uc-agent" ]; then
	rm -rf /var/ucagent
fi

mkdir -p /var/uc-agent

# migrate legacy run data to new location
if [ -f "/var/run/uc-agent/license_key" ] && [ ! -f "/var/uc-agent/license_key" ]; then
	mv /var/run/uc-agent/license_key /var/uc-agent/license_key
fi
if [ -f "/var/run/uc-agent/agent_id" ] && [ ! -f "/var/uc-agent/agent_id" ]; then
	mv /var/run/uc-agent/agent_id /var/uc-agent/agent_id
fi
if [ -f "/var/run/uc-agent/posdb" ]; then
	rm -rf /var/run/uc-agent/posdb
fi
if [ -f "/var/uc-agent/license_key" ]; then
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

