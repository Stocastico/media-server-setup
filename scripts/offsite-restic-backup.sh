#!/bin/bash
# Weekly encrypted off-site backup of the photo library to Backblaze B2 (or
# any S3-compatible storage) using restic. Both local SSDs sit in the same
# building, so this is the only copy that survives fire/theft/power surge.
#
# One-time setup:
#   1. Create a B2 bucket and an "application key" in the Backblaze console.
#   2. cp restic-env.example /root/.restic-env && sudo nano /root/.restic-env
#      (fill in B2_ACCOUNT_ID, B2_ACCOUNT_KEY, RESTIC_REPOSITORY, and a long
#      random RESTIC_PASSWORD - store that password in your password manager,
#      without it the backup is unreadable, even by you)
#   3. sudo chmod 600 /root/.restic-env
#   4. ./offsite-restic-backup.sh init
#   5. ./offsite-restic-backup.sh install-cron
#
# Manual runs:
#   ./offsite-restic-backup.sh backup     # run a backup now
#   ./offsite-restic-backup.sh snapshots  # list snapshots
#   ./offsite-restic-backup.sh test-restore
set -euo pipefail

ENV_FILE="/root/.restic-env"
PHOTO_PATHS=(/srv/media/photos /srv/media/immich-library)
ACTION="${1:-}"

require_env() {
  [[ -f "$ENV_FILE" ]] || { echo "ERROR: $ENV_FILE not found. Copy restic-env.example there and fill it in first." >&2; exit 1; }
}

case "$ACTION" in
  init)
    require_env
    command -v restic >/dev/null || sudo apt install -y restic
    sudo bash -c ". $ENV_FILE && restic init"
    ;;
  backup)
    require_env
    sudo bash -c ". $ENV_FILE && restic backup --quiet ${PHOTO_PATHS[*]} && restic forget --quiet --keep-daily 7 --keep-weekly 8 --keep-monthly 12 --prune"
    ;;
  snapshots)
    require_env
    sudo bash -c ". $ENV_FILE && restic snapshots"
    ;;
  test-restore)
    require_env
    echo "Restoring a sample into /tmp/restore-test ..."
    sudo bash -c ". $ENV_FILE && restic restore latest --target /tmp/restore-test --include /srv/media/photos"
    ls /tmp/restore-test/srv/media/photos | head
    echo "Remove the test copy with: sudo rm -rf /tmp/restore-test"
    ;;
  install-cron)
    require_env
    SCRIPT_PATH="$(readlink -f "$0")"
    sudo install -m 0755 "$SCRIPT_PATH" /usr/local/bin/offsite-restic-backup.sh
    echo "0 5 * * 0 root /usr/local/bin/offsite-restic-backup.sh backup" | sudo tee /etc/cron.d/offsite-photos
    echo "Scheduled for Sunday 05:00. Test it now with: sudo /usr/local/bin/offsite-restic-backup.sh backup"
    ;;
  *)
    echo "Usage: $0 {init|backup|snapshots|test-restore|install-cron}" >&2
    exit 1
    ;;
esac
