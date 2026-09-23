# Photos with Immich

Immich gives you a Google Photos-like timeline, maps, face grouping, smart
search and automatic phone backup. It runs as its **own** compose stack in
`/opt/immich`, separate from `/opt/stack`, because it upgrades on its own
release schedule. Budget 1–2 hours hands-on, plus background indexing time
that scales with your photo library size.

## 1. Download the official compose files

Immich publishes a ready-to-use `docker-compose.yml` and `.env` per release
— don't hand-write them, download the current ones directly from the
project:

```bash
cd /opt/immich
wget -O docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
wget -O .env https://github.com/immich-app/immich/releases/latest/download/example.env
openssl rand -hex 16    # copy the output: it becomes the database password
nano .env
```

Set these lines in `.env` (leave everything else at its default — see
`compose/immich/.env.notes.example` in this repo for the short version):

```
UPLOAD_LOCATION=/srv/media/immich-library    # phone uploads land here (USB SSD)
DB_DATA_LOCATION=/opt/immich/postgres        # database: internal NVMe, never on USB
TZ=Europe/Madrid
IMMICH_VERSION=v3                            # pin the major version; upgrade deliberately
DB_PASSWORD=<paste the random string from openssl above>
```

## 2. Let Immich read your existing photo archive

Copy your existing photos into `/srv/media/photos` over the Samba share set
up in [07-docker-and-samba.md](07-docker-and-samba.md) — any folder
structure works, Immich indexes recursively.

Then open `docker-compose.yml` and, under `immich-server: → volumes:`, add
one line so it looks like this:

```yaml
  immich-server:
    # ...
    volumes:
      - ${UPLOAD_LOCATION}:/data
      - /etc/localtime:/etc/localtime:ro
      - /srv/media/photos:/mnt/photos:ro    # <-- add this line
```

The `:ro` (read-only) means Immich can show and index the archive but can
never modify or delete the originals. (The first two lines may differ
slightly between releases — only add the third one.)

## 3. Optional: use the Intel iGPU

This makes video thumbnail generation and face/smart-search indexing
noticeably faster on the N150.

```bash
cd /opt/immich
wget -O hwaccel.transcoding.yml https://github.com/immich-app/immich/releases/latest/download/hwaccel.transcoding.yml
wget -O hwaccel.ml.yml https://github.com/immich-app/immich/releases/latest/download/hwaccel.ml.yml
nano docker-compose.yml
```

1. Under `immich-server:`, uncomment the `extends:` block and set
   `service: quicksync`.
2. Under `immich-machine-learning:`, uncomment its `extends:` block, set
   `service: openvino`, and change the image tag to end in `-openvino`
   (e.g. `...immich-machine-learning:${IMMICH_VERSION:-release}-openvino`).
3. After starting Immich (next step): *Administration → Settings → Video
   Transcoding Settings → Hardware Acceleration → Quick Sync*, and tick
   *Hardware decoding*.

## 4. Start Immich

```bash
cd /opt/immich
docker compose up -d
docker compose ps                     # immich_server, immich_machine_learning, redis, database: all "Up"
docker compose logs -f immich-server  # wait until it reports listening, then Ctrl+C
```

## 5. First-time setup in the browser

1. Open `http://192.168.1.10:2283` → *Getting Started* → create the admin
   account (the first account created is always the admin).
2. *Administration → Settings → Storage Template* → enable it, e.g.
   `{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}`, so phone uploads are filed by
   date on disk instead of piling into one folder.
3. *Administration → Users → Create user* for each family member; set a
   storage quota if you want one.
4. Log out and back in as **yourself** (not `admin`) for daily use — the
   admin account is for administration, not for uploading your own photos.

## 6. Import the existing archive (external library)

1. *Administration → External Libraries → Create library* → choose the
   owner (e.g. you).
2. Open the library's `⋮` menu → *Edit import paths* → *Add path* →
   `/mnt/photos` → *Save*.
3. `⋮` → *Scan*. Photos appear in the owner's timeline as they're indexed.
4. *Administration → Jobs*: *Generate Thumbnails*, *Extract Metadata*,
   *Smart Search* and *Face Detection* run automatically. On an N150, tens
   of thousands of photos can take hours to a day or two — the server stays
   usable meanwhile, it just chews background CPU.
5. To share the archive with other family members: *Sharing → Partner
   Sharing* from your account, or put selected photos in shared albums.

## 7. Phone backup

1. Install the Immich app (App Store / Play Store).
2. Server URL: `http://192.168.1.10:2283` (later
   `http://mediaserver:2283` once Tailscale is set up) → log in with your
   own user.
3. Tap the cloud icon → *Backup* → *Select Albums* → pick Camera/Recents
   (exclude WhatsApp or screenshot folders if you don't want those backed
   up).
4. Turn on *Background Backup* (Android) or enable *Background App
   Refresh* (iOS — Apple's background execution model means you should also
   open the app every few days so large backlogs actually finish). Android
   lets you require Wi-Fi and charging before it runs.
5. **Wait for the first backup to finish on Wi-Fi before deleting anything
   from the phone.** Immich is a backup target, not a reason to have only
   one copy of anything.

## 8. Upgrades and database backups

- Immich writes a daily database dump to
  `/srv/media/immich-library/backups` (*Administration → Settings → Backup
  Settings*). The nightly backup script (see
  [14-backups-and-maintenance.md](14-backups-and-maintenance.md)) copies it
  to the backup SSD along with everything else under `/srv/media`.
- To upgrade **within** v3: read the release notes first, then:
  ```bash
  cd /opt/immich && docker compose pull && docker compose up -d
  ```
- To move to a **future major version**: change `IMMICH_VERSION` in `.env`
  deliberately, and follow that specific release's migration guide — major
  version bumps can include breaking database migrations.

Jellyfin can still show `home-videos/`, but keep **photos** in Immich only
— don't point both Jellyfin and Immich at the same folder for editing, or
you risk one of them treating the other's writes as unexpected changes.

Next: [10-subtitles.md](10-subtitles.md)
