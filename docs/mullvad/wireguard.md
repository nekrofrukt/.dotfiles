# Mullvad VPN via WireGuard on Void Linux

## How it was set up

- **OS**: Void Linux (runit init), kernel with built-in WireGuard support (5.6+).
- **Installed**: `sudo xbps-install wireguard-tools`
  - Provides `wg`, `wg-quick`, and Void's packaged runit service template at `/etc/sv/wireguard`.
- **Config**: generated at mullvad.net (account panel → Downloads → WireGuard configuration).
  - Saved as `/etc/wireguard/se-sto-wg-013.conf` (root-owned, private key inside).
  - Interface name is derived from the filename: `se-sto-wg-013`.
  - Full tunnel (IPv4 + IPv6), DNS `10.64.0.1` (Mullvad DNS), endpoint `185.195.233.67:51820`.
- **resolvconf fix**: `openresolv` was installed but `/etc/resolv.conf` had been written directly by
  dhcpcd, causing a "signature mismatch" that blocked `wg-quick`. Fixed with:
  ```
  sudo resolvconf -u
  ```
  (Re-run this if the mismatch ever reappears after a DHCP lease renewal.)

## How the tunnel works

WireGuard lives in the kernel. `wg-quick up` creates the interface, applies keys/routes/DNS,
then nothing needs to stay running. Traffic is routed through the tunnel via policy routing
(fwmark + routing table 51820), so `ip route` still shows your LAN default route — the real
test is the egress IP.

## Usage — with autostart (runit)

```
sudo sv status wireguard     # check status (run: wireguard: (pid N) ...)
sudo sv stop wireguard       # VPN off (tunnel down, traffic goes direct via LAN)
sudo sv start wireguard      # VPN on
```

Enable/disable autostart at boot:

```
sudo ln -s /etc/sv/wireguard /var/service/    # enable (auto-connect on reboot)
sudo rm /var/service/wireguard                # disable (no VPN on reboot)
```

## Usage — without autostart (manual)

The runit service is optional — WireGuard needs no service to run once up.

```
sudo wg-quick up se-sto-wg-013      # VPN on
sudo wg-quick down se-sto-wg-013    # VPN off
```

(You can also re-enable autostart later with the symlink command above.)

## Verifying

```
sudo wg show                                     # interface + peer + handshake + transfer
curl https://am.i.mullvad.net/connected          # "You are connected ... Your IP is <mullvad-ip>"
cat /etc/resolv.conf                             # 10.64.0.1 while up, 192.168.1.1 when down
```

## Notes

- `wg show` without sudo shows "Operation not permitted" — needs root, that's normal.
- While the tunnel is up, DNS is Mullvad's `10.64.0.1`; on down it's restored to the LAN
  DNS via resolvconf.
- `sv status` also complains "access denied" without sudo — same reason, use sudo.
