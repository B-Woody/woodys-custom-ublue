# Woody's Custom uBlue 🛹🐧💻

**Custom bootc image for my Framework Laptop 13 (AMD Ryzen AI 9 HX 370) — the daily driver's OS.** Based on Bazzite DX (`ghcr.io/ublue-os/bazzite-dx:stable`, KDE Plasma).

![](system_files/usr/share/plymouth/themes/spinner/watermark.png)

![Build Woodys Custom uBlue](https://github.com/B-Woody/woodys-custom-ublue/actions/workflows/build.yml/badge.svg)

This project is based on the [Universal Blue image template](https://github.com/ublue-os/image-template). If you want to try do something similiar, I suggest starting with the fanstastic tooling that the Universal Blue project have created.  

This is my custom [bootc](https://github.com/bootc-dev/bootc) image image based on Bazzite (`ghcr.io/ublue-os/bazzite-dx:stable`) from the Universal Blue Project.

My intention is to automate and codify my immutable Linux desktop build as much as possible. This git repo is for me to hack away and get more comfortable with container-focused development, cloud-native tools and CI/CD.

Heavily inspired by [Amy OS](https://github.com/astrovm/amyos).

Work in progress! Rebased on my main system — see changes below.

## Changes (on top of `bazzite-dx`)

* Changed Fedora/Bazzite logo to Skateboard in Plymouth boot theme
* Added some DNF packages:
    * tmux / htop / netcat / socat / radeontop
    * podman-compose
    * node-exporter (installed; not enabled yet)
    * `cockpit{-system,-machines,-ostree,-podman,-selinux,-networkmanager,-storaged,-composer}`
    * @virtualization (qemu-kvm / libvirt stack)
    * ksmtuned
* Kernel hardening
    * via sysctl config from the [SecureBlue](https://github.com/secureblue/secureblue) project
    * via kargs — pruned to the AMD-relevant set (Intel-only args and pure-cost items like `pti=on` dropped; see `system_files/usr/lib/bootc/kargs.d/10-hardening.toml`)
* Network:
    * MAC randomisation: per-connection, per-boot generated MACs (`99-woody-mac-randomize.conf`)
    * firewalld: strict `FedoraServer` default zone (SSH + Cockpit only); `home` zone for Steam Remote Play + Cockpit; `tailscale0` in `trusted`
    * `sshd` and Cockpit enabled at boot
    * `tailscaled.service` enabled
* KVM/libvirt enabled (Bazzite's `bazzite-libvirtd-setup.service`); KSM (`ksmtuned`) for VM RAM savings, thresholds tuned in `/etc/ksmtuned.conf`
* Enabled TCP/IP forwarding (`net.ipv4.ip_forward = 1`)
* Framework battery charge limit (80%) applied at boot
* Swapped `nano` default to `vim`
* Disabled version compatibility check for GNOME extensions (in case I change back from KDE)

## Network zones (firewalld)

- **Default zone `FedoraServer`** — SSH + Cockpit reachable on any network; everything else closed.
- **Home networks** — put each home SSID in the `home` zone once (per SSID) to enable Steam Remote Play + Cockpit there:

  ```bash
  nmcli connection modify "<home-ssid>" connection.zone home
  ```

  (takes effect on the next activation of that connection)

- **Tailscale** — `tailscale0` is in the `trusted` zone; full access from the tailnet.

Check current state with `firewall-cmd --get-active-zones` and `firewall-cmd --list-all-zones`.

## KSM (VM memory savings)

`ksmtuned` manages KSM dynamically — it engages when memory gets tight (e.g. while VMs run) and pauses when the system is idle. `/etc/ksmtuned.conf` is tuned to engage earlier than stock. Check with:

```bash
systemctl status ksmtuned ksm
cat /sys/kernel/mm/ksm/run /sys/kernel/mm/ksm/pages_shared
```

## Rebase & roll back

```bash
sudo bootc switch ghcr.io/b-woody/woodys-custom-ublue:latest   # rebase to the latest image
sudo bootc rollback                                            # back to the previous deployment
```

## ToDo/Goals/Wishlist

- [X] Rebase to Bazzite DX with KDE
- [X] Hardening
    - [X] Kernel hardening via sysctl
    - [X] Kernel hardening via kargs
    - [X] MAC address randomization (per-connection, per-boot)
- [X] KVM/libvirt
- [X] Cockpit and Cockpit machines etc. out of the box.
- [ ] Install Flatpaks to userspace from list.
    - [X] Add list to git repo
    - [ ] Automate installation (custom ujust)
- [ ] Install Brew packages to userspace from list.
    - [X] Add list to git repo
    - [ ] Automate installation (custom ujust)
- [ ] Install GNOME extensions from list.
    - [ ] Add list to git repo
    - [ ] Automate installation (custom ujust)
- [X] Change `gsettings` defaults:
    - [X] No compatibility check for GNOME extensions (YOLO)
- [X] Cool wallpapers pre-loaded.
- [X] Kernel Same-page Merging (KSM) with ksmtuned
- [X] Allow TCP/IP forwarding for SSH tunnel foo (`net.ipv4.ip_forward = 1`)
- [X] Cool Plymouth Boot + Dracut
- [X] Configure Firewalld zone for Tailscale
- [ ] ~~Configure `gnome-remote-desktop` (GRD) out of the box.~~ No need for now
- [ ] ~~Set up Nix package manager.~~ Not interest in Nix for now
