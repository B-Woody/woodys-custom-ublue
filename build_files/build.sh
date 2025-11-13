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
tmux htop netcat socat radeontop node-exporter podman-compose ksmtuned \
cockpit{-system,-machines,-ostree,-podman,-selinux,-networkmanager,-storaged} \
@virtualization 

## Cockpit socket/service intentionally disabled to reduce attack surface until I setup better firewalld config
# systemctl enable --now cockpit.socket

# Cool GNOME Dynamic Wallpapers
# Using updated fork from raul-lezameta because main project seems dead 
# curl -s "https://raw.githubusercontent.com/raul-lezameta/Linux_Dynamic_Wallpapers/main/Easy_Install.sh" | bash

echo "Downloading needed files started"
git clone https://github.com/saint-13/Linux_Dynamic_Wallpapers.git  
cd Linux_Dynamic_Wallpapers
echo "Files downloaded"

if [[ -d /usr/share/backgrounds/Dynamic_Wallpapers ]]
then 
	rm -r /usr/share/backgrounds/Dynamic_Wallpapers
	echo "Setting up"
fi

echo "Installing wallpapers..."
cp -r ./Dynamic_Wallpapers/ /usr/share/backgrounds/
cp ./xml/* /usr/share/gnome-background-properties/
echo "Dynamic Wallpapers has been installed!"
cd .. 
echo "Deleting files used only for the installation process"
rm -r Linux_Dynamic_Wallpapers
echo "Wallpapers Installed"

## Enable VM/QEMU/libvirt ( same as ujust script )
## Bazzite seems to ship with libvirt and qemu-kvm installed.
systemctl enable libvirtd
systemctl enable bazzite-libvirtd-setup.service

# Kernel Samepage Merging (KSM) for VM RAM savings
systemctl enable ksmtuned 

# Enable IP forwarding for SSH and VPN foo
echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/10-woody-custom.conf
sysctl -p

## Switch o a far superior default editor
dnf5 swap -y nano-default-editor vim-default-editor

## Enable Tailscale Service
systemctl enable tailscaled.service

## Apply GNOME config tweaks
dconf update

## Remove autostart files
rm /etc/skel/.config/autostart/steam.desktop

# Get kernel version and build initramfs
KERNEL_VERSION="$(dnf5 repoquery --installed --queryformat='%{evr}.%{arch}' kernel)"
/usr/bin/dracut \
  --no-hostonly \
  --kver "$KERNEL_VERSION" \
  --reproducible \
  --zstd \
  -v \
  --add ostree \
  -f "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"

chmod 0600 "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"

## Clean package manager cache on ostree stuff
dnf5 clean all
ostree container commit

# Clean temporary files
rm -rf /tmp/*



