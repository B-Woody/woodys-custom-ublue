#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

# Woodys Additions

## Install extra DNF Packages
dnf5 install -y \
tmux htop netcat socat radeontop node-exporter podman-compose \
cockpit{-system,-machines,-ostree,-podman,-selinux,-networkmanager,-storaged}

## Cockpit socket/service intentionally disabled to reduce attack surface until I setup better firewalld config
# systemctl enable --now cockpit.socket

## Enable VM/QEMU/libvirt ( same as ujust script )
systemctl enable libvirtd
rpm-ostree kargs --append-if-missing="kvm.ignore_msrs=1" --append-if-missing="kvm.report_ignored_msrs=0"
mkdir -p /var/lib/swtpm-localca
restorecon -rv /var/lib/libvirt
restorecon -rv /var/log/libvirt
### Give qemu access to read ISO files from $HOME
setfacl -m u:qemu:rx $HOME
systemctl enable bazzite-libvirtd-setup.service
### Still need to figure out how to: usermod -aG libvirt $USER in Containerfile properly

## Switch o a far superior default editor
dnf5 swap -y nano-default-editor vim-default-editor

## Enable Tailscale Service
systemctl enable tailscaled.service

## Apply GNOME config tweaks
dconf update

## Remove autostart files
rm /etc/skel/.config/autostart/steam.desktop

## Clean package manager cache on ostree stuff
dnf5 clean all
ostree container commit

# Clean temporary files
rm -rf /tmp/*


