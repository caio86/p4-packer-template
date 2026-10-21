#!/bin/sh
set -eux

# Vagrant insecure public key (Vagrant swaps it for a unique key on first `vagrant up`)
install -d -m 700 -o vagrant -g vagrant /home/vagrant/.ssh
curl -fsSL https://raw.githubusercontent.com/hashicorp/vagrant/main/keys/vagrant.pub \
  -o /home/vagrant/.ssh/authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys

# Faster SSH logins
grep -q '^UseDNS' /etc/ssh/sshd_config || echo 'UseDNS no' >> /etc/ssh/sshd_config

# Cloud-init has done its job; don't let it re-run on every boot of the box
touch /etc/cloud/cloud-init.disabled
