#!/bin/sh
# Installs p4c + bmv2 from the official p4lang OBS repository (prebuilt .deb packages).
set -eux
export DEBIAN_FRONTEND=noninteractive

. /etc/os-release   # VERSION_ID=22.04
REPO="https://download.opensuse.org/repositories/home:/p4lang/xUbuntu_${VERSION_ID}"

echo "deb ${REPO}/ /" > /etc/apt/sources.list.d/home:p4lang.list
curl -fsSL "${REPO}/Release.key" | gpg --dearmor > /etc/apt/trusted.gpg.d/home_p4lang.gpg

apt-get update
apt-get -y install p4lang-p4c p4lang-bmv2

# Handy companions for P4 / in-network experiments
apt-get -y install mininet python3-scapy python3-thrift

# Make sure /usr/lib shared libs from the packages are found
ldconfig
