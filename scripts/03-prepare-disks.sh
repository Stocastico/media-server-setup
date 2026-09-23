#!/bin/bash
# Partitions, formats and mounts the two USB SSDs (media + backup).
#
# *** THIS SCRIPT ERASES THE TWO DISKS YOU POINT IT AT. ***
#
# Run on the server, as a user with sudo. Requires `source config.env` first
# (see 00-config.env.example), or export MEDIA_LABEL/BACKUP_LABEL yourself.
#
# Usage: ./03-prepare-disks.sh /dev/sda /dev/sdb
#        (first disk becomes "media", second becomes "backup")
set -euo pipefail

MEDIA_DISK="${1:?Usage: $0 <media-disk e.g. /dev/sda> <backup-disk e.g. /dev/sdb>}"
BACKUP_DISK="${2:?Usage: $0 <media-disk e.g. /dev/sda> <backup-disk e.g. /dev/sdb>}"
MEDIA_LABEL="${MEDIA_LABEL:-media}"
BACKUP_LABEL="${BACKUP_LABEL:-backup}"
MEDIA_DIR="${MEDIA_DIR:-/srv/media}"
BACKUP_DIR="${BACKUP_DIR:-/srv/backup}"

echo "==> Devices currently attached:"
lsblk -o NAME,SIZE,MODEL,TRAN,FSTYPE,MOUNTPOINTS

for dev in "$MEDIA_DISK" "$BACKUP_DISK"; do
  [[ -b "$dev" ]] || { echo "ERROR: $dev is not a block device" >&2; exit 1; }
  tran=$(lsblk -no TRAN "$dev" | head -n1)
  if [[ "$tran" != "usb" ]]; then
    echo "ERROR: $dev does not report TRAN=usb (reports '$tran')." >&2
    echo "Refusing to continue: this script must never touch the internal NVMe." >&2
    exit 1
  fi
done

echo
echo "About to WIPE and reformat as ext4:"
echo "  $MEDIA_DISK  -> label '$MEDIA_LABEL', mounted at $MEDIA_DIR"
echo "  $BACKUP_DISK -> label '$BACKUP_LABEL', mounted at $BACKUP_DIR"
echo "ALL DATA ON BOTH DISKS WILL BE LOST."
read -r -p "Type YES to continue: " confirm
[[ "$confirm" == "YES" ]] || { echo "Aborted."; exit 1; }

echo "==> Wiping existing signatures"
sudo wipefs -a "$MEDIA_DISK" "$BACKUP_DISK"

echo "==> Partitioning"
sudo parted -s "$MEDIA_DISK" mklabel gpt mkpart "$MEDIA_LABEL" ext4 0% 100%
sudo parted -s "$BACKUP_DISK" mklabel gpt mkpart "$BACKUP_LABEL" ext4 0% 100%

echo "==> Formatting"
sudo mkfs.ext4 -L "$MEDIA_LABEL" "${MEDIA_DISK}1"
sudo mkfs.ext4 -L "$BACKUP_LABEL" "${BACKUP_DISK}1"

echo "==> Creating mount points"
sudo mkdir -p "$MEDIA_DIR" "$BACKUP_DIR"
# chattr +i on the empty mountpoint: if the disk fails to mount, writes
# land on the NVMe and fail loudly instead of silently filling root.
sudo chattr +i "$MEDIA_DIR" "$BACKUP_DIR" || true

echo "==> Adding fstab entries"
if ! grep -q "LABEL=$MEDIA_LABEL" /etc/fstab; then
  {
    echo "LABEL=$MEDIA_LABEL              $MEDIA_DIR    ext4   defaults,noatime,nofail,x-systemd.device-timeout=15s   0 2"
    echo "LABEL=$BACKUP_LABEL             $BACKUP_DIR   ext4   defaults,noatime,nofail,x-systemd.device-timeout=15s   0 2"
  } | sudo tee -a /etc/fstab
else
  echo "fstab already has an entry for LABEL=$MEDIA_LABEL, skipping"
fi

sudo systemctl daemon-reload
sudo mount -a
df -h "$MEDIA_DIR" "$BACKUP_DIR"

echo "==> Enabling weekly TRIM"
sudo systemctl enable --now fstrim.timer
echo "TRIM support through the USB adapter (non-zero DISC-MAX means it works):"
lsblk --discard "$MEDIA_DISK" "$BACKUP_DISK"

cat <<EOF

==> Disks prepared.
Reboot once (sudo reboot) and re-check 'df -h $MEDIA_DIR $BACKUP_DIR' to
confirm both SSDs mount automatically on their own.
EOF
