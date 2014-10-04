echo "This script requires superuser access to install rpm packages."
echo "You will be prompted for your password by sudo."

# clear any previous sudo permission
sudo -k

# run inside sudo
sudo sh <<SCRIPT

  # add treasure data repository to yum
  cat >/etc/yum.repos.d/metricsat.repo <<'EOF';
[metricsat]
name = Metrics At, Inc.
baseurl = http://yum.metricsat.com/repo/\$basearch
enabled=1
gpgcheck=0
EOF

SCRIPT