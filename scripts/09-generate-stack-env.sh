#!/bin/bash
# Generates /opt/stack/.env with the values docker-compose.yml expects
# (RENDER_GID for iGPU access, TZ, PUID/PGID). Run once, and again any time
# you re-image the server (the render group's GID can differ per install).
#
# Usage: ./09-generate-stack-env.sh   (source scripts/config.env first)
set -euo pipefail

STACK_DIR="${STACK_DIR:-/opt/stack}"
TZ_VALUE="${TZ:-Europe/Madrid}"
PUID="${PUID:-1000}"
PGID="${PGID:-1000}"

RENDER_GID=$(getent group render | cut -d: -f3)
if [[ -z "$RENDER_GID" ]]; then
  echo "ERROR: no 'render' group found. Install the Intel GPU driver first (01-base-setup.sh) and reboot." >&2
  exit 1
fi

mkdir -p "$STACK_DIR"
cat > "$STACK_DIR/.env" <<EOF
TZ=${TZ_VALUE}
PUID=${PUID}
PGID=${PGID}
RENDER_GID=${RENDER_GID}
MEDIA_DIR=${MEDIA_DIR:-/srv/media}
EOF

echo "==> Wrote $STACK_DIR/.env:"
cat "$STACK_DIR/.env"
