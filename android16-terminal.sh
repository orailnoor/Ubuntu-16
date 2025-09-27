#!/usr/bin/env bash
# Pretty installer: Chromium + wget + VS Code + optional GitHub debs (Clash Verge, Bilibili) + Pi-Apps
# Safe on Debian/Ubuntu; auto-detects arch; robust .deb installation.

set -euo pipefail

step() { printf "\n\033[1;36m==> %s\033[0m\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*\n"; }
die()  { printf "\033[1;31m[ERROR]\033[0m %s\n" "$*\n"; exit 1; }

command -v sudo >/dev/null || die "sudo is required."
sudo -v || die "Cannot obtain sudo credentials."

ARCH="$(dpkg --print-architecture)"   # amd64/arm64/armhf/etc
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

step "Updating APT and installing prerequisites"
sudo apt-get update
sudo apt-get install -y curl wget jq apt-transport-https ca-certificates gnupg lsb-release

# --- Chromium (package name differs across distros) ---
step "Installing Chromium browser"
if apt-cache policy chromium | grep -q Candidate; then
  sudo apt-get install -y chromium
elif apt-cache policy chromium-browser | grep -q Candidate; then
  sudo apt-get install -y chromium-browser
else
  warn "Chromium package not found in your repos."
fi

# --- VS Code (Microsoft repo) ---
step "Installing VS Code"
MS_KEYRING="/usr/share/keyrings/packages.microsoft.gpg"
echo "Adding Microsoft repo..."
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee "$MS_KEYRING" >/dev/null
echo "deb [arch=${ARCH} signed-by=${MS_KEYRING}] https://packages.microsoft.com/repos/code stable main" | \
  sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
sudo apt-get update
sudo apt-get install -y code

# --- Helper: install a .deb robustly ---
install_deb() {
  local deb="$1"
  sudo dpkg -i "$deb" || sudo apt-get -f install -y
}

# --- Helper: fetch latest GitHub release asset URL matching a regex pattern ---
github_latest_asset_url() {
  local repo="$1" pattern="$2"
  curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" \
    | jq -r --arg pat "$pattern" '.assets[]?.browser_download_url | select(test($pat))' \
    | head -n1
}

# --- Clash Verge (example repo: clash-verge-rev/clash-verge-rev) ---
# Adjust PATTERN if upstream names differ.
step "Installing Clash Verge (if available for ${ARCH})"
CV_REPO="${CV_REPO:-clash-verge-rev/clash-verge-rev}"
case "$ARCH" in
  amd64) CV_PATTERN='amd64.*\.deb$' ;;
  arm64) CV_PATTERN='arm64.*\.deb$' ;;
  *)     CV_PATTERN="${ARCH}.*\.deb$" ;;
esac
CV_URL="$(github_latest_asset_url "$CV_REPO" "$CV_PATTERN" || true)"
if [[ -n "${CV_URL:-}" ]]; then
  CV_DEB="$TMPDIR/clash-verge.deb"
  wget -qO "$CV_DEB" "$CV_URL"
  install_deb "$CV_DEB"
else
  warn "Clash Verge latest .deb not found for ${ARCH} (repo: $CV_REPO). Skipping."
fi

# --- Bilibili Linux client (set to a repo that publishes .deb; adjust as needed) ---
step "Installing Bilibili Linux client (if available for ${ARCH})"
BB_REPO="${BB_REPO:-itorr/bilibili-linux}"   # <-- change to your preferred repo if different
case "$ARCH" in
  amd64) BB_PATTERN='amd64.*\.deb$' ;;
  arm64) BB_PATTERN='arm64.*\.deb$' ;;
  *)     BB_PATTERN="${ARCH}.*\.deb$" ;;
esac
BB_URL="$(github_latest_asset_url "$BB_REPO" "$BB_PATTERN" || true)"
if [[ -n "${BB_URL:-}" ]]; then
  BB_DEB="$TMPDIR/bilibili.deb"
  wget -qO "$BB_DEB" "$BB_URL"
  install_deb "$BB_DEB"
else
  warn "Bilibili .deb not found for ${ARCH} (repo: $BB_REPO). Skipping."
fi

# --- Pi-Apps (optional; mostly for Raspberry Pi OS, but leaving here if desired) ---
step "Installing Pi-Apps (optional)"
if ! command -v pi-apps >/dev/null 2>&1; then
  wget -qO- https://raw.githubusercontent.com/Botspot/pi-apps/master/install | bash || warn "Pi-Apps install failed or not applicable."
fi

step "Cleanup"
sudo apt-get -y autoremove
sudo apt-get -y clean

echo
echo "All done."
