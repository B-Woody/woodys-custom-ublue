# Woody's Custom uBlue 🛹🐧💻

**Custom bootc image for my Framework Laptop 13 (AMD Ryzen AI 9 HX 370) — the daily driver's OS.** Based on Bazzite DX (`ghcr.io/ublue-os/bazzite-dx:stable`, KDE Plasma).

![](system_files/usr/share/plymouth/themes/spinner/watermark.png)

![Build Woodys Custom uBlue](https://github.com/B-Woody/woodys-custom-ublue/actions/workflows/build.yml/badge.svg)

Built on the [Universal Blue image template](https://github.com/ublue-os/image-template) tooling; heavily inspired by [Amy OS](https://github.com/astrovm/amyos). Work in progress — I rebase my main system on it to get comfortable with container-focused development and CI/CD.

## Changes (on top of `bazzite-dx`)

* Skateboard Plymouth boot theme
* Extra DNF packages: `tmux` `htop` `netcat` `socat` `radeontop`, `podman-compose`, `cockpit{-system,-machines,-ostree,-podman,-selinux,-networkmanager,-storaged,-composer}`, `@virtualization` (qemu-kvm/libvirt), `ksmtuned`; `node-exporter` installed but deliberately not enabled (a laptop doesn't need scraping)
* Kernel hardening: SecureBlue-derived sysctls + pruned kargs (`system_files/usr/lib/bootc/kargs.d/10-hardening.toml`)
* **Framework 13 power tuning** (2026-10): `amd_pstate=guided`, `amdgpu.abmlevel=2`, lid/keyboard wakeup suppression, KSM gated to running VMs, hibernation disabled — see below
* Framework 13 internal microphone fix: blacklist the AMD ACP audio modules (`system_files/usr/lib/modprobe.d/fw13-acp-mic-blacklist.conf`) to stop the phantom `acp-pdm-mach` card the BIOS wrongly advertises; see [Framework issue #11](https://github.com/NorrisWu0/dotfile/issues/11) / [FrameworkComputer/SoftwareFirmwareIssueTracker#166](https://github.com/FrameworkComputer/SoftwareFirmwareIssueTracker/issues/166)
* Network: per-connection MAC randomisation; firewalld with a strict `FedoraServer` default zone (SSH + Cockpit), a `home` zone for Steam Remote Play + Cockpit (bind SSIDs: `nmcli connection modify "<ssid>" connection.zone home`), and `tailscale0` trusted; `sshd`, Cockpit and `tailscaled` enabled
* KVM/libvirt enabled; TCP/IP forwarding on
* Framework battery charge limit (80%) applied at boot
* `vim` as default editor; GNOME extension compatibility check disabled

## Framework 13 power tuning (2026-10)

Battery pass for the AMD Ryzen AI 300 mainboard. Short version — details live in the file headers (`10-hardening.toml`, `99-fw13-wakeup.rules`, the KSM gate units) and in my wiki:

- **Kernel args:** `amd_pstate=guided` gives the power-profile EPP hints more influence than the performance-biased default; `amdgpu.abmlevel=2` trims panel backlight on dark content.
- **Wakeup suppression:** the lid switch and internal keyboard no longer wake it (resume via power button or touchpad) — stops the EC's spurious bag-wakeups.
- **KSM** only runs while a libvirt VM is up (`fw13-ksm-vm-gate.service` + `.timer`).
- **Hibernation is deliberately disabled** (`sleep.conf.d/10-no-hibernation.conf`): it weakens the Secure Boot anti-tamper posture (unsigned resume image) and could never work here anyway (zram-only swap, no `resume=`). Plain suspend is unaffected.

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
- [X] Framework 13 power tuning (2026-10): amd_pstate=guided, abmlevel, wakeup suppression, KSM gating, hibernation disabled
- [X] Allow TCP/IP forwarding for SSH tunnel foo (`net.ipv4.ip_forward = 1`)
- [X] Cool Plymouth Boot + Dracut
- [X] Configure Firewalld zone for Tailscale
- [ ] ~~Configure `gnome-remote-desktop` (GRD) out of the box.~~ No need for now
- [ ] ~~Set up Nix package manager.~~ Not interest in Nix for now
