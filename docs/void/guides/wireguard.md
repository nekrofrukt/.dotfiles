# Mullvad VPN via WireGuard on Void Linux

## Prerequisites

- Void Linux with kernel 5.6+ (WireGuard is built into the kernel, no DKMS needed).
- A [Mullvad](https://mullvad.net) account.

## Setup

### 1. Install wireguard-tools

```
sudo xbps-install wireguard-tools
```

This provides `wg`, `wg-quick`, and Void's runit service template at `/etc/sv/wireguard`.

### 2. Generate a WireGuard config on Mullvad

1. Go to [mullvad.net/account/wireguard-config](https://mullvad.net/account/wireguard-config) and log in.
2. Click **Generate key** to create a WireGuard key pair. (Generate a separate key for each device you use.)
3. **Immediately** select a server location — you can't come back to a key without one.
4. (Optional) Enable DNS content blockers, kill switch, or multihop.
5. Click **Download file** and save the `.conf` file.

### 3. Install the config

Copy the downloaded config into place and lock down permissions (the file contains your private key):

```
sudo cp se-sto-wg-001.conf /etc/wireguard/
sudo chown root:root /etc/wireguard/se-sto-wg-001.conf
sudo chmod 600 /etc/wireguard/se-sto-wg-001.conf
```

The interface name is derived from the filename without the `.conf` extension. In this
example the interface becomes `se-sto-wg-001`.

If `wg-quick` fails with a "signature mismatch" error, run `sudo resolvconf -u` first
(dhcpcd sometimes writes `/etc/resolv.conf` directly, bypassing openresolv). Re-run this
if the mismatch reappears after a DHCP lease renewal.

Now bring the tunnel up:

```
sudo wg-quick up se-sto-wg-001
```

Verify it works:

```
curl https://am.i.mullvad.net/connected
```

The config sets:
- **Full tunnel** (all IPv4 + IPv6 traffic routed through Mullvad).
- **DNS**: `10.64.0.1` (Mullvad's ad/tracker-blocking DNS resolver).
- **Endpoint**: Mullvad server IP and port.

## How the tunnel works

WireGuard lives in the kernel. `wg-quick up` creates the interface, applies keys/routes/DNS,
then nothing needs to stay running. Traffic is routed through the tunnel via policy routing
(fwmark + routing table 51820), so `ip route` still shows your LAN default route — the real
test is the egress IP.

## Usage — manual (no autostart)

WireGuard needs no service to run once up. Just use `wg-quick`:

```
sudo wg-quick up se-sto-wg-001      # VPN on
sudo wg-quick down se-sto-wg-001    # VPN off
```

## Usage — with autostart (runit, optional)

If you want the VPN to connect automatically on boot, symlink the runit service:

```
sudo ln -s /etc/sv/wireguard /var/service/    # enable (auto-connect on reboot)
sudo rm /var/service/wireguard                # disable (no VPN on reboot)
```

Once enabled:

```
sudo sv status wireguard     # check status (run: wireguard: (pid N) ...)
sudo sv stop wireguard       # VPN off (tunnel down, traffic goes direct via LAN)
sudo sv start wireguard      # VPN on
```

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
