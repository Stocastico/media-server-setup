#!/bin/bash
# Run this on your PC (NOT on the server) to switch from password to
# key-based SSH login. Requires the server to be reachable and that you
# can still log in with a password once.
#
# Usage: ./02-setup-ssh-keys.sh stefano 192.168.1.10
set -euo pipefail

SERVER_USER="${1:?Usage: $0 <server_user> <server_host_or_ip>}"
SERVER_HOST="${2:?Usage: $0 <server_user> <server_host_or_ip>}"

if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
  echo "==> No ed25519 key found, generating one (accept the defaults, a passphrase is optional)"
  ssh-keygen -t ed25519
else
  echo "==> Reusing existing key at ~/.ssh/id_ed25519"
fi

echo "==> Copying the public key to ${SERVER_USER}@${SERVER_HOST} (you'll be asked for the account password once)"
ssh-copy-id "${SERVER_USER}@${SERVER_HOST}"

echo "==> Testing key-based login"
ssh -o PasswordAuthentication=no "${SERVER_USER}@${SERVER_HOST}" 'echo "Key login OK as $(whoami)@$(hostname)"'

cat <<EOF

==> Key-based login works.

Now disable password logins ON THE SERVER (keep this terminal open, and
test a NEW connection in a second terminal before closing this one):

  ssh ${SERVER_USER}@${SERVER_HOST}
  echo 'PasswordAuthentication no' | sudo tee /etc/ssh/sshd_config.d/10-no-passwords.conf
  sudo systemctl restart ssh
EOF
