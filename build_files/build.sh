#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf5 install -y tmux htop netcat socat radeontop node-exporter podman-compose 
dnf5 swap -y nano-default-editor vim-default-editor

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

# Woodys Additions

## Enable Tailscale Service
systemctl enable tailscaled.service

# Apply GNOME config tweaks
dconf update

# Remove autostart files
rm /etc/skel/.config/autostart/steam.desktop

# Clean package manager cache on ostree stuff
dnf5 clean all
ostree container commit

# Clean temporary files
rm -rf /tmp/*


