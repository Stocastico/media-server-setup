#!/bin/bash
# Installs Tailscale and brings up the interface. Requires opening a login
# URL in a browser once (printed to the terminal / shown by this script).
#
# Usage: ./07-install-tailscale.sh
set -euo pipefail

if command -v tailscale &>/dev/null; then
  echo "Tailscale is already installed ($(tailscale version | head -n1)), skipping install."
else
  echo "==> Installing Tailscale"
  curl -fsSL https://tailscale.com/install.sh | sh
fi

echo "==> Bringing the interface up"
echo "A login URL will be printed below: open it on any device and approve this machine."
sudo tailscale up

echo "==> This server's Tailscale IP:"
tailscale ip -4

cat <<'EOF'

==> Next steps (in the Tailscale admin console, https://login.tailscale.com/admin/machines):

  1. Machines -> mediaserver -> ... -> Disable key expiry
     (otherwise the server drops off the tailnet after 180 days)
  2. DNS tab -> make sure MagicDNS is enabled
     (the server becomes reachable as "mediaserver" from any tailnet device)
  3. Install the Tailscale app on your phone/laptop, sign in with the same
     account, and test from mobile data (not home Wi-Fi):
       http://mediaserver:8096   (Jellyfin)
       http://mediaserver:2283   (Immich)
  4. To share with family members who have their own Tailscale account:
     Machines -> mediaserver -> ... -> Share -> send the invite link.
EOF
