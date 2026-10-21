#!/bin/sh
set -eux

ISO=/home/vagrant/VBoxGuestAdditions.iso
mkdir -p /mnt/vbga
mount -o loop,ro "$ISO" /mnt/vbga
# The installer exits non-zero when no X11 is present; that's harmless on a server.
sh /mnt/vbga/VBoxLinuxAdditions.run --nox11 || true
umount /mnt/vbga
rmdir /mnt/vbga
rm -f "$ISO"

# Fail the build if the guest additions did not install
modinfo vboxguest >/dev/null
command -v VBoxControl >/dev/null
