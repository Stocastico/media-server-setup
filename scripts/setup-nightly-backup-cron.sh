#!/bin/bash
# Installs nightly-backup.sh to /usr/local/bin, runs it once by hand, then
# schedules it for 03:30 every night via /etc/cron.d.
#
# Usage: ./setup-nightly-backup-cron.sh
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

sudo install -m 0755 "${SCRIPT_DIR}/nightly-backup.sh" /usr/local/bin/nightly-backup.sh

echo "==> Running the backup once by hand (this first run copies everything and can take a while)"
sudo /usr/local/bin/nightly-backup.sh
tail -n 5 /var/log/nightly-backup.log

echo "==> Scheduling it for 03:30 every night"
echo '30 3 * * * root /usr/local/bin/nightly-backup.sh' | sudo tee /etc/cron.d/nightly-backup

echo "Done. Check /var/log/nightly-backup.log after tonight's run."
