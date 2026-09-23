# Storage setup

Now plug in both USB SSDs, straight into the mini PC's fastest ports
(usually the blue or USB-C ones, rated 10 Gbps) — **not** through a hub.

## 1. Identify the disks

```bash
lsblk -o NAME,SIZE,MODEL,TRAN,FSTYPE,MOUNTPOINTS
```

Confirm `TRAN` shows `usb` for both, and use the `SIZE`/`MODEL` columns to
tell them apart if they're different drives. Note which device (`/dev/sda`,
`/dev/sdb`, …) will become **media** (the live library) and which becomes
**backup**.

## 2. Partition, format and mount

```bash
cd ~/media-server-setup/scripts
source config.env       # if not already sourced in this shell
./03-prepare-disks.sh /dev/sda /dev/sdb   # media disk first, backup disk second
```

**This erases both disks.** The script refuses to run against anything that
doesn't report `TRAN=usb` (as a guardrail against accidentally targeting the
internal NVMe), shows you the current block devices, and requires typing
`YES` to proceed. It then:

- wipes and GPT-partitions both disks,
- formats them ext4 with labels (`media` / `backup` by default),
- creates `/srv/media` and `/srv/backup`, marks them immutable with
  `chattr +i` (so if a disk ever fails to mount, writes fail loudly instead
  of silently filling the internal NVMe),
- adds them to `/etc/fstab` by label, mounted with `nofail` (a missing disk
  won't block the whole system from booting),
- enables weekly TRIM (`fstrim.timer`).

Reboot once and confirm both mount automatically on their own:

```bash
sudo reboot
# after reconnecting:
df -h /srv/media /srv/backup     # both should show ~1.8 TB available
```

## 3. Folder layout

```bash
./04-create-folders.sh
```

This creates:

```
/srv/media/
├── movies/          Title (Year)/Title (Year).mkv + .es.srt .it.srt .en.srt ...
├── tv/              Show (Year)/Season 01/Show (Year) S01E01.mkv
├── home-videos/      family videos, no metadata lookup
├── photos/           your existing photo archive (read-only for Immich)
├── immich-library/    new phone uploads (written by Immich)
└── downloads/
    ├── incomplete/
    └── complete/
/srv/backup/          nightly copies (see 14-backups-and-maintenance.md)
/opt/stack/            docker-compose.yml + configs for Jellyfin, qBittorrent, Bazarr, etc. (on the NVMe)
/opt/immich/           Immich's own compose stack (on the NVMe)
```

Note **why configs live on the NVMe, not the USB SSDs**: container configs
and databases do lots of small random writes, which portable USB
drives handle worse than an internal NVMe, and you don't want a container
crash-looping because a USB SSD briefly dropped out.

The script also sets ownership of everything to your user's uid:gid
(1000:1000 by default on a fresh Debian install — the script prints `id` at
the end so you can confirm).

## Filename conventions (read before importing anything)

Jellyfin and the `*arr` apps match files to online metadata by folder and
file name — getting this right up front saves a lot of manual re-matching
later.

| Content | Path | Notes |
|---|---|---|
| Movie | `/srv/media/movies/Amarcord (1973)/Amarcord (1973).mkv` | One folder per movie; the year avoids mismatches between films with the same title. |
| Movie subtitles | `Amarcord (1973).es.srt`, `.it.srt`, `.en.srt`, `.eu.srt` | ISO 639-1 language code right before `.srt`. |
| Forced / hearing-impaired / default subtitle | `Amarcord (1973).it.forced.srt`, `.en.sdh.srt`, `.es.default.srt` | These flags are picked up automatically by Jellyfin. |
| TV episode | `/srv/media/tv/Fawlty Towers (1975)/Season 01/Fawlty Towers (1975) S01E01.mkv` | The `SxxEyy` pattern is what actually matters for matching. |
| Home video | `/srv/media/home-videos/2019 Summer holidays/clip01.mp4` | No metadata lookup happens here — any naming is fine. |

If an MKV's audio tracks have no language tag, Jellyfin's per-user audio
language selection can't work for that file. Fix it once with MKVToolNix:

```bash
mkvpropedit file.mkv --edit track:a2 --set language=ita
```

If you have an existing archive of ripped DVDs, home videos or photos on
external drives to bring in, do that now — see
[06b-initial-bulk-import.md](06b-initial-bulk-import.md). If you're
starting from an empty library, skip straight to
[07-docker-and-samba.md](07-docker-and-samba.md).
