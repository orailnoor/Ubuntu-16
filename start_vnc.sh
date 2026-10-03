#!/bin/bash

# Restart VNC server after a VM reboot or crash.
# Automatically re-enables swap if it was lost during reboot.

echo "Stopping existing VNC processes..."
vncserver -kill :1 2>/dev/null
pkill -f Xtigervnc 2>/dev/null
sleep 1

# Re-activate swap if not already active
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
