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
tmux htop netcat socat radeontop node-exporter podman-compose ksmtuned qemu-kvm libvirt libvirt-daemon-common libvirt-daemon-kvm libvirt-ssh-proxy libvirt-dbus libvirt-daemon-driver-qemu libguestfs-tools \
cockpit{-system,-machines,-ostree,-podman,-selinux,-networkmanager,-storaged,-composer} \
@virtualization

## node-exporter is installed but deliberately NOT enabled (Woody's call) — a
## laptop does not need to be scraped; leaving it off avoids a steady idle CPU poll.

## Remove BazziteDX Docker stuff, because we only use Podman in this house
# (disable the socket first so no dangling enable symlink survives the removal)
systemctl disable docker.socket docker.service 2>/dev/null || true
dnf5 remove -y containerd.io docker-buildx-plugin docker-ce docker-ce-cli docker-compose-plugin
rm -f /etc/systemd/system/sockets.target.wants/docker.socket

## Cockpit re-enabled now that the firewalld config below is in place
systemctl enable cockpit.socket

## SSH server: Bazzite ships sshd disabled by default; I want remote access
systemctl enable sshd

# Cool GNOME Dynamic Wallpapers
# Using updated fork from raul-lezameta because main project seems dead 
# curl -s "https://raw.githubusercontent.com/raul-lezameta/Linux_Dynamic_Wallpapers/main/Easy_Install.sh" | bash

# echo "Downloading needed files started"
# git clone https://github.com/saint-13/Linux_Dynamic_Wallpapers.git  
# cd Linux_Dynamic_Wallpapers
# echo "Files downloaded"

# if [[ -d /usr/share/backgrounds/Dynamic_Wallpapers ]]
# then 
# 	rm -r /usr/share/backgrounds/Dynamic_Wallpapers
# 	echo "Setting up"
#  fi

# echo "Installing wallpapers..."
# cp -r ./Dynamic_Wallpapers/ /usr/share/backgrounds/
# cp ./xml/* /usr/share/gnome-background-properties/
# echo "Dynamic Wallpapers has been installed!"
# cd .. 
# echo "Deleting files used only for the installation process"
# rm -r Linux_Dynamic_Wallpapers
# echo "Wallpapers Installed"

## Enable VM/QEMU/libvirt ( same as ujust script )
## Bazzite seems to ship with libvirt and qemu-kvm installed.
# systemctl enable libvirtd
systemctl enable bazzite-libvirtd-setup.service

# Kernel Samepage Merging (KSM) for VM RAM savings.
# ksmtuned is NOT enabled directly any more: on a laptop that is mostly VM-free
# its scanning threads burn CPU for nothing. fw13-ksm-vm-gate.service starts it
# only while libvirt VMs are actually running (and its timer re-checks every
# 5 min). ksmtuned.conf still tunes the coefficient when it IS running.
systemctl enable fw13-ksm-vm-gate.service fw13-ksm-vm-gate.timer

## Framework 13 AMD power tuning (2026-10)
## Kernel args: amd_pstate=guided, amdgpu.abmlevel=2 (see 10-hardening.toml).
## Wakeup suppression: system_files/usr/lib/udev/rules.d/99-fw13-wakeup.rules.
## Sleep policy: sleep.conf.d sets HibernateDelaySec; the drop-in at
##   usr/lib/systemd/system/systemd-suspend.service.d/10-fw13-suspend-then-hibernate.conf
##   routes plain "suspend" through suspend-then-hibernate so the machine
##   hibernates after HibernateDelaySec instead of draining in a bag.
##   Requires swap >= RAM for the hibernate half; see that file's header.

## IP forwarding for SSH tunnels / VPN: config shipped via
## system_files/usr/lib/sysctl.d/10-woody-custom.conf (sysctl -p is a no-op in a container build)

## Switch o a far superior default editor
dnf5 swap -y nano-default-editor vim-default-editor

## Enable Tailscale Service
systemctl enable tailscaled.service

## Mask the DisplayLink service (it keeps hogging CPU; mask keeps it off even if the unit moves around)
systemctl mask displaylink.service 2>/dev/null || true

# Enable the hardware limit service on boot
systemctl enable fw-hardware-charge-limit.service

## Firewalld: strict default zone + home zone (Steam/Cockpit) + trusted tailnet
systemctl enable firewalld
firewall-offline-cmd --set-default-zone=FedoraServer
## Home zone: stock already has ssh, mdns, dhcpv6-client; add Steam Remote Play + Cockpit.
## Bind home Wi-Fi SSIDs once, on the laptop:  nmcli connection modify "<ssid>" connection.zone home
firewall-offline-cmd --zone=home --add-service=cockpit
firewall-offline-cmd --zone=home --add-service=steam
## Trust the tailnet interface (applies when Tailscale brings it up)
firewall-offline-cmd --zone=trusted --add-interface=tailscale0

## Apply GNOME config tweaks
dconf update

## Remove autostart files
# rm /etc/skel/.config/autostart/steam.desktop

#  Get kernel version and build initramfs
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



