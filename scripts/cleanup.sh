#!/usr/bin/env bash
set -euo pipefail

systemctl stop bmv2.service >/dev/null 2>&1 || true

# Remove source/build trees. The installed binaries/libraries stay in /usr/local.
rm -rf /usr/local/src/PI /usr/local/src/behavioral-model

# Remove development packages that were needed only to build BMv2.
apt-get purge -y \
  autoconf \
  automake \
  bison \
  build-essential \
  cmake \
  flex \
  git \
  libboost-dev \
  libboost-filesystem-dev \
  libboost-program-options-dev \
  libboost-system-dev \
  libboost-thread-dev \
  libevent-dev \
  libgmp-dev \
  libgrpc++-dev \
  libgrpc-dev \
  libpcap-dev \
  libprotobuf-dev \
  libreadline-dev \
  libssl-dev \
  libtool \
  libtool-bin \
  pkg-config \
  protobuf-compiler \
  protobuf-compiler-grpc \
  >/dev/null 2>&1 || true

apt-get autoremove -y --purge >/dev/null 2>&1 || true
apt-get clean

rm -rf /var/lib/apt/lists/*
rm -rf /tmp/* /var/tmp/*

# Make cloned VMs obtain new machine identity / SSH host keys.
cloud-init clean --logs --seed >/dev/null 2>&1 || true
rm -f /etc/ssh/ssh_host_*
truncate -s 0 /etc/machine-id

# Keep build logs from consuming template storage.
journalctl --rotate >/dev/null 2>&1 || true
journalctl --vacuum-time=1s >/dev/null 2>&1 || true

sync
