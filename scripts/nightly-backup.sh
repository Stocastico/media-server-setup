#!/bin/bash
# Nightly local backup: mirrors media/photos and container configs onto the
# second SSD, keeping 30 days of anything deleted or overwritten instead of
# discarding it immediately.
#
# Install with scripts/setup-nightly-backup-cron.sh, which copies this file
# to /usr/local/bin/nightly-backup.sh and schedules it at 03:30 daily.
set -euo pipefail
exec >>/var/log/nightly-backup.log 2>&1

MEDIA_DIR="/srv/media"
BACKUP_DIR="/srv/backup"
STACK_DIR="/opt/stack"
IMMICH_DIR="/opt/immich"
KEEP_DELETED_DAYS=30

echo "=== $(date '+%F %T') start"

mountpoint -q "$MEDIA_DIR" || { echo "media SSD not mounted"; exit 1; }
mountpoint -q "$BACKUP_DIR" || { echo "backup SSD not mounted"; exit 1; }

TODAY=$(date +%F)

# 1. Media + photos. Anything deleted or overwritten on the live SSD is kept
#    for KEEP_DELETED_DAYS days under backup/deleted/<date> instead of
#    vanishing immediately.
rsync -a --delete --exclude 'downloads/' \
  --backup --backup-dir="${BACKUP_DIR}/deleted/${TODAY}" \
  "${MEDIA_DIR}/" "${BACKUP_DIR}/media/"

# 2. Stack configs. Jellyfin is stopped briefly so its SQLite database is
#    copied in a consistent state.
cd "$STACK_DIR"
docker compose stop jellyfin
rsync -a --delete "${STACK_DIR}/" "${BACKUP_DIR}/opt-stack/"
docker compose start jellyfin

# 3. Immich config. The live Postgres data directory is skipped: Immich's
#    own daily SQL dump (in ${MEDIA_DIR}/immich-library/backups) is what
#    gets backed up, via step 1 above.
rsync -a --delete --exclude 'postgres/' "${IMMICH_DIR}/" "${BACKUP_DIR}/opt-immich/"

# 4. Forget deleted-file copies older than KEEP_DELETED_DAYS
find "${BACKUP_DIR}/deleted" -mindepth 1 -maxdepth 1 -mtime +${KEEP_DELETED_DAYS} -exec rm -rf {} +

echo "=== $(date '+%F %T') done"
