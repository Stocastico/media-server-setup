#!/bin/bash
# One-time bulk import of an existing archive (ripped DVDs, home videos,
# photos) from an external drive into the media library. Meant to be run
# locally on the server, with the external drive plugged directly into the
# mini PC — not over Samba/Wi-Fi, which is far slower for a one-off
# multi-hundred-GB (or multi-TB) transfer.
#
# Safe to interrupt and re-run: it's an incremental rsync, already-copied
# files are skipped/updated rather than re-copied from scratch.
#
# Usage:
#   ./import-initial-archive.sh <source-dir> <movies|tv|home-videos|photos> [--verify]
#
# Examples:
#   ./import-initial-archive.sh /mnt/external-hdd/Movies movies
#   ./import-initial-archive.sh /mnt/external-hdd/Movies movies --verify   # also checksums every file afterward
set -euo pipefail

SOURCE_DIR="${1:?Usage: $0 <source-dir> <movies|tv|home-videos|photos> [--verify]}"
DEST_KIND="${2:?Usage: $0 <source-dir> <movies|tv|home-videos|photos> [--verify]}"
VERIFY="${3:-}"

MEDIA_DIR="${MEDIA_DIR:-/srv/media}"
LOG_FILE="/var/log/initial-import.log"

case "$DEST_KIND" in
  movies|tv|home-videos|photos) ;;
  *)
    echo "ERROR: destination must be one of: movies, tv, home-videos, photos" >&2
    echo "(immich-library is not a valid target: it's written by Immich itself - import photos through the 'photos' folder and Immich's External Library feature instead, see docs/09-immich.md)" >&2
    exit 1
    ;;
esac

DEST_DIR="${MEDIA_DIR}/${DEST_KIND}"

[[ -d "$SOURCE_DIR" ]] || { echo "ERROR: source directory not found: $SOURCE_DIR" >&2; exit 1; }
mountpoint -q "$MEDIA_DIR" || { echo "ERROR: $MEDIA_DIR is not mounted - is the media SSD plugged in?" >&2; exit 1; }
[[ -d "$DEST_DIR" ]] || { echo "ERROR: $DEST_DIR doesn't exist. Run scripts/04-create-folders.sh first." >&2; exit 1; }

echo "== Source =="
du -sh "$SOURCE_DIR"
echo
echo "== Destination free space =="
df -h "$MEDIA_DIR"
echo
read -r -p "Copy everything from '$SOURCE_DIR' into '$DEST_DIR'? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }

exec > >(tee -a "$LOG_FILE") 2>&1
echo "=== $(date '+%F %T') import start: $SOURCE_DIR -> $DEST_DIR"

rsync -avh --progress "$SOURCE_DIR"/ "$DEST_DIR"/

echo "=== $(date '+%F %T') copy done"

if [[ "$VERIFY" == "--verify" ]]; then
  echo "=== $(date '+%F %T') verifying checksums (this re-reads every file, can take a while)"
  rsync -avh --checksum --dry-run "$SOURCE_DIR"/ "$DEST_DIR"/ | tee /tmp/import-verify-diff.txt
  if [[ -s /tmp/import-verify-diff.txt ]] && grep -qv '^sending incremental file list$\|^$\|^sent \|^total size' /tmp/import-verify-diff.txt; then
    echo "!! Some files differ between source and destination - see /tmp/import-verify-diff.txt. Do not wipe the source drive yet."
  else
    echo "Verification OK: destination matches source byte for byte."
  fi
fi

cat <<EOF

=== $(date '+%F %T') import finished.

DO NOT reuse or wipe '$SOURCE_DIR' yet. First:
  1. Spot-check a few files (open a movie in Jellyfin, view a photo, etc.).
  2. Run the nightly backup by hand right now, so a second copy exists
     before you touch the source drive again:
       sudo /usr/local/bin/nightly-backup.sh
       tail -n 10 /var/log/nightly-backup.log   # should end with "done"

Only once both of those check out is it safe to free up the source drive.
EOF
