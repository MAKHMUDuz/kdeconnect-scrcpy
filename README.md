# KDE Connect + Scrcpy Integration

Add a "Share Screen" button directly into your KDE Connect system tray menu! 🚀

This project integrates [scrcpy](https://github.com/Genymobile/scrcpy) with [KDE Connect](https://kdeconnect.kde.org/) to allow one-click screen mirroring of your Android device.

## Features
- **One-click mirroring:** Added a "Share Screen" option to the KDE Connect menu.
- **Automatic IP detection:** Uses KDE Connect to find your phone's IP address.
- **High quality:** Optimized scrcpy settings (12M bitrate, 60 FPS).
- **Application Shortcut:** "Phone Mirror" entry in your application launcher.

## Requirements
- KDE Plasma 6
- `scrcpy`
- `android-tools` (for adb)
- `kdeconnect`

## Installation
1. Clone this repository:
   ```bash
   git clone https://github.com/MAKHMUDuz/kdeconnect-scrcpy.git
   cd kdeconnect-scrcpy
   ```
2. Run the installer:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

## Usage
1. Connect your phone via USB once and run `adb tcpip 5555`.
2. Ensure your phone is connected to KDE Connect.
3. Click the KDE Connect icon in your system tray.
4. Click the "overflow" (3 dots) menu next to your device.
5. Select **Share Screen**.

---
Developed by **Mahmudjon Murodov**
