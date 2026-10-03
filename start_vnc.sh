#!/bin/bash

echo "Stopping existing VNC servers..."
vncserver -kill :1 2>/dev/null
pkill -f Xtigervnc 2>/dev/null
sleep 1

echo "Starting VNC server..."
Xtigervnc :1 -geometry 2400x1080 -depth 24 -rfbport 5901 -rfbauth /home/droid/.config/tigervnc/passwd -SecurityTypes VncAuth -noreset -localhost no &
sleep 2

export DISPLAY=:1
~/.vnc/xstartup &
sleep 1

IP=$(hostname -I | awk '{print $1}')
echo -e "\033[1;36m======================================\033[0m"
echo -e "\033[1;32m✅ VNC Server Started!\033[0m"
echo -e "\033[1;33m📱 Connect VNC App to: $IP:5901\033[0m"
echo -e "\033[1;36m======================================\033[0m"
