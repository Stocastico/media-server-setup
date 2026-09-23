# Jellyfin: install and configure

Run Jellyfin in Docker with the Intel iGPU passed through, create the
libraries, turn on Quick Sync hardware transcoding, then give every family
member their own user with their own audio/subtitle language preferences.
Budget 2–3 hours.

Make sure you've finished [07-docker-and-samba.md](07-docker-and-samba.md)
first — `/opt/stack/docker-compose.yml` and `/opt/stack/.env` must already
exist.

## 1. Start the container

```bash
cd /opt/stack
docker compose up -d jellyfin
docker compose ps                     # STATUS should become "Up" / "healthy"
docker compose logs -f jellyfin       # wait for "Startup complete", then Ctrl+C
```

## 2. First-run setup wizard

Open `http://192.168.1.10:8096` in a browser on your PC.

1. **Language**: display language for the admin UI.
2. **User**: create the admin account (e.g. `admin`) with a strong password.
   Keep this one for administration — family members get their own users
   later (step 6).
3. **Media libraries**: click *Add Media Library* for each row below. For
   each: set *Preferred download language* and *Country*, leave
   TheMovieDb first in the metadata/image fetcher lists, and **untick**
   *Save artwork into media folders* (the `/media` mount is read-only, so
   this would just fail).

   | Content type | Display name | Folder |
   |---|---|---|
   | Movies | Movies | `/media/movies` |
   | Shows | Series | `/media/tv` |
   | Home Videos and Photos | Home videos | `/media/home-videos` |

   Also tick **Enable real-time monitoring** so newly added files appear
   without a manual scan.
4. **Preferred metadata language**: your household default.
5. **Remote access**: tick *Allow remote connections to this server*
   (needed later for Tailscale) — **untick** *Enable automatic port
   mapping* (this would try UPnP to punch a hole in your router; we
   deliberately never expose Jellyfin directly to the internet — see
   [13-remote-access-tailscale.md](13-remote-access-tailscale.md)).
6. Finish, then log in as `admin`. The first library scan starts in the
   background (*Dashboard → Scheduled Tasks* shows progress).

Metadata language is set **per library, not per user**. If some family
members want a different language for titles/plots, add a second library
(e.g. "Films" in Italian) pointing at the same `/media/movies` folder with
different metadata settings, and restrict access to it to just them.

## 3. Network settings

*Dashboard → Networking*:

1. **LAN networks**: `192.168.1.0/24, 100.64.0.0/10` (the second range is
   Tailscale's CGNAT range — this treats remote family devices as "local"
   so they aren't artificially bandwidth-limited).
2. **Known proxies / HTTPS**: leave empty for now.
3. Save, then: `docker compose restart jellyfin`.

## 4. Hardware acceleration (Intel Quick Sync)

*Dashboard → Playback → Transcoding*:

1. **Hardware acceleration**: Intel QuickSync (QSV); **QSV device**:
   `/dev/dri/renderD128`.
2. **Enable hardware decoding for**: H264, HEVC, MPEG2, VC1, VP8, VP9, AV1,
   HEVC 10bit, VP9 10bit.
3. Tick *Prefer OS native DXVA or VA-API hardware decoders*, *Enable
   hardware encoding*, *Enable Intel Low-Power H.264 hardware encoder* and
   *Enable Intel Low-Power HEVC hardware encoder*.
4. Tick *Allow encoding in HEVC format*; leave **AV1 encoding off** (the
   N150's iGPU can decode AV1 but not encode it).
5. Tick *Enable tone mapping* and *Enable VPP Tone mapping* (needed for HDR
   files played back on an SDR display).
6. **Transcode path**: `/cache/transcodes`. Tick *Throttle transcodes* and
   *Delete segments*.
7. Save.

### Verify it's actually using the GPU

Play a movie in the browser, click the gear icon → *Quality* → pick a low
bitrate (e.g. 3 Mbps) to force a transcode, then from another SSH session:

```bash
./scripts/08-check-hw-accel.sh
```

This checks `/dev/dri`, host and in-container `vainfo`, the `render` group
GID, and whether GuC/HuC firmware (required for the low-power encoders) is
loaded. If playback only fails with the low-power encoders ticked and
`dmesg` shows no GuC/HuC lines, add `i915.enable_guc=3` to
`GRUB_CMDLINE_LINUX_DEFAULT` in `/etc/default/grub`, then:

```bash
sudo update-grub
sudo reboot
```

You can also watch `sudo intel_gpu_top` live while a transcode plays — the
"Video" bar should move. In *Dashboard → Activity* the session should read
that the video is transcoding with hardware acceleration.

## 5. Users and languages (the multilingual part)

As `admin`, *Dashboard → Users → +*:

1. Enter a name and password; under *Library access* tick the libraries
   this person should see.
2. For a child's account: open the user → *Parental control* → set
   *Maximum allowed parental rating*, optionally an *Access schedule*, and
   **untick** *Allow media deletion*.
3. Under *Profile*, **untick** *Allow remote access* for anyone who only
   watches at home.

Each person then logs in as themselves → avatar (top right) → *Settings*:

| Where | Setting | Suggested value | Effect |
|---|---|---|---|
| Playback | Preferred audio language | e.g. Italian for one person, Spanish for another | Auto-selects that track when the file has it |
| Playback | Play default audio track regardless of language | Off | Otherwise the disc's default track always wins over the preference above |
| Subtitles | Subtitle language | e.g. Spanish | Preferred `.srt` or embedded track |
| Subtitles | Subtitle mode | Smart | Subtitles only appear automatically when the audio isn't in the preferred language |
| Display | Display language | the person's language | Menus and buttons |
| Home | Home screen sections | Continue Watching, Next Up, Latest Media | The "streaming service" home page feel |

These settings follow each user across TV, phone and browser apps
automatically.

## 6. Useful plugins

1. *Dashboard → Plugins → Catalog*.
2. Install **Open Subtitles** (see
   [10-subtitles.md](10-subtitles.md)) and **Playback Reporting** (who
   watched what, useful for a shared household server).
3. For **Intro Skipper** (a "Skip Intro" button on series), add its
   repository URL under *Plugins → Repositories → +* (find the current URL
   on the plugin's GitHub page, it's updated more often than release
   cadences fit here), then install it from the catalog.
4. Restart after installing any plugin: `docker compose restart jellyfin`.

## 7. Updating Jellyfin

```bash
cd /opt/stack
sudo tar czf /srv/backup/jellyfin-config-$(date +%F).tgz config/jellyfin   # quick manual config backup
docker compose pull jellyfin && docker compose up -d jellyfin
```

On major version upgrades, the first start after pulling runs database
migrations for a few minutes — don't interrupt it (watch `docker compose
logs -f jellyfin` until it settles).

## 8. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Library stays empty | Wrong folder or permissions | Folder must be `/media/movies` (the **container** path, not `/srv/...`); run `sudo chown -R 1000:1000 /srv/media` and rescan |
| Wrong movie matched | Folder name missing the year | Rename to `Title (Year)`, or use the item's `⋮ → Identify` |
| Playback buffers | Transcoding in software, not hardware | Check *Dashboard → Activity* for the transcode reason; re-check section 4 above and `RENDER_GID` in `/opt/stack/.env` |
| Buffering only when subtitles are on | Image-based subtitles (PGS/VobSub) forcing a burn-in transcode | Use a `.srt` for that language instead |
| TV app can't find the server | LAN discovery blocked | Type the address manually: `http://192.168.1.10:8096` |
| Container restarts in a loop | Config permission or disk issue | `docker compose logs jellyfin`; check `df -h /srv/media` |

Next: [09-immich.md](09-immich.md)
