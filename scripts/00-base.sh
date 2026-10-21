#!/bin/sh
set -eux
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get -y upgrade
apt-get -y install \
  build-essential dkms linux-headers-generic \
  git curl wget gnupg ca-certificates \
  net-tools tcpdump iperf3 python3-pip

# Reboot so the (possibly new) kernel is the running one before building guest additions.
# Packer is configured with expect_disconnect = true for this provisioner.
nohup sh -c 'sleep 2; reboot' >/dev/null 2>&1 &
exit 0
