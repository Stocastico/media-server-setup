# Overview and key decisions

This repo builds a home media server that streams video (Jellyfin), backs up
and organizes family photos (Immich), and downloads legal/public-domain
content (qBittorrent) — all as Docker containers on a single small PC.

## The stack

| Decision | Choice | Why |
|---|---|---|
| Hardware | Intel N150 (or N100) mini PC, 16 GB RAM, NVMe SSD + 2× 2 TB USB SSD | Raspberry Pi 5 has no hardware video encoder and is too slow for this use case (see below). The N-series has Intel Quick Sync for efficient transcoding. |
| Media server | Jellyfin | Free, open source, self-hosted. Plex and Emby now charge for remote streaming. |
| Photos | Immich | Google Photos-like UI: timeline, face grouping, smart search, automatic phone backup. Jellyfin's photo support is basic. |
| Downloads | qBittorrent-nox (web UI) in Docker | Mature, headless, well maintained. |
| Subtitles | Jellyfin OpenSubtitles plugin, optionally Bazarr | Per-language `.srt` files next to each video. |
| Remote access | Tailscale | Never port-forward Jellyfin/Immich to the public internet. |

## Why not a Raspberry Pi

A Pi 5 has no hardware video encoder, so it can only *direct play* files that
already match the client's codec/subtitle support exactly. DVD rips are
typically MPEG-2 video with image-based (VobSub) subtitles: many TV apps
can't direct-play MPEG-2, and image-based subtitles always force a burn-in
transcode. Without hardware encoding, that transcode runs in software and
saturates the Pi's CPU for a single stream. An N150 mini PC does several
such transcodes simultaneously, using well under 10 W, thanks to Intel Quick
Sync Video (QSV).

If you already own a Pi 5 and want to use it anyway: get the 8 GB model with
an NVMe HAT, and re-encode your entire library to H.264 + AAC with `.srt`
subtitles so every client can direct-play. Expect 2–3 simultaneous streams
at most, and no transcoding headroom for the future.

## Architecture

Everything runs as Docker containers on one mini PC, wired to the router by
Ethernet. TVs, phones and laptops are just clients — they never see anything
but Jellyfin/Immich/qBittorrent's web UIs and apps.

```
                    ┌─────────────────────────────────────┐
                    │        mini PC ("mediaserver")       │
                    │                                       │
  Router (Ethernet) │  Debian 13 + Docker                   │
        │           │   ├─ jellyfin        (video/TV)       │
        │           │   ├─ immich          (photos)         │
        │           │   ├─ qbittorrent     (downloads)      │
        │           │   ├─ radarr/sonarr   (optional)       │
        │           │   ├─ bazarr          (optional)       │
        │           │   └─ uptime-kuma     (optional)       │
        │           │                                       │
        │           │  Internal NVMe: OS + container configs │
        │           │  USB SSD #1 (/srv/media): live library │
        │           │  USB SSD #2 (/srv/backup): nightly copy│
        │           └─────────────────────────────────────┘
        │
   ┌────┴─────┐   ┌──────────┐   ┌───────────┐
   │   TVs    │   │  Phones  │   │ Laptops/PC│
   └──────────┘   └──────────┘   └───────────┘
```

Storage sizing: with the second SSD reserved as backup, you effectively get
2 TB shared by movies, series and photos — roughly 250–500 lossless DVD rips
(4–8 GB each) or 1,000–2,000 rips re-encoded to H.265 (1–2 GB each). When it
fills up, add larger disks and repurpose the current SSDs as backup/photo
storage.

## How this repo is organized

```
docs/       step-by-step tutorial, one file per phase — read them in order
scripts/    shell scripts that do the repetitive/error-prone steps for you
compose/    docker-compose.yml files for the two stacks (Jellyfin/*arr/qBittorrent, Immich)
```

Read the docs in numeric order the first time through; after that, each file
stands on its own as a reference. Every script is meant to be read before
you run it — none of them are black boxes, and several are destructive by
design (disk formatting, in particular) with confirmation prompts to match.

Throughout the docs, the server is `192.168.1.10`, the Linux user is
`stefano` and the hostname is `mediaserver` — replace them with your own
values everywhere they appear, including inside the scripts'
`scripts/config.env` (copy it from `scripts/00-config.env.example`).

## Reading order

1. [01-shopping-list-and-costs.md](01-shopping-list-and-costs.md) — what to buy
2. [02-assembly-and-first-boot.md](02-assembly-and-first-boot.md) — unboxing, cabling, BIOS
3. [03-create-installer-usb.md](03-create-installer-usb.md) — Debian ISO → USB stick
4. [04-install-debian.md](04-install-debian.md) — the OS installer, screen by screen
5. [05-first-server-configuration.md](05-first-server-configuration.md) — SSH, drivers, base packages
6. [06-storage-setup.md](06-storage-setup.md) — the two SSDs, folder layout
   - [06b-initial-bulk-import.md](06b-initial-bulk-import.md) — bringing in an existing archive from external drives, if you have one (one-time step)
7. [07-docker-and-samba.md](07-docker-and-samba.md) — container runtime, network share
8. [08-jellyfin.md](08-jellyfin.md) — video server, hardware transcoding, users
9. [09-immich.md](09-immich.md) — photos
10. [10-subtitles.md](10-subtitles.md) — OpenSubtitles plugin and/or Bazarr
11. [11-qbittorrent.md](11-qbittorrent.md) — downloads, legal sources
12. [12-tv-and-device-clients.md](12-tv-and-device-clients.md) — apps for every screen
13. [13-remote-access-tailscale.md](13-remote-access-tailscale.md) — access from outside home
14. [14-backups-and-maintenance.md](14-backups-and-maintenance.md) — nightly + off-site backups, monthly checklist
15. [15-troubleshooting.md](15-troubleshooting.md) — symptom → cause → fix tables

Total hands-on time is roughly 10–15 hours across two weekends, if you're
already comfortable with Linux and Docker; add time if either is new to you.
