#!/usr/bin/env bash
# android16-terminal.sh — English + GNOME + SSH:10022 + TigerVNC(:1, GNOME)
# Works both as a normal user (via sudo) and as root (no sudo needed).

set -euo pipefail

step() { printf "\n\033[1;32m==> %s\033[0m\n" "$*"; }
warn() { printf "\n\033[1;33m[WARN]\033[0m %s\n" "$*" >&2; }
die()  { printf "\n\033[1;31m[ERROR]\033[0m %s\n" "$*" >&2; exit 1; }

# Decide whether to use sudo
if [[ $EUID -eq 0 ]]; then
  SUDO=""
else
  if ! command -v sudo >/dev/null 2>&1; then
    die "sudo is required when not running as root. Either install sudo or run this script as root."
  fi
  SUDO="sudo"
  # Try to cache credentials; if it fails, explain clearly
  if ! $SUDO -v; then
    die "sudo authentication failed. Set a password for your user with 'passwd', ensure you are in the 'sudo' group, or run this script as root."
  fi
fi

USER_NAME="$(id -un)"
SSH_PORT="${SSH_PORT:-10022}"
VNC_DISPLAY="${VNC_DISPLAY:-:1}"
DISPLAY_NUM="${VNC_DISPLAY#:}"            # "1"
VNC_GEOMETRY="${VNC_GEOMETRY:-1920x1080}"

export DEBIAN_FRONTEND=noninteractive
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 LANGUAGE=en_US:en

# ---------- APT prep ----------
step "Updating APT and installing prerequisites"
$SUDO apt-get update
$SUDO apt-get install -y locales apt-transport-https ca-certificates curl gnupg

# ---------- Locale: force English ----------
step "Setting system locale to English (en_US.UTF-8)"
if ! grep -Eq '^[^#]*en_US\.UTF-8' /etc/locale.gen 2>/dev/null; then
  $SUDO sed -i -E 's/^#?\s*en_US\.UTF-8.*/en_US.UTF-8 UTF-8/' /etc/locale.gen
fi
$SUDO locale-gen en_US.UTF-8 || true
$SUDO update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 LANGUAGE=en_US:en

# ---------- Base upgrade ----------
step "Upgrading base packages"
$SUDO apt-get -y full-upgrade

# ---------- GNOME desktop ----------
step "Installing GNOME desktop (non-interactive)"
if apt-cache policy task-gnome-desktop | grep -q Candidate; then
  $SUDO apt-get install -y task-gnome-desktop
else
  $SUDO apt-get install -y tasksel
  $SUDO tasksel install gnome-desktop
fi
$SUDO apt-get install -y gnome-terminal gnome-system-monitor

# ---------- OpenSSH ----------
step "Installing and configuring OpenSSH (port ${SSH_PORT}, password auth enabled)"
$SUDO apt-get install -y openssh-server
$SUDO sed -i -E "s/^#?\s*Port .*/Port ${SSH_PORT}/" /etc/ssh/sshd_config
$SUDO sed -i -E 's/^#?\s*PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
$SUDO sed -i -E 's/^#?\s*PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
$SUDO systemctl enable ssh --now
$SUDO systemctl restart ssh

# ---------- TigerVNC ----------
step "Installing TigerVNC server"
$SUDO apt-get install -y tigervnc-standalone-server tigervnc-common
mkdir -p "${HOME}/.vnc"

cat > "${HOME}/.vnc/config" <<EOF
session=gnome
geometry=${VNC_GEOMETRY}
alwaysshared
localhost=no
EOF

# VNC password
if [[ ! -f "${HOME}/.vnc/passwd" ]]; then
  if [[ -n "${VNC_PASS:-}" ]]; then
    step "Setting VNC password from VNC_PASS"
    printenv VNC_PASS | vncpasswd -f > "${HOME}/.vnc/passwd"
    chmod 600 "${HOME}/.vnc/passwd"
  else
    step "No VNC_PASS provided. You will be prompted to set your VNC password."
    vncpasswd
  fi
fi

# Map display :1 -> current user
step "Enabling TigerVNC systemd service for display ${VNC_DISPLAY}"
$SUDO mkdir -p /etc/tigervnc
echo "${VNC_DISPLAY}=${USER_NAME}" | $SUDO tee /etc/tigervnc/vncserver.users >/dev/null

$SUDO systemctl daemon-reload || true
$SUDO systemctl enable "tigervncserver@${DISPLAY_NUM}.service"
$SUDO systemctl restart "tigervncserver@${DISPLAY_NUM}.service"

# ---------- Optional firewall ----------
if command -v ufw >/dev/null 2>&1; then
  step "UFW detected: allowing SSH ${SSH_PORT}/tcp and VNC $((5900 + DISPLAY_NUM))/tcp"
  $SUDO ufw allow "${SSH_PORT}/tcp" || true
  $SUDO ufw allow "$((5900 + DISPLAY_NUM))/tcp" || true
fi

# ---------- Summary ----------
IPV4="$(hostname -I 2>/dev/null | awk '{print $1}')"
VNC_PORT="$((5900 + DISPLAY_NUM))"

echo
echo "======================== SUMMARY ========================"
echo "Locale          : $LANG"
echo "Desktop         : GNOME"
echo "User            : ${USER_NAME}"
echo "SSH             : ssh ${USER_NAME}@${IPV4:-<your-ip>} -p ${SSH_PORT}"
echo "VNC             : ${IPV4:-<your-ip>}:${VNC_PORT}   (display ${VNC_DISPLAY})"
echo "VNC geometry    : ${VNC_GEOMETRY}"
echo "VNC config      : ${HOME}/.vnc/config"
echo "VNC service     : tigervncserver@${DISPLAY_NUM}.service"
echo "ADB port-forward: adb forward tcp:5901 tcp:5901  -> connect VNC to localhost:5901"
echo "Security note   : VNC is open (localhost=no). Restrict via firewall or tunnel over SSH."
echo "========================================================="
