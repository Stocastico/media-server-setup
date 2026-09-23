#!/bin/bash
# Sanity-checks that the Intel iGPU is visible and usable for hardware
# transcoding, both on the host and inside the running Jellyfin container.
#
# Usage: ./08-check-hw-accel.sh
set -euo pipefail

echo "== /dev/dri devices =="
ls -l /dev/dri || { echo "MISSING: no /dev/dri, the kernel driver isn't loaded. Reboot after 01-base-setup.sh, or check 'dmesg | grep -i i915'."; exit 1; }

echo
echo "== vainfo (host) =="
vainfo || echo "vainfo failed - intel-media-va-driver-non-free may not be installed."

echo
echo "== render group GID (must match RENDER_GID in /opt/stack/.env) =="
getent group render

if docker ps --format '{{.Names}}' | grep -qx jellyfin; then
  echo
  echo "== vainfo inside the jellyfin container =="
  docker exec -it jellyfin /usr/lib/jellyfin-ffmpeg/vainfo --display drm --device /dev/dri/renderD128 \
    || echo "Container vainfo failed - check devices:/group_add: in docker-compose.yml"
else
  echo
  echo "jellyfin container is not running, skipping the in-container check."
fi

echo
echo "== GuC/HuC firmware (needed for the Low-Power H.264/HEVC encoders) =="
sudo dmesg | grep -i -E 'guc|huc' || echo "No GuC/HuC lines found. If low-power encoding fails in Jellyfin, add" \
  "i915.enable_guc=3 to GRUB_CMDLINE_LINUX_DEFAULT in /etc/default/grub, then: sudo update-grub && sudo reboot"

cat <<'EOF'

== Live check while a video plays ==
Start a transcode in Jellyfin (play a file, gear icon -> Quality -> pick a
low bitrate), then in another terminal:

  sudo intel_gpu_top     # the "Video" bar should move; q to quit
EOF
