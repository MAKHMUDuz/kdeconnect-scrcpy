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
   Use `./install.sh --no-restart` if you do not want the installer to restart
   Plasma, and `./install.sh --help` for the full option list.

## Uninstall
```bash
./install.sh --uninstall
```

The uninstaller restores the original `DeviceDelegate.qml` from the backup the
installer made, restores or removes `~/bin/phone`, removes the application
menu entry and the `PATH` line it added. The local plasmoid copy itself is
left in place because it may contain your own changes.

## Usage
1. Connect your phone via USB once and run `adb tcpip 5555`.
2. Ensure your phone is connected to KDE Connect.
3. Click the KDE Connect icon in your system tray.
4. Click the "overflow" (3 dots) menu next to your device.
5. Select **Share Screen**.

The applet resolves the helper script as `~/bin/phone` at runtime, so the
installation works for every user instead of one hard-coded home directory.

## Troubleshooting

- **Nothing happens when I click "Share Screen"**
  Check `~/.cache/kdeconnect-scrcpy.log`. The script writes the detected IP,
  the `adb connect` result and any `scrcpy` error there.
- **"No phone detected or not reachable"**
  Open KDE Connect and make sure the phone is paired and reachable. The
  script reads the IP from `kdeconnect-cli -a`.
- **`adb connect` fails**
  Enable Wireless debugging on the phone, or connect it over USB once and run
  `adb tcpip 5555`. Some ROMs use a different port; the script uses 5555.
- **The menu entry is missing after a KDE Connect update**
  Re-run `./install.sh`. The installer keeps a backup of the original file at
  `DeviceDelegate.qml.orig` and re-applies the patch.

---
Developed by **Mahmudjon Murodov**
