# Backups and maintenance

Back up to the second SSD every night, plus a weekly off-site copy of the
photos (the one truly irreplaceable thing on this server), and spend about
15 minutes a month on updates and health checks. Budget 1–2 hours for
initial setup.

## What's backed up, and how

| What | Lives at | Backed up how | Priority |
|---|---|---|---|
| Photos (archive + phone uploads) | `/srv/media/photos`, `/srv/media/immich-library` | Nightly to the backup SSD + weekly off-site | Irreplaceable |
| Immich database | Daily dumps in `/srv/media/immich-library/backups` | Included with the photos backup above | High |
| Service configs | `/opt/stack`, `/opt/immich` (excluding `postgres/`) | Nightly to the backup SSD | High (hours of setup to redo) |
| Movies and series | `/srv/media/movies`, `/srv/media/tv` | Nightly to the backup SSD | Medium (re-rippable/re-downloadable, but slow) |
| Downloads (in progress) | `/srv/media/downloads` | Not backed up | Low |

## 1. Nightly local backup to the second SSD

```bash
cd ~/media-server-setup/scripts
./setup-nightly-backup-cron.sh
```

This installs `nightly-backup.sh` to `/usr/local/bin/`, runs it once by
hand (the first run copies everything and can take a while — subsequent
runs are incremental via `rsync`), and schedules it for **03:30 every
night** via `/etc/cron.d/nightly-backup`.

What it does, each run:

1. `rsync`s `/srv/media/` to `/srv/backup/media/` (excluding
   `downloads/`). Anything deleted or overwritten on the live copy is kept
   for **30 days** under `/srv/backup/deleted/<date>/` instead of vanishing
   immediately — this is what saves you from an accidental `rm -rf` or a
   bad rename, not a second true copy of everything.
2. Stops Jellyfin briefly, `rsync`s `/opt/stack/` to
   `/srv/backup/opt-stack/`, restarts Jellyfin. The brief stop makes sure
   its SQLite database is copied in a consistent state rather than
   mid-write.
3. `rsync`s `/opt/immich/` to `/srv/backup/opt-immich/`, **excluding**
   `postgres/` — Immich's own daily SQL dump (backed up as part of step 1,
   since it lives under `/srv/media/immich-library/backups`) is what
   actually needs to survive; copying the live Postgres data directory
   byte-for-byte while it's running would just capture an inconsistent
   snapshot.
4. Prunes `deleted/` copies older than 30 days.

Because both SSDs are 2 TB, **keep the live SSD below ~80% full** so the
`deleted/` copies still have room to fit.

Check it's actually running every night:

```bash
tail -n 20 /var/log/nightly-backup.log     # every entry should end with "done"
```

## 2. Off-site copy of the photos (restic)

Both SSDs sit physically next to each other, so a fire, theft, or power
surge takes out both at once. Photos are the one thing worth protecting
against that too. Two options:

- **A third disk**, kept at a relative's house or at work, refreshed
  monthly:
  ```bash
  rsync -a /srv/media/photos /srv/media/immich-library /media/offsite/
  ```
- **Encrypted cloud backup with restic**, to Backblaze B2 or any
  S3-compatible storage — a few hundred GB of photos typically costs a few
  euros/dollars a month; check current pricing before committing.

### Setting up restic → Backblaze B2

1. Create a B2 bucket and an **application key** (not your master account
   key) in the Backblaze web console.
2. ```bash
   sudo cp ~/media-server-setup/scripts/restic-env.example /root/.restic-env
   sudo nano /root/.restic-env    # fill in B2_ACCOUNT_ID, B2_ACCOUNT_KEY, RESTIC_REPOSITORY, RESTIC_PASSWORD
   sudo chmod 600 /root/.restic-env
   ```
   **`RESTIC_PASSWORD`** should be a long random string
   (`openssl rand -base64 32`), stored in your password manager. Without
   it, the backup is unreadable — including by you.
3. ```bash
   cd ~/media-server-setup/scripts
   ./offsite-restic-backup.sh init
   ./offsite-restic-backup.sh install-cron    # schedules Sunday 05:00, keeps 7 daily / 8 weekly / 12 monthly snapshots
   ```

### Test the restore — now, and every few months

A backup you've never restored is a guess, not a backup:

```bash
./offsite-restic-backup.sh test-restore
# verify the files look right, then:
sudo rm -rf /tmp/restore-test
```

## 3. Monthly maintenance (~15 minutes)

```bash
cd ~/media-server-setup/scripts
./monthly-maintenance.sh
```

Walks through, interactively:

1. **OS updates**: `apt update` + `full-upgrade`, reboots flagged if a
   kernel update was installed.
2. **Container updates**: `docker compose pull && up -d` for both stacks,
   then `docker image prune -f`. Read the Immich release notes before
   upgrading it — major version bumps can include breaking migrations.
3. **Free space**: `df -h` on `/srv/media`, `/srv/backup`, `/` — act before
   any of them hits 80%.
4. **Backup log**: last 20 lines of `/var/log/nightly-backup.log`.
5. **SSD health**: `smartctl` — watch *Percentage Used* and *Available
   Spare*. Many portable SSDs report as NVMe internally even over USB; if
   `-d sat` fails, try `-d sntasmedia`, `-d sntrealtek` or `-d sntjmicron`.
6. Reminder to check *Dashboard → Scheduled Tasks* in Jellyfin for errors.

## Optional extras

- **Uptime Kuma** (alerts on your phone when a service stops): already
  defined under the `monitoring` profile in
  `compose/stack/docker-compose.yml`.
  ```bash
  cd /opt/stack
  docker compose --profile monitoring up -d uptime-kuma
  ```
  Then open `http://192.168.1.10:3001`, create the admin account, and add
  HTTP monitors for `:8096` (Jellyfin), `:2283` (Immich) and `:8080`
  (qBittorrent).
- **UPS integration**: if your UPS has a USB data port, `sudo apt install
  nut` and follow the [Network UPS Tools](https://networkupstools.org/)
  documentation so the server shuts down cleanly on an extended power cut,
  instead of a hard power loss potentially corrupting a database.

Next: [15-troubleshooting.md](15-troubleshooting.md)
