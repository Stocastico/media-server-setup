# Downloads: qBittorrent

Runs qBittorrent's headless build (web UI only) in Docker, downloads into
`/srv/media/downloads`, then you move finished files into the library.
Budget 30–45 minutes.

qBittorrent is a general-purpose BitTorrent client — use it only for
content you have the right to download (public-domain works, Creative
Commons releases, Linux ISOs, your own backups, etc.). Section 6 below lists
sources for free, legal films.

## 1. Start the service

Already defined in `compose/stack/docker-compose.yml` as a core service:

```bash
cd /opt/stack
docker compose up -d qbittorrent
docker compose logs qbittorrent 2>&1 | grep -i password   # shows a temporary admin password
```

## 2. First login and security

1. Open `http://192.168.1.10:8080`, log in as `admin` with the temporary
   password from the logs above.
2. `⚙ Options → Web UI → Authentication`: set your own username and a
   strong password.
3. Same page: leave *Bypass authentication for clients on localhost* off;
   set *Ban client after consecutive failures* to `5`.
4. Scroll down → *Save*. Log out and back in with the new credentials.

## 3. Recommended settings

`⚙ Options`, tab by tab:

| Tab | Setting | Value | Why |
|---|---|---|---|
| Downloads | Default Save Path | `/downloads/complete` | Finished files land here |
| Downloads | Keep incomplete torrents in | ✔ `/downloads/incomplete` | Half-finished files never mix with finished ones |
| Downloads | Append `.!qB` extension to incomplete files | ✔ | Easy to spot unfinished files in the filesystem |
| Connection | Port used for incoming connections | `6881` | Matches the compose file's port mapping |
| Connection | Use UPnP / NAT-PMP port forwarding | ✘ | No automatic holes punched in your router |
| Speed | Global upload limit | e.g. 70% of your upload speed | Keeps video calls and streaming smooth for everyone else at home |
| Speed | Alternative rate limits + Schedule | e.g. lower limits 19:00–23:00 | Evening TV time stays smooth |
| BitTorrent | Seeding limits: When ratio reaches | `2.0` → Pause torrent | Gives back to the swarm, then stops automatically |
| BitTorrent | Enable DHT, PeX, Local Peer Discovery | ✔ | Needed for most public torrents to find peers |

Click *Save* at the bottom. If downloads are slow, forward TCP/UDP port
`6881` to `192.168.1.10` on your router — this is optional and not required
for it to work.

**Note on speed**: only the *upload* limit above is capped by default —
**downloads are already unrestricted**, so adding something new pulls at
full available speed without any extra configuration. The *Alternative
rate limits* schedule only throttles the evening hours if you set one up;
you can also flip it on/off instantly at any time with the small
turtle-shaped icon in the bottom-right corner of the web UI, e.g. to go
back to full upload speed right after adding something even during the
scheduled window.

## 4. Categories for movies and series

1. Left sidebar → right-click *Categories* → *Add category*.
2. Category `movies`, save path `/downloads/complete/movies` → *Add*.
3. Repeat with `tv` → `/downloads/complete/tv`.

Choose the matching category whenever you add a torrent, so it lands in the
right subfolder automatically.

## 5. Adding a download and moving it into Jellyfin

1. **Get the torrent**: on an Internet Archive film page, open *Download
   Options* (right-hand side) → *TORRENT* and copy the link, or download
   the `.torrent` file.
2. In qBittorrent: click **+** (*Add Torrent Link*) and paste the link, or
   the folder icon (*Add Torrent File*) to upload the file. Choose the
   category (`movies`) → *Download*.
3. When it finishes, rename and move it into the library. Moving is instant
   since it's the same physical SSD:
   ```bash
   cd /srv/media/downloads/complete/movies
   ls                                                       # see what arrived
   mkdir -p "/srv/media/movies/Nosferatu (1922)"
   mv "Nosferatu_1922_original.mp4" "/srv/media/movies/Nosferatu (1922)/Nosferatu (1922).mp4"
   ```
   (You can do the same thing by drag-and-drop through the Samba share from
   your PC — see [07-docker-and-samba.md](07-docker-and-samba.md).)
4. In qBittorrent, right-click the torrent → *Remove* (**without** deleting
   files, since you've already moved them). Moving the files out from under
   qBittorrent stops seeding, which is fine for archive-type downloads.
5. Jellyfin picks it up within a minute via real-time monitoring;
   otherwise trigger *Dashboard → Libraries → Scan All Libraries* manually.

**Optional privacy layer**: route the qBittorrent container through
[Gluetun](https://github.com/qdm12/gluetun) with a paid VPN
(`network_mode: service:gluetun`), which also acts as a kill switch if the
VPN drops. Not needed for public-domain downloads, but worth it if you plan
to use qBittorrent more broadly.

## 6. Where to find free, legal films

| Source | What you get | Watch out for |
|---|---|---|
| [Internet Archive – Feature Films](https://archive.org/details/feature_films) | Thousands of classic films; every item has a direct download and a torrent link | Many are public domain only in the US, not necessarily in your own country |
| [Internet Archive – Moving Image Archive](https://archive.org/details/movies) | Noir, silent era, early sci-fi | Quality varies; check the uploader's rights note on each item |
| [Wikimedia Commons – films](https://commons.wikimedia.org/wiki/Category:Films) | Verified free-licence and public-domain films, often with subtitle files included | Smaller catalogue |
| Creative Commons releases (e.g. Blender Studio's open movies) | Freely redistributable modern shorts/features | — |
| Your own discs and tapes | Your own rips (a separate project of its own) | Keep the originals |

For free, legal streaming in Spanish/Basque without downloading, RTVE Play
and EITB's Primeran complement the server.

Next: [12-tv-and-device-clients.md](12-tv-and-device-clients.md)
