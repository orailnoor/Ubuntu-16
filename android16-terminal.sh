#!/bin/bash

# ==============================================================================
# Android 16 AVF -- Debian LXQt Desktop Installer
#
# Provisions a lightweight LXQt desktop environment inside the Android 16
# Virtualization Framework Terminal app, with TigerVNC and SSH remote access.
#
# Tested on: Pixel 8 (Android 16/17), Debian 13 (Trixie)
# ==============================================================================

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
TARGET_USER=$(whoami)

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Helpers ---
info()   { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()   { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()  { echo -e "${RED}[ERROR]${NC} $1"; }
banner() { echo -e "\n${BLUE}============================================================${NC}"; echo -e "${BLUE} $1${NC}"; echo -e "${BLUE}============================================================${NC}"; }

# --- Root check ---
if [ "$(id -u)" -eq 0 ]; then
    error "Do not run this script as root. Run as a regular user; sudo will be requested when needed."
    exit 1
fi

# --- Confirmation ---
confirm_install() {
    clear
    banner "Android AVF -- Debian LXQt Desktop Installer"
    echo ""
    echo "  The following will be configured on this system:"
    echo ""
    echo "    - User:    $TARGET_USER"
    echo "    - Desktop: LXQt"
    echo "    - SSH:     Port 22"
    echo "    - VNC:     Port 5901 (Display :1)"
    echo "    - Swap:    2GB (persistent)"
    echo ""
    read -p "  Do you want to continue? (y/n): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        info "Installation cancelled."
        exit 0
    fi
}

# --- Step 1: Fix and update package manager ---
prepare_system() {
    banner "Preparing system"

    # Clear potentially corrupted package lists (common on fresh AVF VMs)
    info "Clearing package list cache..."
    sudo rm -rf /var/lib/apt/lists/*

    info "Updating package lists..."
    sudo apt-get update -y

    info "Upgrading installed packages..."
    sudo apt-get upgrade -y

    # Ensure UTF-8 locale
    if ! locale 2>/dev/null | grep -q "UTF-8"; then
        info "Configuring UTF-8 locale..."
        sudo apt-get install -y locales
        sudo sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen
        sudo locale-gen en_US.UTF-8
        sudo update-locale LANG=en_US.UTF-8
    else
        info "UTF-8 locale already configured."
    fi
}

# --- Step 2: Configure SSH ---
setup_ssh() {
    banner "Configuring SSH"

    sudo apt-get install -y openssh-server

    # Enable password authentication
    if ! sudo grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config; then
        echo "PasswordAuthentication yes" | sudo tee -a /etc/ssh/sshd_config > /dev/null
    fi

    sudo systemctl restart sshd
    info "SSH configured on port 22."
}

# --- Step 3: Install LXQt desktop ---
install_desktop() {
    banner "Installing LXQt desktop environment"
    sudo apt-get install -y lxqt-core qterminal dbus-x11
    info "LXQt desktop installed."
}

# --- Step 4: Configure swap memory ---
setup_swap() {
    banner "Configuring swap memory"

    if [ -f /swapfile ]; then
        info "Swap file already exists, skipping."
        return
    fi

    info "Creating 2GB swap file..."
    sudo dd if=/dev/zero of=/swapfile bs=1M count=2048 status=progress
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile

    # Make persistent across reboots
    if ! grep -q '/swapfile' /etc/fstab; then
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    fi

    info "2GB swap configured and persisted."
}

# --- Step 5: Install and configure TigerVNC ---
setup_vnc() {
    banner "Configuring TigerVNC"

    sudo apt-get install -y tigervnc-standalone-server tigervnc-common

    info "Set a password for VNC (minimum 6 characters):"
    vncpasswd

    # Create X11 socket directory
    sudo mkdir -p /tmp/.X11-unix
    sudo chmod 1777 /tmp/.X11-unix

    # Write VNC config
    mkdir -p ~/.vnc
    cat > ~/.vnc/config << 'VNCCONF'
session=lxqt
geometry=2400x1080
localhost=no
alwaysshared
SecurityTypes=VncAuth
VNCCONF

    # Write xstartup for LXQt
    cat > ~/.vnc/xstartup << 'XSTARTUP'
#!/bin/sh
export XDG_SESSION_TYPE=x11
export GDK_BACKEND=x11
exec dbus-run-session startlxqt
XSTARTUP
    chmod +x ~/.vnc/xstartup

    # Register VNC user
    echo ":1=$TARGET_USER" | sudo tee /etc/tigervnc/vncserver.users > /dev/null

    # Enable and start the service
    sudo systemctl daemon-reload
    sudo systemctl enable tigervncserver@:1.service
    sudo systemctl start tigervncserver@:1.service

    info "TigerVNC configured on port 5901."
}

# --- Step 6: Deploy helper scripts ---
deploy_scripts() {
    banner "Deploying helper scripts"

    # start_vnc.sh -- kills stale processes and starts a fresh VNC server
    cat > ~/start_vnc.sh << 'STARTVNC'
#!/bin/bash
echo "Stopping existing VNC processes..."
vncserver -kill :1 2>/dev/null
pkill -f Xtigervnc 2>/dev/null
sleep 1

# Activate swap if not already active
if ! swapon --show | grep -q /swapfile; then
    sudo swapon /swapfile 2>/dev/null
fi

echo "Starting VNC server on :1..."
vncserver :1

IP=$(hostname -I | awk '{print $1}')
echo ""
echo "======================================"
echo "  VNC Server Running"
echo "  Connect to: $IP:5901"
echo "  Or locally: 127.0.0.1:5901"
echo "======================================"
STARTVNC
    chmod +x ~/start_vnc.sh

    info "Helper scripts deployed to ~/start_vnc.sh"
}

# --- Step 7: Summary ---
final_summary() {
    IP_ADDR=$(hostname -I | awk '{print $1}')
    clear
    banner "Installation Complete"
    echo ""
    echo "  You can now connect to this machine:"
    echo ""
    echo -e "  ${YELLOW}SSH:${NC}"
    echo "    ssh $TARGET_USER@$IP_ADDR"
    echo ""
    echo -e "  ${YELLOW}VNC (Graphical Desktop):${NC}"
    echo "    Address: $IP_ADDR:5901"
    echo "    Or locally on this device: 127.0.0.1:5901"
    echo ""
    echo -e "  ${YELLOW}From a PC via ADB:${NC}"
    echo "    adb forward tcp:5901 tcp:5901"
    echo "    Then connect to: 127.0.0.1:5901"
    echo ""
    echo "  If the VM reboots, run: ~/start_vnc.sh"
    echo ""
}

# --- Main ---
main() {
    confirm_install
    prepare_system
    setup_ssh
    install_desktop
    setup_swap
    setup_vnc
    deploy_scripts
    final_summary
}

main
