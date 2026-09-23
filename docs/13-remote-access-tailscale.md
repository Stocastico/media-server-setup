# Remote access with Tailscale

Jellyfin's own documentation is explicit: it is not designed to be exposed
directly to the internet. **Don't port-forward 8096, 2283 or 8080** on your
router. Instead, Tailscale creates a private, encrypted mesh network (built
on WireGuard) between only your own devices — no open ports, no public
attack surface. The Personal plan is free and enough for a household.

## 1. Set up

1. Create an account at [tailscale.com](https://tailscale.com) (login via
   Google, Microsoft, Apple or GitHub).
2. On the server:
   ```bash
   cd ~/media-server-setup/scripts
   ./07-install-tailscale.sh
   ```
   This installs Tailscale, runs `tailscale up` (prints a login URL — open
   it on your PC/phone and approve the machine), and prints the server's
   Tailscale IP.
3. In the [admin console](https://login.tailscale.com/admin/machines):
   *Machines → mediaserver → ⋯ → Disable key expiry* — otherwise the server
   silently drops off the tailnet after 180 days and everyone loses remote
   access until someone re-authenticates it.
4. **DNS** tab: make sure **MagicDNS** is enabled. The server becomes
   reachable as `mediaserver` (its hostname) from any device on your
   tailnet, without remembering an IP.
5. On your phone and laptop: install the Tailscale app, log in with the
   same account, switch it on. **Test away from home Wi-Fi** (mobile data):
   ```
   http://mediaserver:8096   (Jellyfin)
   http://mediaserver:2283   (Immich)
   ```
6. In the Jellyfin and Immich phone apps, you can either keep the LAN
   address and add `http://mediaserver:8096` / `:2283` as a second
   ("external") server address, or simply use the Tailscale name
   everywhere — it works both on and off the home network.
7. **Family members with their own Tailscale accounts**: *Machines →
   mediaserver → ⋯ → Share* → send them the invite link. They'll only see
   this one server, not any of your other devices.
8. **Optional HTTPS**: in the admin console enable *HTTPS Certificates*
   (DNS tab), then on the server:
   ```bash
   sudo tailscale serve --bg 8096
   ```
   Jellyfin becomes available at `https://mediaserver.<your-tailnet>.ts.net`
   with a valid TLS certificate — useful for clients that refuse plain HTTP.

## Why not a VPN you self-host, or a reverse proxy with a public domain?

Both are viable alternatives, but add real maintenance burden (certificate
renewal, keeping the reverse proxy patched, a public DNS record pointing at
your home IP) for a household server that only a handful of trusted people
need to reach. Tailscale removes all of that: nothing is listening on the
public internet at all, so there's nothing there to attack.

Next: [14-backups-and-maintenance.md](14-backups-and-maintenance.md)
