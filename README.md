# KDE Connect + Scrcpy Integration

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)
[![KDE Plasma 6](https://img.shields.io/badge/KDE-Plasma%206-blue?style=flat-square)](https://kde.org/plasma-desktop/)
[![scrcpy](https://img.shields.io/badge/scrcpy-%E2%89%A51.25-red?style=flat-square)](https://github.com/Genymobile/scrcpy)
[![Platform](https://img.shields.io/badge/platform-Linux-green?style=flat-square)](https://archlinux.org/)

Add a **"Share Screen"** button directly into your KDE Connect system tray menu! 🚀

This project integrates [scrcpy](https://github.com/Genymobile/scrcpy) with
[KDE Connect](https://kdeconnect.kde.org/) to allow one-click, high-quality
screen mirroring of your Android device over Wi-Fi — no cable, no typing IP
addresses every time.

## How it works

```
┌─────────────┐  1. discovers the phone's IP   ┌─────────────┐
│ KDE Plasma  │ ─────────────────────────────▶ │   Android   │
│ (applet)    │                                │  (Wi-Fi)    │
│             │  2. adb connect <IP>:5555      │             │
│ ~/bin/phone │ ─────────────────────────────▶ │             │
│             │  3. scrcpy opens the screen    │             │
└─────────────┘ ◀───────────────────────────── └─────────────┘
```

1. KDE Connect only **discovers the phone's IP address**.
2. The helper script (`~/bin/phone`) connects `adb` to that IP.
3. `scrcpy` mirrors the screen at 12 Mbit/s / 60 FPS.

> ⚠️ **Important:** Pairing the phone in KDE Connect is **not** the same as
> granting ADB permission. KDE Connect finds the IP; Android must separately
> authorize your computer through an ADB confirmation dialog. This is the
> single most common reason "Share Screen" does nothing.

## Features

- **One-click mirroring:** a "Share Screen" option in the KDE Connect menu.
- **Automatic IP detection:** reads the phone's IP from `kdeconnect-cli`.
- **High quality:** optimized scrcpy settings (12M bitrate, 60 FPS).
- **Application shortcut:** a "Phone Mirror" entry in your application launcher.
- **Safe install:** backs up the original KDE Connect QML file, uninstallable.

## Requirements

| Package | Purpose | Arch | Debian/Ubuntu | Fedora |
|---|---|---|---|---|
| KDE Plasma 6 | Tray applet | `plasma` | — | — |
| `kdeconnect` | Device discovery | `kdeconnect` | `kdeconnect` | `kdeconnectd` |
| `scrcpy` | Screen mirroring | `scrcpy` | `scrcpy` | `scrcpy` |
| `android-tools` | `adb` | `android-tools` | `adb`/`android-sdk-platform-tools-common` | `android-tools` |
| `android-udev` | USB permissions for adb (first setup) | `android-udev` | `android-sdk-platform-tools-common` | `android-tools` |

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

## Android phone setup (one time)

Before "Share Screen" can work, Android must allow ADB from your computer.

### Step 1 — Enable Developer options

1. **Settings → About phone** (or *About device*).
2. Tap **Build number** 7 times in a row.
3. "You are now a developer!" appears. Go back — **Developer options** is now
   inside **Settings → System** (or directly in the Settings list).

### Step 2 — Enable debugging

In **Settings → System → Developer options**, turn on:

- [ ] **USB debugging** — required for the classic 5555 method.
- [ ] **Wireless debugging** (Android 11+) — required for method B.
- [ ] *(optional)* **Stay awake** — screen stays on while mirroring.

> **Xiaomi / HyperOS (MIUI) users:** also enable **USB debugging (Security
> settings)** (and on some builds **Install via USB**). MIUI sometimes refuses
> both until a Mi account and a SIM card are present in the phone.

### Step 3 — Authorize the computer

The **first time** adb talks to the phone, Android shows a dialog:

> *"Allow USB debugging? / Allow wireless debugging on this device?"*
> The computer's RSA key fingerprint is shown. ✅ Check **"Always allow from
> this computer"** and tap **Allow**.

Without accepting this dialog adb shows the device as `unauthorized` (see the
table below).

## Connect the phone to ADB

Do this **once in a terminal** with the phone reachable. You do not have to
remember it afterwards — the tray button re-uses it every time.

### Method A — Classic, port 5555 (recommended, works on every Android)

1. **Connect the phone by USB** and verify the computer sees it:

   ```bash
   adb devices
   ```

   Expected output:

   ```
   List of devices attached
   b3e02a1c        device
   ```

   - `unauthorized` → accept the dialog from Step 3 above.
   - `no permissions` → install `android-udev` on Arch (or unplug/replug and
     accept), then `adb kill-server && adb devices`.

2. Switch adb to TCP/IP mode:

   ```bash
   adb tcpip 5555
   # restarting in TCP mode port: 5555
   ```

3. **Unplug the USB cable.** Find your phone's IP
   (*Settings → Wi-Fi → tap the network → IP address*, or just let KDE Connect
   show it), then:

   ```bash
   adb connect 192.168.1.140:5555
   # connected to 192.168.1.140:5555
   adb devices
   ```

   You should now see the phone listed **by IP**:

   ```
   List of devices attached
   192.168.1.140:5555    device
   ```

4. Done — the phone survives reboots on 5555 until you run `adb usb` or
   toggle USB debugging off.

### Method B — Android 11+ wireless debugging (random port)

Android 11 changed things: wireless debugging no longer uses a fixed port.
The pairing port is shown on the phone screen and **changes every time**; the
connect port is different from the pairing port and **changes after reboot**.

1. On the phone: **Settings → System → Developer options → Wireless debugging**
   → enable it.
2. Tap **"Pair device with pairing code"**. The screen shows
   `IP:PORT` and a 6-digit code — e.g. `192.168.1.140:43217`, code `123456`.
3. On the computer:

   ```bash
   adb pair 192.168.1.140:43217
   # Enter pairing code: 123456
   # Successfully paired to 192.168.1.140:43217
   ```

   (The DHCP IP must match the one shown on the phone. Re-open the pairing
   dialog if you wait too long — the code and port expire.)

4. Pairing is permanent, but the **connect port is different**. Go back to the
   **Wireless debugging** screen — the port shown under it (e.g.
   `192.168.1.140:37291`) is what you connect to:

   ```bash
   adb connect 192.168.1.140:37291
   ```

5. After each phone reboot the connect port changes: open the Wireless
   debugging screen again and update the port. Because the port is not fixed,
   tell the helper script about it (see the next section) or connect manually
   with `scrcpy --tcpip=IP:PORT`.

> Tip: `scrcpy` itself can do both steps in one line —
> `scrcpy --tcpip=192.168.1.140:37291`.
> If the USB cable is plugged in, plain `scrcpy --tcpip` even switches the
> phone to TCP/IP mode automatically.

## Choosing the port for the tray button

The helper tries the **classic port 5555** by default. For method-B phones
with a random port, either:

- **Config file (recommended for the tray button):**

  ```bash
  mkdir -p ~/.config/kdeconnect-scrcpy
  echo "37291" > ~/.config/kdeconnect-scrcpy/port
  ```

- **Environment variable:**

  ```bash
  ADB_PORT=37291 ~/bin/phone
  ```

Update the port after every phone reboot (method B only — method A users never
need this).

## Usage

1. Make sure the phone and computer are on the same network and the phone is
   connected in KDE Connect.
2. Click the **KDE Connect icon** in the system tray.
3. Click the **overflow (⋮) menu** next to your device.
4. Select **Share Screen**.

Your phone's screen opens in a scrcpy window. In addition, a **"Phone Mirror
(scrcpy)"** entry is available in your application launcher.

The applet resolves the helper script as `~/bin/phone` at runtime, so the
installation works for every user instead of one hard-coded home directory.

## Troubleshooting

Check the log first — every run, IP detection, `adb connect` result and scrcpy
errors are written there:

```bash
cat ~/.cache/kdeconnect-scrcpy.log
```

| Symptom | Cause and fix |
|---|---|
| `adb devices` shows `unauthorized` | Accept the RSA dialog on the phone (Step 3), tick "Always allow". Then `adb kill-server && adb devices`. |
| `adb devices` shows `offline` or `device missing` | `adb kill-server && adb start-server`; replug USB; toggle USB debugging off/on. |
| `no permissions` (USB) | Arch: install `android-udev`, log out/in, replug. |
| `cannot connect to 192.168.x.x:5555` | Never ran `adb tcpip 5555` over USB (Method A step 2), or phone left the Wi-Fi, or the router blocks device-to-device traffic — disable *client isolation* (AP isolation) and allow the port in your firewall (nftables). |
| `failed to authenticate` on Android 11+ | Pairing not completed — run `adb pair` with the code currently shown on the phone. |
| Works until phone reboot, then fails | Android 11+ random port changed — update `~/.config/kdeconnect-scrcpy/port`. |
| "No phone detected or not reachable" | KDE Connect has no reachable device — pair the phone in KDE Connect first (`kdeconnect-cli -a`). |
| "adb not found" / "scrcpy not found" | Install the packages from the requirements table. |
| Nothing happens when clicking "Share Screen" | Read the log file; it contains the detected IP, adb result and scrcpy error. |
| Menu entry missing after a KDE Connect update | Re-run `./install.sh`; it keeps a backup at `DeviceDelegate.qml.orig` and re-applies the patch. |
| Multiple phones connected, wrong one opens | IP is taken from the first reachable KDE Connect device. Disconnect the others or set the IP manually (see below). |

## Port reference

| Port | Purpose |
|---|---|
| **5555** | Classic ADB-over-TCP port (`adb tcpip 5555`). **This is the port used by default.** |
| 5037 | Local adb **server** port on your computer — never used to reach the phone. |
| `adb pair` port | Random 5-digit port shown on the phone during pairing (Android 11+). |
| `adb connect` port | Random 5-digit port shown under *Wireless debugging*; changes after reboot. |

To go back to USB-only: `adb disconnect`, then `adb usb` (USB cable needed).

## Uninstall

```bash
./install.sh --uninstall
```

The uninstaller restores the original `DeviceDelegate.qml` from the backup the
installer made, restores or removes `~/bin/phone`, removes the application
menu entry and the `PATH` line it added. The local plasmoid copy itself is
left in place because it may contain your own changes.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) — good first issues are labelled and
pull requests are welcome.

---

Developed by **Mahmudjon Murodov** · [MAKHMUDuz](https://github.com/MAKHMUDuz) · License: [MIT](LICENSE)
