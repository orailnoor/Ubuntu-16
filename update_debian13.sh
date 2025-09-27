#!/usr/bin/env bash
# In-place upgrade: Debian 12 (bookworm) -> Debian 13 (trixie)
# Run as NORMAL user with sudo.

set -euo pipefail

say() { printf "\n\033[1;32m==> %s\033[0m\n" "$*"; }
warn(){ printf "\033[1;33m[WARN]\033[0m %s\n" "$*\n"; }
die() { printf "\033[1;31m[ERROR]\033[0m %s\n" "$*\n"; exit 1; }

command -v sudo >/dev/null || die "sudo required."
sudo -v || die "Cannot get sudo."

# Detect current codename
CODENAME="$(. /etc/os-release; echo "${VERSION_CODENAME:-}")"
if [[ -z "$CODENAME" ]]; then
  die "Cannot detect current Debian codename."
fi

say "Current release: $CODENAME"
if [[ "$CODENAME" != "bookworm" ]]; then
  warn "This script expects Debian 12 (bookworm). Continuing anyway..."
fi

# Prep
say "Updating and upgrading current system"
sudo apt-get update
sudo apt-get -y full-upgrade

# Reboot required?
if [[ -f /var/run/reboot-required ]]; then
  warn "A reboot is required before proceeding. Reboot now and rerun this script."
  exit 1
fi

# Backup sources
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="/root/sources-backup-$TS"
say "Backing up APT sources to $BACKUP_DIR"
sudo mkdir -p "$BACKUP_DIR"
sudo cp -a /etc/apt/sources.list "$BACKUP_DIR"/ || true
sudo cp -a /etc/apt/sources.list.d "$BACKUP_DIR"/ || true

# Switch bookworm -> trixie in all sources
say "Updating APT sources: bookworm -> trixie"
sudo sed -i -E 's/\bbookworm\b/trixie/g' /etc/apt/sources.list || true
if [[ -d /etc/apt/sources.list.d ]]; then
  sudo find /etc/apt/sources.list.d -type f -name '*.list' -exec sed -i -E 's/\bbookworm\b/trixie/g' {} +
fi

# Make sure components include non-free-firmware (common on bookworm/trixie)
if ! grep -Eq 'non-free-firmware' /etc/apt/sources.list; then
  warn "Consider adding 'non-free-firmware' to your components if you need proprietary firmware."
fi

# Upgrade to trixie
say "Fetching trixie package lists"
sudo apt-get update

say "Full upgrade to trixie (this can take a while)"
sudo APT_LISTCHANGES_FRONTEND=none NEEDRESTART_MODE=a apt-get -y full-upgrade

# Cleanup
say "Autoremove and clean"
sudo apt-get -y autoremove
sudo apt-get -y clean

say "Upgrade completed. A reboot is recommended."
