# Troubleshooting

Service-specific tables also live in their own docs
([08-jellyfin.md](08-jellyfin.md#8-troubleshooting)); this page collects
cross-cutting issues.

## General Docker / stack issues

| Symptom | Likely cause | Fix |
|---|---|---|
| `docker compose up -d` fails with a permission error | Your user isn't in the `docker` group yet, or the group change hasn't taken effect | Run `groups` — if `docker` is missing, re-run `sudo usermod -aG docker $USER` and log out/in (or `newgrp docker`) |
| A container is `Restarting` in a loop | Bad config, missing volume path, or permission mismatch | `docker compose logs <service>`; check the referenced host paths exist and are owned by `PUID:PGID` |
| `docker compose` can't find `.env` values (blank `RENDER_GID`, etc.) | You're running the command from the wrong directory | `.env` is only picked up automatically from the **same directory** as `docker-compose.yml` — `cd /opt/stack` first |
| Disk usage on `/` (the NVMe) keeps climbing | Container logs, unpruned images, or something writing to `/opt/stack` instead of the SSDs | `docker system df`; `docker image prune -f`; confirm `log-driver: local` is set in `/etc/docker/daemon.json` |

## Storage

| Symptom | Likely cause | Fix |
|---|---|---|
| `/srv/media` or `/srv/backup` is empty after a reboot | The SSD didn't mount (unplugged, USB port issue, `TRAN` changed) | `lsblk`; `sudo mount -a`; check `dmesg` for USB errors. The `chattr +i` protection means containers should fail loudly rather than silently write to the NVMe instead — check `docker compose logs` for the affected service |
| `mount -a` fails for a labeled disk | Label doesn't match `/etc/fstab`, or filesystem got corrupted | `sudo blkid` to see actual labels; `sudo fsck /dev/sdX1` (unmount first) |
| SSD feels slower over time | TRIM isn't reaching the drive through the USB bridge | `lsblk --discard` — a `DISC-MAX` of `0` means TRIM isn't passed through; some USB-to-NVMe bridges don't support it, there's no software fix beyond a different enclosure/drive |

## Networking

| Symptom | Likely cause | Fix |
|---|---|---|
| Can't reach `http://192.168.1.10:8096` from your PC | Wrong/changed IP, firewall, or service not running | `docker compose ps`; confirm the DHCP reservation from [04-install-debian.md](04-install-debian.md) is actually in place on the router; `ping 192.168.1.10` |
| Works at home, not from Tailscale | Tailscale not connected on the client, or key expiry kicked the server off the tailnet | Check the Tailscale app is "Connected" on both ends; admin console → confirm *Disable key expiry* is still set for `mediaserver` |
| TV/phone app can't auto-discover the server | UDP discovery (port 7359) blocked by client isolation on some routers/APs, or you're not on the same VLAN/SSID | Type the address manually; if it's a recurring annoyance, check your router/AP for "AP/client isolation" or a guest-network setting that blocks it |

## Backups

| Symptom | Likely cause | Fix |
|---|---|---|
| `/var/log/nightly-backup.log` is missing or stale | Cron job didn't fire | `sudo cat /etc/cron.d/nightly-backup`; `sudo systemctl status cron`; run `sudo /usr/local/bin/nightly-backup.sh` by hand to see the error directly |
| Backup script exits immediately with "media SSD not mounted" | An SSD dropped or wasn't remounted after a reboot | Same fix as the storage section above — the script deliberately refuses to `rsync --delete` against an empty mount point, which would otherwise look like "everything was deleted" and wipe the backup copy |
| restic `init` or `backup` fails with an auth error | Wrong/expired B2 application key | Regenerate the application key in the Backblaze console, update `/root/.restic-env` |

## When in doubt

1. `docker compose logs -f <service>` is almost always the fastest way to
   see what's actually wrong — read the error message before guessing.
2. Check `df -h` for the obvious "disk is full" cause before anything else.
3. Confirm which **user/uid** actually created a problematic file
   (`ls -la`) — permission mismatches between the host user and
   `PUID`/`PGID` in a container are the single most common source of
   "library stays empty" / "can't write" issues in this whole stack.
