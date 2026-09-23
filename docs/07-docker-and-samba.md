# Docker and Samba

## 1. Install Docker

```bash
cd ~/media-server-setup/scripts
source config.env        # if not already sourced
./05-install-docker.sh
```

This uses Docker's official convenience script, adds your user to the
`docker` group, and caps container log growth (`log-driver: local`) so logs
don't silently fill the disk over months of uptime.

Log out and back in (or `newgrp docker`) so the new group membership takes
effect, then verify:

```bash
docker run --rm hello-world
docker compose version
```

Optional: [Dockge](https://github.com/louislam/dockge) or
[Portainer](https://www.portainer.io/) give you a web UI over your compose
stacks, if you'd rather not manage `docker-compose.yml` by hand. Not covered
here — the CLI is enough for this setup and keeps one less service to
secure/update.

## 2. Share `/srv/media` over Samba

This lets you drag your rips, home videos and photo archive from your
desktop straight onto the server, instead of copying files over SSH/SCP.

```bash
./06-setup-samba.sh
```

It installs Samba, appends a `[media]` share definition pointing at
`$MEDIA_DIR`, checks the config with `testparm`, and asks you to set a
**Samba password** for your user (this is separate from your Linux login
password — Samba keeps its own credential store).

### Connect from your PC

- **Windows**: File Explorer → *This PC* → *Map network drive* →
  `\\192.168.1.10\media` → tick *Connect using different credentials* → your
  username + the Samba password.
- **macOS**: Finder → *Go* → *Connect to Server* (`⌘K`) →
  `smb://192.168.1.10/media`.
- **Linux**: file manager address bar → `smb://192.168.1.10/media`.

## 3. Generate the compose stack's `.env`

The main `docker-compose.yml` (in `compose/stack/`) needs a `RENDER_GID`
value that's specific to *this machine* (the group ID Debian assigned to
`/dev/dri/renderD128`), so it can't be hardcoded.

```bash
# copy the compose stack onto the server, e.g.:
cp -r ~/media-server-setup/compose/stack/* /opt/stack/
cd ~/media-server-setup/scripts
./09-generate-stack-env.sh
```

This writes `/opt/stack/.env` with `RENDER_GID`, `TZ`, `PUID`/`PGID` and
`MEDIA_DIR` filled in. Re-run it any time you re-image the server — the
render group's GID isn't guaranteed to be the same across installs.

At this point `/opt/stack/` should contain `docker-compose.yml` and `.env`.
You're ready to bring up the first service.

Next: [08-jellyfin.md](08-jellyfin.md)
