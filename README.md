# Android 16 AVF Debian Desktop Environment

This repository provides an automated installation script to provision a complete, lightweight Debian 13 desktop environment within the Android 16 Virtualization Framework (AVF) Terminal application.

## Overview

The Android 16 Terminal app provisions a Virtual Machine with constrained memory (typically 1GB). This script automatically bypasses these constraints by configuring a persistent 2GB swap file and installing a highly optimized LXQt desktop environment.

**Features:**
- **Lightweight Desktop:** Installs LXQt for maximum performance on constrained AVF environments.
- **OOM Prevention:** Automatically provisions a 2GB swap file backed by UFS storage to allow installation and execution of heavy applications (e.g., VS Code).
- **Remote Access:** Configures SSH (Port 10022) and TigerVNC (TCP 5901) for direct access via ADB forwarding.
- **Bilingual Interface:** Supports English and Simplified Chinese installation menus.

## Device Compatibility

This setup requires a device supporting the **Android 16 Virtualization Framework (AVF)** with the official Terminal application. 
- **Supported Devices:** Pixel 8, Pixel 8 Pro, Pixel 8a, Pixel 9 series (running Android 16+ developer previews with AVF enabled).

## Installation

First, open the Terminal app and run the following commands to download and start the installer:

```bash
sudo apt update
sudo apt install -y curl
curl -O https://raw.githubusercontent.com/orailnoor/Ubuntu-16/main/android16-terminal.sh
chmod +x android16-terminal.sh
./android16-terminal.sh
```

## Connecting to the Desktop

You can connect to your desktop either locally directly on your phone, or remotely from a PC.

### Option A: Local Connection (On your Phone)

You can use a VNC viewer app on your phone to view the desktop locally without needing a PC.
1. Download **RealVNC Viewer** from the [Google Play Store](https://play.google.com/store/apps/details?id=com.realvnc.viewer.android).
2. Open the app and create a new connection.
3. Set the Address to: `127.0.0.1:5901`
4. Connect and enter the VNC password you set during installation.

### Option B: Remote Connection (From a PC)

If you want to view the desktop on a larger screen, you can connect from your host PC using ADB port forwarding over a USB cable:

1. Connect your phone to your PC and forward the VNC port:
   ```bash
   adb forward tcp:5901 tcp:5901
   ```
2. Open TigerVNC Viewer (or RealVNC) on your PC and connect to:
   ```
   127.0.0.1:5901
   ```

*Note: If the Android VM is suspended or reboots, you may need to restart the VNC service manually using the provided `start_vnc.sh` script.*
