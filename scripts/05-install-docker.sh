#!/bin/bash
# Installs Docker Engine + Compose plugin using Docker's official convenience
# script, adds the current user to the docker group, and caps container log
# growth.
#
# Usage: ./05-install-docker.sh
set -euo pipefail

if command -v docker &>/dev/null; then
  echo "Docker is already installed ($(docker --version)), skipping install."
else
  echo "==> Installing Docker"
  curl -fsSL https://get.docker.com | sudo sh
fi

echo "==> Adding $USER to the docker group"
sudo usermod -aG docker "$USER"

echo "==> Capping container log size (log-driver: local)"
echo '{ "log-driver": "local" }' | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker

cat <<'EOF'

==> Docker installed.

You must log out and back in (or run `newgrp docker`) for the group change
to apply, then verify with:

  docker run --rm hello-world
  docker compose version
EOF
