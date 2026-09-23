#!/bin/bash
# Runs through the monthly maintenance checklist and prints a short report.
# Doesn't change anything by itself except OS/container updates, which it
# asks about first. Meant to be run by hand, once a month.
#
# Usage: ./monthly-maintenance.sh   (source scripts/config.env first)
set -euo pipefail

STACK_DIR="${STACK_DIR:-/opt/stack}"
IMMICH_DIR="${IMMICH_DIR:-/opt/immich}"
MEDIA_DIR="${MEDIA_DIR:-/srv/media}"
BACKUP_DIR="${BACKUP_DIR:-/srv/backup}"

echo "########## 1. OS updates ##########"
sudo apt update
sudo apt list --upgradable
read -r -p "Run 'apt full-upgrade -y' now? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  sudo apt full-upgrade -y
  if [[ -f /var/run/reboot-required ]]; then
    echo "!! A reboot is required (kernel update). Run 'sudo reboot' when convenient."
  fi
fi

echo
echo "########## 2. Container updates ##########"
echo "(Check the Immich release notes before upgrading: https://github.com/immich-app/immich/releases)"
read -r -p "Pull and restart all containers now? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  (cd "$STACK_DIR" && docker compose pull && docker compose up -d)
  (cd "$IMMICH_DIR" && docker compose pull && docker compose up -d)
  docker image prune -f
fi

echo
echo "########## 3. Free space ##########"
df -h "$MEDIA_DIR" "$BACKUP_DIR" /

echo
echo "########## 4. Backup log (last 20 lines) ##########"
tail -n 20 /var/log/nightly-backup.log 2>/dev/null || echo "No backup log yet."

echo
echo "########## 5. SSD health ##########"
sudo smartctl --scan || true
echo "Run 'sudo smartctl -a -d sat /dev/sdX' for each disk above and check"
echo "'Percentage Used' and 'Available Spare'. If -d sat fails on a portable"
echo "SSD, try -d sntasmedia, -d sntrealtek or -d sntjmicron."

echo
echo "########## 6. Reminders ##########"
echo "- Jellyfin: Dashboard -> Scheduled Tasks, make sure nothing shows errors."
echo "- Every night's backup log entry should end with 'done'."
