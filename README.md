# Home Media Server

Everything needed to build a private home media server: streaming (Jellyfin),
photo backup (Immich), and downloads (qBittorrent), running as Docker
containers on a small Intel mini PC. Free/open-source software throughout,
no cloud subscription required, remote access via Tailscale instead of
exposing anything to the public internet.

Built from a hardware/software research doc, expanded here into a full,
step-by-step tutorial plus the scripts and compose files needed to actually
do every step — from buying the hardware to a working, backed-up server.

## Start here

**[docs/00-overview.md](docs/00-overview.md)** — key decisions, architecture,
and the full reading order for the rest of the docs.

## Repo layout

```
docs/       the tutorial itself, one file per phase, meant to be read in order
scripts/    shell scripts that automate the repetitive/error-prone steps
compose/    docker-compose.yml files for the two stacks (Jellyfin/*arr/qBittorrent, Immich)
```

## What you end up with

- **Jellyfin** for movies/TV, with Intel Quick Sync hardware transcoding,
  per-user audio/subtitle language preferences, and third-party apps on
  every TV platform.
- **Immich** for photos: a Google Photos-like timeline, face grouping,
  smart search, and automatic phone backup.
- **qBittorrent** for downloads, feeding straight into the library.
- Optional **Bazarr + Radarr + Sonarr** for fully automatic subtitle
  fetching, and **Uptime Kuma** for monitoring.
- **Nightly local backups** to a second SSD (with a 30-day undelete window),
  plus a weekly **encrypted off-site backup** of the photo library.
- **Tailscale** for secure remote access, no port-forwarding.

## Estimated cost and time

€620–820 for the recommended build (mini PC + 2× 2 TB SSD), roughly
10–15 hands-on hours across two weekends. Full breakdown in
[docs/01-shopping-list-and-costs.md](docs/01-shopping-list-and-costs.md).
