#!/bin/bash

# Get the first reachable IP from KDE Connect
IP=$(kdeconnect-cli -a --id-name-only | head -n1 | cut -d' ' -f1 | xargs -I{} kdeconnect-cli -d {} --list-available | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n1)

# Fallback: check all reachable devices if the above fails
if [ -z "$IP" ]; then
    IP=$(kdeconnect-cli -a | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n1)
fi

if [ -z "$IP" ]; then
    notify-send "KDE Connect" "No phone detected or not reachable."
    exit 1
fi

# Connect via ADB
adb connect "$IP:5555" >/dev/null 2>&1

# Wait a moment for connection to establish
sleep 1

# Launch scrcpy with high quality settings
scrcpy -s "$IP:5555" --video-bit-rate=12M --max-fps=60 --window-title="Phone Mirror ($IP)" || \
notify-send "Mirror Error" "Check if Wireless Debugging is enabled on your phone."
