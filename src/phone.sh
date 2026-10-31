#!/usr/bin/env bash
# Share an Android screen through KDE Connect + scrcpy.
#
# The Plasma applet starts this script without a terminal, so every failure
# has to be visible somewhere. Keep a log in the user's cache directory and
# send a desktop notification when something goes wrong.
set -u

LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
LOG_FILE="$LOG_DIR/kdeconnect-scrcpy.log"
mkdir -p "$LOG_DIR"
exec >>"$LOG_FILE" 2>&1

log() {
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

notify_error() {
    log "ERROR: $*"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "KDE Connect" "$*"
    fi
}

# The applet's environment does not always inherit the user's PATH, so look
# in the usual install locations as well.
find_tool() {
    local name=$1
    if command -v "$name" >/dev/null 2>&1; then
        command -v "$name"
        return 0
    fi
    for candidate in "/usr/bin/$name" "/usr/local/bin/$name"; do
        if [ -x "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

ADB=$(find_tool adb) || {
    notify_error "adb not found. Install android-tools."
    exit 1
}
SCRCPY=$(find_tool scrcpy) || {
    notify_error "scrcpy not found. Install scrcpy."
    exit 1
}
KDECONNECT_CLI=$(find_tool kdeconnect-cli) || {
    notify_error "kdeconnect-cli not found. Install kdeconnect."
    exit 1
}

log "Starting screen mirror"

# `kdeconnect-cli -a` prints one line per reachable device, for example:
#   - Galaxy S21 5G: <id> on 192.168.1.140 via LAN (paired and reachable)
# The IP is part of that line, so no device-id round trip is needed.
IP=$("$KDECONNECT_CLI" -a 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n1)

if [ -z "$IP" ]; then
    notify_error "No phone detected or not reachable. Pair it in KDE Connect first."
    exit 1
fi

log "Phone IP: $IP"

# adb connect is idempotent. A failure is not fatal: the device may already
# be connected over USB, or the user may have set up a different port.
"$ADB" connect "$IP:5555" || log "adb connect failed; continuing"

sleep 1

"$SCRCPY" -s "$IP:5555" --video-bit-rate=12M --max-fps=60 \
    --window-title="Phone Mirror ($IP)" \
    || notify_error "Could not start scrcpy. Enable Wireless debugging / ADB over TCP on the phone."
