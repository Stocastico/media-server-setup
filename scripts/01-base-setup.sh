#!/bin/bash
# Base OS setup: non-free firmware repo, package updates, essential tools,
# Intel GPU drivers, timezone, automatic security updates.
#
# Run on the server itself (over SSH), as the user created during install.
# Usage: ./01-base-setup.sh
set -euo pipefail

SOURCES_FILE="/etc/apt/sources.list.d/debian.sources"

if [[ ! -f "$SOURCES_FILE" ]]; then
  echo "ERROR: $SOURCES_FILE not found. This script targets Debian 13 (trixie)'s" >&2
  echo "deb822-style sources file. If you're on an older Debian release, edit" >&2
  echo "/etc/apt/sources.list by hand instead." >&2
  exit 1
fi

echo "==> Enabling non-free firmware components (needed for the Intel GPU driver)"
sudo cp "$SOURCES_FILE" "${SOURCES_FILE}.bak.$(date +%F)"
sudo sed -i -E 's/^Components:\s*main(\s+contrib)?(\s+non-free)?(\s+non-free-firmware)?\s*$/Components: main contrib non-free non-free-firmware/' "$SOURCES_FILE"
grep -q 'non-free-firmware' "$SOURCES_FILE" || {
  echo "ERROR: could not patch $SOURCES_FILE automatically, edit it by hand:" >&2
  echo "  sudo nano $SOURCES_FILE" >&2
  echo "Make every 'Components:' line read: main contrib non-free non-free-firmware" >&2
  exit 1
}

echo "==> Updating and upgrading the system"
sudo apt update
sudo apt full-upgrade -y

echo "==> Installing base tools and the Intel GPU driver"
sudo apt install -y \
  curl wget htop nano parted rsync smartmontools unattended-upgrades \
  firmware-misc-nonfree intel-media-va-driver-non-free intel-gpu-tools vainfo

echo "==> Setting timezone to ${TZ:-Europe/Madrid}"
sudo timedatectl set-timezone "${TZ:-Europe/Madrid}"

echo "==> Enabling unattended security upgrades"
echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | sudo debconf-set-selections
sudo dpkg-reconfigure -f noninteractive unattended-upgrades

cat <<'EOF'

==> Base setup done.

A reboot is required to load the Intel GPU driver and the latest kernel.
Run:  sudo reboot

After the reboot, verify the iGPU is visible with:
  ls -l /dev/dri            # expect card0 (or card1) and renderD128
  vainfo                    # expect a list of H.264/HEVC decode/encode profiles
EOF
