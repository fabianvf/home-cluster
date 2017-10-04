#!/usr/bin/env bash

if [ "$EUID" -ne "0" ]; then
  echo "This script must be run as root." >&2
  exit 1
fi
(set -x

echo "changeme" | passwd root --stdin

# Enable root ssh key access
cp -R /home/vagrant/.ssh /root/.ssh

# Enable ovirt.org repository
)

# Enable password based SSH auth
if ! grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config ; then
  sed -i -e '/^PasswordAuthentication/s/^.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config
fi
# Enable root logon
if  ! grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config ; then
  sed -i -e '/^PermitRootLogin/s/^.*$/PermitRootLogin yes/' /etc/ssh/sshd_config
fi
/sbin/service sshd restart
