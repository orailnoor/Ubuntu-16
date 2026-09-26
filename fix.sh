#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -y
sudo apt-get install -y dbus-x11 lxde-core lxterminal
sudo mkdir -p /tmp/.X11-unix
sudo chmod 1777 /tmp/.X11-unix
mkdir -p ~/.vnc
cat > ~/.vnc/config <<- EOF
session=LXDE
geometry=1920x1080
localhost=no
alwaysshared
SecurityTypes=VncAuth
EOF
rm -f ~/.vnc/xstartup
vncserver -kill :1 2>/dev/null
vncserver :1 -localhost no -SecurityTypes VncAuth
echo "======================================"
echo "FIX COMPLETED SUCCESSFULLY!"
echo "VNC SERVER IS RUNNING FOR LXDE!"
echo "OPEN REALVNC AND CONNECT TO 172.19.203.173:5901"
echo "======================================"
