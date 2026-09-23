#!/bin/bash
# Writes a Debian netinst ISO to a USB stick. Run this on your PC (Linux or
# macOS), NOT on the server. ERASES the target USB stick completely.
#
# Usage: ./make-installer-usb.sh debian-13.7.0-amd64-netinst.iso /dev/sdX
#
# Find the right device first with `lsblk` (Linux) or `diskutil list` (macOS)
# - look for the size of your USB stick, and TRIPLE-CHECK you're not about to
# pick an internal disk.
set -euo pipefail

ISO="${1:?Usage: $0 <path-to-iso> <target-device e.g. /dev/sdX or /dev/diskN>}"
TARGET="${2:?Usage: $0 <path-to-iso> <target-device e.g. /dev/sdX or /dev/diskN>}"

[[ -f "$ISO" ]] || { echo "ERROR: ISO file not found: $ISO" >&2; exit 1; }

OS="$(uname -s)"

echo "== Current block devices =="
if [[ "$OS" == "Darwin" ]]; then
  diskutil list
else
  lsblk -o NAME,SIZE,MODEL,TRAN,MOUNTPOINTS
fi

echo
echo "About to ERASE ${TARGET} and write ${ISO} to it. ALL DATA ON ${TARGET} WILL BE LOST."
read -r -p "Type the device name again to confirm (${TARGET}): " confirm
[[ "$confirm" == "$TARGET" ]] || { echo "Confirmation did not match, aborted."; exit 1; }

if [[ "$OS" == "Darwin" ]]; then
  RAW_TARGET="${TARGET/\/dev\/disk/\/dev\/rdisk}"
  echo "==> Unmounting ${TARGET}"
  diskutil unmountDisk "$TARGET"
  echo "==> Writing image (this can take several minutes, no progress bar on macOS's dd)"
  sudo dd if="$ISO" of="$RAW_TARGET" bs=4m
  sync
  diskutil eject "$TARGET"
else
  echo "==> Writing image with progress"
  sudo dd if="$ISO" of="$TARGET" bs=4M status=progress conv=fsync
  sync
fi

echo "Done. Safely remove the USB stick and plug it into the mini PC."
