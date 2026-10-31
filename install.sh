#!/usr/bin/env bash
# KDE Connect + Scrcpy Integration Installer
# Author: Mahmudjon Murodov
set -euo pipefail

echo "🚀 Starting KDE Connect + Scrcpy Integration Setup..."

# 1. Check dependencies
echo "🔍 Checking dependencies..."
for cmd in scrcpy adb kdeconnect-cli; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "❌ $cmd not found! Please install it first." >&2
        exit 1
    fi
done

# 2. Create local bin and copy script
echo "📂 Setting up scripts..."
mkdir -p "$HOME/bin"
install -m 755 src/phone.sh "$HOME/bin/phone"

# 3. Add ~/bin to PATH if not present. Keep this idempotent so running the
#    installer twice does not append the same line twice.
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    echo "📝 Adding ~/bin to .bashrc..."
    printf '\n# Added by kdeconnect-scrcpy\nexport PATH="$HOME/bin:$PATH"\n' >> "$HOME/.bashrc"
    echo "Please restart your terminal or run 'source ~/.bashrc' after installation."
fi

# 4. Patch KDE Connect UI
echo "🎨 Patching KDE Connect UI..."
PLASMOID_DIR="$HOME/.local/share/plasma/plasmoids/org.kde.kdeconnect"
SYS_PLASMOID="/usr/share/plasma/plasmoids/org.kde.kdeconnect"

if [ ! -d "$SYS_PLASMOID" ]; then
    echo "❌ KDE Connect plasmoid not found at $SYS_PLASMOID" >&2
    echo "   Install the kdeconnect package first." >&2
    exit 1
fi

mkdir -p "$PLASMOID_DIR"
# Copy the system plasmoid only when there is no local copy yet. Copying over
# an existing one would discard local changes on every installer run.
if [ ! -f "$PLASMOID_DIR/metadata.json" ]; then
    cp -r "$SYS_PLASMOID/." "$PLASMOID_DIR/"
fi

TARGET="$PLASMOID_DIR/contents/ui/DeviceDelegate.qml"
if [ -f "$TARGET" ] && [ ! -f "$TARGET.orig" ]; then
    cp "$TARGET" "$TARGET.orig"
fi
install -m 644 src/DeviceDelegate.qml "$TARGET"

# 5. Add Desktop Entry
echo "🖥️ Adding Application Menu entry..."
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/phone-mirror.desktop" <<EOF
[Desktop Entry]
Name=Phone Mirror (scrcpy)
Exec=$HOME/bin/phone
Icon=phone
Terminal=false
Type=Application
Categories=Utility;RemoteAccess;
Comment=Mirror Android screen via scrcpy and KDE Connect
EOF

echo "✅ Done!"
echo "🔄 Restarting Plasma..."
if command -v systemctl >/dev/null 2>&1 && systemctl --user cat plasma-plasmashell.service >/dev/null 2>&1; then
    systemctl --user restart plasma-plasmashell.service
elif command -v kquitapp6 >/dev/null 2>&1 && command -v kstart >/dev/null 2>&1; then
    kquitapp6 plasmashell || true
    kstart plasmashell
else
    echo "⚠️  Could not restart Plasma automatically. Log out and back in."
fi

echo "🎉 Installation complete!"
echo "👉 Now click the KDE Connect icon in your system tray, click the 3 dots menu of your phone, and select 'Share Screen'."
