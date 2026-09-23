# Subtitles: manual and automatic

Start with Jellyfin's OpenSubtitles plugin (30 minutes). Only add Bazarr if
you find yourself manually fetching subtitles for dozens of titles — it's
more setup for more automation.

Text subtitles (`.srt`, `.ass`) direct-play on virtually every client. Image
subtitles (DVD VobSub, Blu-ray PGS) always force a transcode when enabled,
even if the video itself would otherwise direct-play — so prefer `.srt`
files wherever you can get them.

## Option A — on demand, inside Jellyfin

1. Create a free account at **opensubtitles.com** (not the old `.org`
   site — that one's a different, largely abandoned service). The free tier
   allows a small number of downloads per day.
2. Jellyfin, as admin: *Dashboard → Plugins → Catalog → Open Subtitles →
   Install*, then `docker compose restart jellyfin`.
3. *Dashboard → Plugins → My Plugins → Open Subtitles* → enter your
   opensubtitles.com username and password → *Save*.
4. *Dashboard → Libraries* → on your Movies library `⋮ → Manage Library →
   Subtitle downloads*:
   - **Download languages**: tick the ones your household needs.
   - **Subtitle downloaders**: tick *Open Subtitles*.
   - **Untick** *Save subtitles into media folders* — the media mount is
     read-only (by design, see [08-jellyfin.md](08-jellyfin.md)), so
     Jellyfin keeps downloaded subtitles in its own metadata folder
     instead.
   - Optionally tick *Only download subtitles that are a perfect match*.
   - Save, then repeat for the Series library.
5. **Per title**: open the movie → `⋮ → Edit Subtitles` → choose a language
   → *Search* → click the download icon on the best match.
6. **In bulk**: *Dashboard → Scheduled Tasks → Download Missing Subtitles*
   → ▶ run (respects the daily download limit of the free tier, so a large
   library can take several days to fully catch up).
7. **Out of sync?** While playing, open the subtitle menu → *Subtitle
   Offset* and nudge it in 0.1 s steps.

## Option B — fully automatic with Bazarr

Bazarr needs Radarr (movies) and Sonarr (series) to know what's in your
library. Here they're used **only as library indexes** of folders you
already own the content for — no indexers are configured, no download
clients are wired up, and nothing gets automatically searched or
downloaded. They exist purely so Bazarr knows which files exist and can
fetch matching subtitles.

### B1. Start the three services

They're already defined in `compose/stack/docker-compose.yml` under the
`subtitles` profile:

```bash
cd /opt/stack
docker compose --profile subtitles up -d radarr sonarr bazarr
```

### B2. Radarr (movies) — `http://192.168.1.10:7878`

1. First visit asks you to set up authentication: choose *Forms* (login
   page), *Authentication required: Enabled*, pick a username and password.
2. *Settings → Media Management → Add Root Folder* → `/movies`.
3. *Movies → Library Import* → `/movies` → *Start Import*. On the import
   screen set **Monitor: None** and leave **Start search unticked**, then
   *Import*. Check any title it couldn't match and pick the right one
   manually.
4. *Settings → General* → copy the **API Key** (you'll paste it into
   Bazarr next).

### B3. Sonarr (series) — `http://192.168.1.10:8989`

Same steps as Radarr: set up authentication → *Settings → Media Management*
→ root folder `/tv` → *Series → Library Import* with **Monitor: None** →
copy the API key from *Settings → General*.

### B4. Bazarr — `http://192.168.1.10:6767`

1. *Settings → General → Security*: set *Authentication* to *Form* with a
   username and password → *Save*.
2. *Settings → Languages*:
   - **Languages Filter**: add the languages your household needs.
   - **Languages Profiles → Add New Profile** → name it (e.g. "Household")
     → add those languages → *Save*.
   - **Default Settings**: set both Series and Movies to that profile →
     *Save*.
3. *Settings → Providers* → add **OpenSubtitles.com** (your account),
   **Podnapisi** (strong for European languages) and **Addic7ed** (TV
   series) → *Save*.
4. *Settings → Radarr* → *Enabled* → Address `radarr`, Port `7878`, paste
   the API key → *Test* → *Save*. Then *Settings → Sonarr* → Address
   `sonarr`, Port `8989`, API key → *Test* → *Save*. (The container names
   work directly as hostnames because they share one compose file/network.)
5. *Settings → Subtitles*:
   - **Use embedded subtitles**: on (don't re-fetch what the file already
     has).
   - **Automatic subtitles synchronization**: on, so downloaded subtitles
     get aligned to your specific rip's timing.
   - **Minimum score**: around 90 for both movies and episodes, to avoid
     wrong-match subtitles.
6. *Movies* / *Series*: select all → *Mass Edit* → set the language profile
   from step 2 → *Save*. Bazarr starts searching in the background —
   *System → Tasks* shows progress.

Bazarr writes files like `Title (Year).it.srt` next to each video. Jellyfin
picks them up automatically if real-time monitoring is on (see
[08-jellyfin.md](08-jellyfin.md)), or on the next library scan otherwise.

Next: [11-qbittorrent.md](11-qbittorrent.md)
