# Woody's Custom uBlue 

This project is based on the [Universal Blue image template](https://github.com/ublue-os/image-template). If you want to try do something similiar, I suggest starting with the fanstastic tooling that the Universal Blue project have created.  

This is my custom [bootc](https://github.com/bootc-dev/bootc) image image based on Bazzite (`ghcr.io/ublue-os/bazzite-gnome:stable`) from the Universal Blue Project.

My intention is to automate and codify my immutable Linux desktop build as much as possible. This git repo is for me to hack away and get more comfortable with container-focused development, cloud-native tools and CI/CD.

Heavily inspired by [Amy OS](https://github.com/astrovm/amyos).

More to come!

## Changes  (on top of `bazzite-gnome`)

* Added DNF packages:
    * tmux
    * htop
    * netcat
    * socat
    * radeontop
    * node-exporter
* Swapped `nano` default to a `vim`
* Enabled `tailscaled.service`

## ToDo/Goals/Wishlist

- [ ] Configure `gnome-remote-desktop` (GRD) out of the box.
- [ ] KVM/libvirt and Cockpit Machines out of the box.
- [ ] Install Flatpaks to userspace from list.
- [ ] Install Brew packages to userspace from list.
- [ ] Install GNOME extensions from list.
- [ ] Change `gsettings` defaults:
    - [X] No compaitbility check for GNOME extensions (YOLO)
- [ ] Cool Wallpapers pre-loaded.
- [ ] Set up Nix Package Manager.
- [X] MAC address Randomization on WiFi Scanning
- [ ] Kernel Same-page Merging (KSM) 
- [ ] Allow TCP/IP forwarding for SSH tunnel foo (`net.ipv4.ip_forward = 1`)
- [ ] Configure Firewalld zone for Tailscale
- [ ] Cool Plymouth Boot + Dracut



