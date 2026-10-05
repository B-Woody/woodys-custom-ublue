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
    * node-exporter (installed; not enabled — a laptop doesn't need scraping)
    * `cockpit{-system,-machines,-ostree,-podman,-selinux,-networkmanager,-storaged,-composer}`
    * @virtualization (qemu-kvm / libvirt stack)
    * ksmtuned
* Kernel hardening
    * via sysctl config from the [SecureBlue](https://github.com/secureblue/secureblue) project
    * via kargs — pruned to the AMD-relevant set (Intel-only args and pure-cost items like `pti=on` dropped; see `system_files/usr/lib/bootc/kargs.d/10-hardening.toml`)
* **Framework 13 power/battery tuning** (2026-10) — see the section below
* Network:
    * MAC randomisation: per-connection, per-boot generated MACs (`99-woody-mac-randomize.conf`)
    * firewalld: strict `FedoraServer` default zone (SSH + Cockpit only); `home` zone for Steam Remote Play + Cockpit; `tailscale0` in `trusted`
    * `sshd` and Cockpit enabled at boot
    * `tailscaled.service` enabled
* KVM/libvirt enabled (Bazzite's `bazzite-libvirtd-setup.service`); KSM (`ksmtuned`) is gated to only run while a VM is up (see below)
* Enabled TCP/IP forwarding (`net.ipv4.ip_forward = 1`)
* Framework battery charge limit (80%) applied at boot
* Framework 13 internal microphone fix — blacklist the AMD ACP audio modules (`system_files/usr/lib/modprobe.d/fw13-acp-mic-blacklist.conf`) to stop the phantom `acp-pdm-mach` card the BIOS wrongly advertises; see [Framework issue #11](https://github.com/NorrisWu0/dotfile/issues/11) / [FrameworkComputer/SoftwareFirmwareIssueTracker#166](https://github.com/FrameworkComputer/SoftwareFirmwareIssueTracker/issues/166)
* Swapped `nano` default to `vim`
* Disabled version compatibility check for GNOME extensions (in case I change back from KDE)

## Framework 13 power tuning (2026-10)

Battery-life changes for the AMD Ryzen AI 300 mainboard. Each is revertible
independently; the honest summary is that the two kernel args are the headline
wins and the rest are housekeeping.

### Kernel arguments (`10-hardening.toml`)

- **Added `amd_pstate=guided`** — lets the AMD CPPC governor honour the EPP hints
  that power-profiles-daemon pushes (so KDE's power-saver mode actually does
  something) while keeping kernel-side load awareness. This is the single biggest
  idle-power knob on Strix/Krackan Point. `active` (kernel default) is
  performance-biased; `passive` is the legacy ondemand-style mode and is known to
  misbehave on some AMD laptops — `guided` is the safe battery-leaning choice.
- **Added `amdgpu.abmlevel=2`** — Adaptive Backlight Management: a panel-side
  algorithm that trims backlight power on dark content (roughly 0.3–1 W). Level 2
  is the usual "no visible change" setting; 3–4 are visibly aggressive. Set 0 to
  disable.
- **Dropped `init_on_free=1`** — kept `init_on_alloc=1`. Zeroing on every free is
  the expensive half of the pair (constant memory traffic); `init_on_alloc` still
  blocks the main use-after-free info-leak class.
- **Dropped `iommu.strict=1`** — the kernel's default lazy DMA flush is retained.
  `iommu=force iommu.passthrough=0` remain, so the IOMMU is still on and enabled.

### Power-related sysctls (`55-hardening.conf`)

- **`log_martians` 1 → 0** — every logged martian packet writes a journal line and
  keeps the CPU/disk awake; `rp_filter` still drops the packets. Re-enable while
  debugging spoofing.

### Sleep (`sleep.conf.d` + `systemd-suspend.service.d`)

The FW13 AMD is notorious for draining while suspended. Plain `suspend` (lid
close, menu) is now routed through **suspend-then-hibernate**: it still enters RAM
suspend for fast resume, but after `HibernateDelaySec=180min` it wakes on an RTC
alarm, writes the image to swap and powers off. `HibernateOnACPower=no` keeps the
fast-resume behaviour while plugged in.

- **Requires swap ≥ RAM** for the hibernate half (`swapon --show`).
- The hibernate/resume half is **incompatible with Secure Boot** + kernel
  signature enforcement; on failure it falls back to plain suspend.
- Disable by removing the drop-in at
  `system_files/usr/lib/systemd/system/systemd-suspend.service.d/`.

### Wakeup suppression (`99-fw13-wakeup.rules`)

udev rule disabling wakeup for the ACPI lid switch (`PNP0C0D`) and the AT keyboard
controller. On this EC, closing the lid emits two spurious wake events (one from
the lid switch, one from a synthetic keyboard event) and plugging in AC emits a
keyboard one — so the laptop could wake itself to screen-on right after suspending
and sit awake in a bag. Trade-off: the lid and keyboard no longer wake it — resume
with the power button or touchpad.

### KSM gating (`fw13-ksm-vm-gate.service` + `.timer`)

`ksmtuned` is no longer enabled directly. `fw13-ksm-vm-gate.service` starts it only
when a `qemu-system-*` task is present (a running libvirt VM) and stops it
otherwise; the paired timer re-checks every 5 minutes. `/etc/ksmtuned.conf` still
tunes the coefficient when KSM is active. On a mostly VM-free laptop this removes
KSM's continuous scanning cost.

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

`ksmtuned` manages KSM dynamically. Since 2026-10 it is **not enabled directly** —
`fw13-ksm-vm-gate.service` starts it only while a `qemu-system-*` (libvirt VM) task
is running, and stops it otherwise (the paired `.timer` re-checks every 5 min). So
KSM engages while you run VMs and costs nothing when the laptop is VM-free.
`/etc/ksmtuned.conf` is tuned to engage earlier than stock when it does run. Check with:

```bash
systemctl status ksmtuned ksm fw13-ksm-vm-gate.service
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
- [X] Framework 13 power tuning (amd_pstate=guided, abmlevel, suspend-then-hibernate, wakeup suppression, KSM gating) — 2026-10
- [X] Allow TCP/IP forwarding for SSH tunnel foo (`net.ipv4.ip_forward = 1`)
- [X] Cool Plymouth Boot + Dracut
- [X] Configure Firewalld zone for Tailscale
- [ ] ~~Configure `gnome-remote-desktop` (GRD) out of the box.~~ No need for now
- [ ] ~~Set up Nix package manager.~~ Not interest in Nix for now
