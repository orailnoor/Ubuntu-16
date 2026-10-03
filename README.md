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

First, clone this repository directly inside your Android Terminal app, then run the installer:

```bash
git clone https://github.com/orailnoor/Ubuntu-16.git
cd Ubuntu-16
chmod +x ./android16-terminal.sh
./android16-terminal.sh
```

## Connecting via VNC

Once installed, you can connect from your host PC using ADB port forwarding:

1. Forward the VNC port:
   ```bash
   adb forward tcp:5901 tcp:5901
   ```
2. Open TigerVNC Viewer on your PC and connect to:
   ```
   127.0.0.1:5901
   ```

*Note: If the Android VM is suspended or reboots, you may need to restart the VNC service manually using the provided `start_vnc.sh` script.*
