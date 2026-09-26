#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -y
sudo apt-get install -y task-xfce-desktop dbus-x11 xfonts-base
sudo mkdir -p /tmp/.X11-unix
sudo chmod 1777 /tmp/.X11-unix
mkdir -p ~/.vnc
cat > ~/.vnc/config <<- EOF
session=xfce4
geometry=1920x1080
localhost=no
alwaysshared
SecurityTypes=VncAuth
EOF
rm -f ~/.vnc/xstartup
vncserver -kill :1 2>/dev/null
vncserver :1 -localhost no -SecurityTypes VncAuth
IP_ADDR=$(hostname -I | awk '{print $1}')
echo "======================================"
echo "ULTIMATE FIX COMPLETED!"
echo "VNC SERVER IS RUNNING FOR XFCE!"
echo "YOUR IP ADDRESS IS: $IP_ADDR"
echo "CONNECT IN REALVNC TO: $IP_ADDR:5901"
echo "======================================"
