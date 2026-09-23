#!/bin/bash
# Shares $MEDIA_DIR over Samba so you can drag files onto the server from
# your desktop.
#
# Usage: ./06-setup-samba.sh   (source scripts/config.env first)
set -euo pipefail

MEDIA_DIR="${MEDIA_DIR:-/srv/media}"
SERVER_USER="${SERVER_USER:-$USER}"

echo "==> Installing Samba"
sudo apt install -y samba

if ! sudo grep -q "^\[media\]" /etc/samba/smb.conf 2>/dev/null; then
  echo "==> Appending the [media] share to /etc/samba/smb.conf"
  sudo tee -a /etc/samba/smb.conf > /dev/null <<EOF

[media]
   path = ${MEDIA_DIR}
   browseable = yes
   read only = no
   valid users = ${SERVER_USER}
   force user = ${SERVER_USER}
   create mask = 0664
   directory mask = 0775
EOF
else
  echo "[media] share already present in smb.conf, skipping"
fi

echo "==> Checking the config"
testparm -s

echo "==> Set the Samba password for ${SERVER_USER} (separate from the Linux login password)"
sudo smbpasswd -a "${SERVER_USER}"

sudo systemctl restart smbd

cat <<EOF

==> Samba share ready: \\\\<server-ip>\\media

  Windows : File Explorer -> Map network drive -> \\\\<server-ip>\\media
  macOS   : Finder -> Go -> Connect to Server (Cmd+K) -> smb://<server-ip>/media
  Linux   : file manager address bar -> smb://<server-ip>/media
EOF
