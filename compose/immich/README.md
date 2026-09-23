# Immich compose stack

Immich publishes its own `docker-compose.yml` per release and upgrades on a
different schedule than the rest of the stack, so it isn't vendored in this
repo — you download it fresh, straight from the release you're installing.
See `docs/09-immich.md` for the full walkthrough. In short, on the server:

```bash
cd /opt/immich
wget -O docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
wget -O .env https://github.com/immich-app/immich/releases/latest/download/example.env
```

Then edit `.env` and `docker-compose.yml` as described in `docs/09-immich.md`
(upload location, database password, timezone, the read-only mount of your
existing photo archive, and optionally the Quick Sync / OpenVINO hardware
acceleration overrides).

`.env.notes.example` in this folder lists exactly which keys to change in the
downloaded `.env`, without duplicating the whole (large) upstream file.
