#!/usr/bin/env bash
# KDE Connect + Scrcpy Integration Installer
# Author: Mahmudjon Murodov
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PLASMOID_DIR="$HOME/.local/share/plasma/plasmoids/org.kde.kdeconnect"
SYS_PLASMOID="/usr/share/plasma/plasmoids/org.kde.kdeconnect"
TARGET="$PLASMOID_DIR/contents/ui/DeviceDelegate.qml"
BACKUP="$TARGET.orig"
HELPER="$HOME/bin/phone"
HELPER_BACKUP="$HELPER.orig"
DESKTOP_FILE="$HOME/.local/share/applications/phone-mirror.desktop"

UNINSTALL=0
RESTART=1

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTION]...

Install the KDE Connect "Share Screen" integration.

Options:
  --no-restart  Do not restart plasmashell after the change.
  --uninstall   Restore the original KDE Connect QML file and remove the helper.
  -h, --help    Show this help.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --uninstall) UNINSTALL=1 ;;
        --no-restart) RESTART=0 ;;
        -h|--help) usage; exit 0 ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

restart_plasma() {
    if [ "$RESTART" -eq 0 ]; then
        echo "⏭️  Skipping the Plasma restart (--no-restart)."
        return
    fi
    echo "🔄 Restarting Plasma..."
    if command -v systemctl >/dev/null 2>&1 && systemctl --user cat plasma-plasmashell.service >/dev/null 2>&1; then
        systemctl --user restart plasma-plasmashell.service
    elif command -v kquitapp6 >/dev/null 2>&1 && command -v kstart >/dev/null 2>&1; then
        kquitapp6 plasmashell || true
        kstart plasmashell
    else
        echo "⚠️  Could not restart Plasma automatically. Log out and back in."
    fi
}

if [ "$UNINSTALL" -eq 1 ]; then
    echo "🧹 Removing the KDE Connect + Scrcpy integration..."

    if [ -f "$HELPER_BACKUP" ]; then
        mv "$HELPER_BACKUP" "$HELPER"
        echo "Restored the previous ~/bin/phone."
    else
        rm -f "$HELPER"
    fi

    rm -f "$DESKTOP_FILE"

    if [ -f "$BACKUP" ]; then
        mv "$BACKUP" "$TARGET"
        echo "Restored the original DeviceDelegate.qml."
    else
        echo "No QML backup found; leaving the current DeviceDelegate.qml in place."
    fi

    # Remove the PATH block the installer added. Match the exact lines so a
    # user's own PATH setup is not touched.
    if [ -f "$HOME/.bashrc" ]; then
        tmp=$(mktemp)
        grep -vxF \
            -e '# Added by kdeconnect-scrcpy' \
            -e 'export PATH="$HOME/bin:$PATH"' \
            "$HOME/.bashrc" > "$tmp" || true
        mv "$tmp" "$HOME/.bashrc"
    fi

    restart_plasma
    echo "✅ Uninstalled. The plasmoid files copied from the system are left in place."
    exit 0
fi

echo "🚀 Starting KDE Connect + Scrcpy Integration Setup..."

# 1. Check dependencies
echo "🔍 Checking dependencies..."
for cmd in scrcpy adb kdeconnect-cli; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "❌ $cmd not found! Please install it first." >&2
        exit 1
    fi
done

# 2. Create local bin and copy script. Keep a backup if the user already had
#    a file at that path, so --uninstall can restore it.
echo "📂 Setting up scripts..."
mkdir -p "$HOME/bin"
if [ -f "$HELPER" ] && [ ! -f "$HELPER_BACKUP" ]; then
    cp "$HELPER" "$HELPER_BACKUP"
fi
install -m 755 "$SCRIPT_DIR/src/phone.sh" "$HELPER"

# 3. Add ~/bin to PATH if not present. Keep this idempotent so running the
#    installer twice does not append the same line twice.
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    echo "📝 Adding ~/bin to .bashrc..."
    printf '\n# Added by kdeconnect-scrcpy\nexport PATH="$HOME/bin:$PATH"\n' >> "$HOME/.bashrc"
    echo "Please restart your terminal or run 'source ~/.bashrc' after installation."
fi

# 4. Patch KDE Connect UI
echo "🎨 Patching KDE Connect UI..."

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

if [ -f "$TARGET" ] && [ ! -f "$BACKUP" ]; then
    cp "$TARGET" "$BACKUP"
fi
install -m 644 "$SCRIPT_DIR/src/DeviceDelegate.qml" "$TARGET"

# 5. Add Desktop Entry
echo "🖥️ Adding Application Menu entry..."
mkdir -p "$HOME/.local/share/applications"
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=Phone Mirror (scrcpy)
Exec=$HELPER
Icon=phone
Terminal=false
Type=Application
Categories=Utility;RemoteAccess;
Comment=Mirror Android screen via scrcpy and KDE Connect
EOF

restart_plasma

echo "✅ Done!"
echo "🎉 Installation complete!"
echo "👉 Now click the KDE Connect icon in your system tray, click the 3 dots menu of your phone, and select 'Share Screen'."
