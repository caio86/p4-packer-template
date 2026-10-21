#!/bin/sh
set -eux
export DEBIAN_FRONTEND=noninteractive

apt-get -y autoremove --purge
apt-get -y clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
rm -f /var/log/*.log
journalctl --rotate && journalctl --vacuum-time=1s || true

# machine-id is regenerated on first boot
truncate -s 0 /etc/machine-id

# Zero free space so the exported box compresses well
dd if=/dev/zero of=/EMPTY bs=1M || true
rm -f /EMPTY
sync

history -c || true
