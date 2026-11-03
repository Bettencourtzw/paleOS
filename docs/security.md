# Privacy & security

paleOS sets a few things up so you don't have to.

## Private DNS — no leaks

Every DNS lookup is sent **encrypted** (DNS-over-TLS) to [Quad9](https://quad9.net), with DNSSEC.
NetworkManager is told not to hand your router's or ISP's DNS servers to the system, so nothing
can slip around it — including over IPv6. Settings: `/etc/systemd/resolved.conf.d/paleos.conf`
(change `DNS=` to use another provider) and `/etc/NetworkManager/conf.d/paleos.conf`.

Check it yourself: `resolvectl status` should list only Quad9 under *Global* and no DNS servers
under your network links.

Trade-off: hotel/airport Wi-Fi login pages that rely on hijacking DNS won't pop up on their own.
Open `http://neverssl.com` to reach them.

## Firewall

`ufw` blocks everything coming in and allows everything going out. Allow a port with
`sudo ufw allow 22/tcp` (for example), check with `sudo ufw status`.

## Privacy on networks

- Temporary IPv6 addresses (your device isn't trackable by a fixed IPv6 address).
- A different, stable MAC address for each Wi-Fi network.

## Kernel hardening (light)

Kernel addresses and logs are hidden from normal users, and network redirects are ignored.
Nothing here gets in the way of normal apps. See `/etc/sysctl.d/99-paleos.conf`.

## Also

- The root account is locked; you use `sudo`.
- 10 wrong passwords lock the account for 10 minutes (`/etc/security/faillock.conf`).
- Disk encryption (LUKS2) is offered by the ISO installer.
