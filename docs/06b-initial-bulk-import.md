# Initial bulk import from your existing archive

If you already have DVD rips, home videos or a photo archive on external
hard disks, this is the step to bring them onto the server. It's meant to
happen **once**, up front — after this, the normal way to add things is the
Samba share ([07-docker-and-samba.md](07-docker-and-samba.md)) for
occasional files and qBittorrent
([11-qbittorrent.md](11-qbittorrent.md)) for new downloads.

**Do this locally on the server, not over the network.** Copying a few
hundred GB — or several TB — of video over Wi-Fi/Samba can take a very long
time and is more prone to dropping partway through. Plugging the external
disk directly into the mini PC and copying disk-to-disk over USB is
dramatically faster and more reliable for a one-off transfer this size.

Do this after [06-storage-setup.md](06-storage-setup.md) (the media SSD
must already be partitioned, mounted and have its folder layout), and
before you start adding libraries in Jellyfin — though it isn't strictly
required in that order, since you can always rescan later.

## 1. Connect and mount the external disk

Plug it into a free USB port on the mini PC (not the same bus-powered port
already used by the two permanent SSDs, if you can avoid it — some mini PCs
share bandwidth across ports under heavy simultaneous load).

```bash
lsblk -o NAME,SIZE,MODEL,TRAN,FSTYPE,MOUNTPOINTS
```

If the disk was formatted on Windows or macOS, it's likely NTFS or exFAT —
Debian doesn't read/write those out of the box:

```bash
sudo apt install -y ntfs-3g exfatprogs
sudo mkdir -p /mnt/external
sudo mount /dev/sdX1 /mnt/external      # NTFS and exFAT are both auto-detected by `mount`
```

(Replace `/dev/sdX1` with the actual partition from `lsblk`. If you have
several external disks to get through, mount one at a time — it keeps
`lsblk`/`df` output unambiguous.)

## 2. Check sizes before copying

```bash
du -sh /mnt/external/Movies            # or whatever the folder is called on the disk
df -h /srv/media                        # free space on the destination
```

Make sure the destination has enough room. If it doesn't, you'll need to
import in batches, checking free space between each one.

## 3. Copy

```bash
cd ~/media-server-setup/scripts
source config.env
./import-initial-archive.sh /mnt/external/Movies movies
./import-initial-archive.sh /mnt/external/Series tv
./import-initial-archive.sh /mnt/external/Home-Videos home-videos
./import-initial-archive.sh /mnt/external/Photos photos
```

The script shows the source size and destination free space, asks for
confirmation, then runs an `rsync` copy with progress. It's safe to
`Ctrl+C` and re-run later — already-copied files are recognized and
skipped/resumed rather than re-copied from scratch, so you don't have to
finish a multi-TB import in one sitting.

Add `--verify` as a third argument to also do a full checksum comparison
pass afterward (re-reads every file on both sides — slower, but the surest
way to confirm nothing got corrupted in transit):

```bash
./import-initial-archive.sh /mnt/external/Movies movies --verify
```

## 4. Rename into the expected layout

The importer copies files as-is; it doesn't rename them. Go through the
imported folders and match the naming convention from
[06-storage-setup.md](06-storage-setup.md) (`Title (Year)/Title
(Year).mkv`, `SxxEyy` for episodes, language-coded `.srt` files) — this is
what lets Jellyfin match everything to the right metadata automatically
instead of you fixing mismatches one by one later. Doing it now, before the
first library scan, is much less tedious than doing it after.

## 5. Verify, then back up, before touching the source disks again

This is the step it's easiest to skip and the one most worth not skipping:
right after the copy finishes, the media SSD is the **only** copy of
whatever you just imported — the backup SSD doesn't have it yet.

1. Spot-check a handful of files: play a movie, open a few photos.
2. Run the nightly backup **by hand**, immediately (don't wait for the
   03:30 cron job — see [14-backups-and-maintenance.md](14-backups-and-maintenance.md)
   for setting that up permanently):
   ```bash
   sudo /usr/local/bin/nightly-backup.sh
   tail -n 10 /var/log/nightly-backup.log    # should end with "done"
   ```
   (If you haven't run `scripts/setup-nightly-backup-cron.sh` yet, do that
   first — it installs the script and runs it once for you.)

Only once both of those check out — files play correctly, and a backup run
has completed — is it safe to wipe, repurpose or put away the external
disks. Until then, keep them as they are.

## 6. Photos specifically

Photos copied into `/srv/media/photos` aren't automatically visible in
Immich — that needs one extra step (creating an *External Library* and
pointing it at the folder) covered in
[09-immich.md](09-immich.md#6-import-the-existing-archive-external-library).
Do the copy here first, then follow that section once Immich is running.

Next: [07-docker-and-samba.md](07-docker-and-samba.md)
