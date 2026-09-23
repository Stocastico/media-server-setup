#!/bin/bash
# Creates the media/backup folder layout and the docker-compose directories,
# and sets ownership. Run after 03-prepare-disks.sh, once the two SSDs are
# mounted.
#
# Usage: ./04-create-folders.sh  (source scripts/config.env first)
set -euo pipefail

MEDIA_DIR="${MEDIA_DIR:-/srv/media}"
BACKUP_DIR="${BACKUP_DIR:-/srv/backup}"
STACK_DIR="${STACK_DIR:-/opt/stack}"
IMMICH_DIR="${IMMICH_DIR:-/opt/immich}"
PUID="${PUID:-1000}"
PGID="${PGID:-1000}"

for d in "$MEDIA_DIR" "$BACKUP_DIR"; do
  mountpoint -q "$d" || { echo "ERROR: $d is not a mounted filesystem. Run 03-prepare-disks.sh first." >&2; exit 1; }
done

echo "==> Creating media folder layout under $MEDIA_DIR"
sudo mkdir -p \
  "$MEDIA_DIR/movies" \
  "$MEDIA_DIR/tv" \
  "$MEDIA_DIR/home-videos" \
  "$MEDIA_DIR/photos" \
  "$MEDIA_DIR/immich-library" \
  "$MEDIA_DIR/downloads/incomplete" \
  "$MEDIA_DIR/downloads/complete"

echo "==> Creating compose directories on the internal NVMe"
sudo mkdir -p "$STACK_DIR/config" "$STACK_DIR/cache" "$IMMICH_DIR"

echo "==> Setting ownership to ${PUID}:${PGID}"
sudo chown -R "${PUID}:${PGID}" "$MEDIA_DIR" "$BACKUP_DIR" "$STACK_DIR" "$IMMICH_DIR"

echo "==> Current user identity (must match PUID/PGID above):"
id

echo "Done. Tree:"
find "$MEDIA_DIR" -maxdepth 2 | sort
