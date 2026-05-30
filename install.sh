#!/bin/bash

# KDE Connect + Scrcpy Integration Installer
# Author: Mahmudjon Murodov

echo "🚀 Starting KDE Connect + Scrcpy Integration Setup..."

# 1. Check dependencies
echo "🔍 Checking dependencies..."
for cmd in scrcpy adb kdeconnect-cli; do
    if ! command -v $cmd &> /dev/null; then
        echo "❌ $cmd not found! Please install it first."
        exit 1
    fi
done

# 2. Create local bin and copy script
echo "📂 Setting up scripts..."
mkdir -p "$HOME/bin"
cp src/phone.sh "$HOME/bin/phone"
chmod +x "$HOME/bin/phone"

# 3. Add ~/bin to PATH if not present
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    echo "📝 Adding ~/bin to .bashrc..."
    echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
    echo "Please restart your terminal or run 'source ~/.bashrc' after installation."
fi

# 4. Patch KDE Connect UI
echo "🎨 Patching KDE Connect UI..."
PLASMOID_DIR="$HOME/.local/share/plasma/plasmoids/org.kde.kdeconnect"
SYS_PLASMOID="/usr/share/plasma/plasmoids/org.kde.kdeconnect"

mkdir -p "$PLASMOID_DIR"
cp -r "$SYS_PLASMOID/"* "$PLASMOID_DIR/"
cp src/DeviceDelegate.qml "$PLASMOID_DIR/contents/ui/DeviceDelegate.qml"

# 5. Add Desktop Entry
echo "🖥️ Adding Application Menu entry..."
mkdir -p "$HOME/.local/share/applications"
cat <<EOF > "$HOME/.local/share/applications/phone-mirror.desktop"
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
echo "🔄 Refreshing Plasma..."
killall plasmashell && kstart6 plasmashell &

echo "🎉 Installation complete!"
echo "👉 Now click the KDE Connect icon in your system tray, click the 3 dots menu of your phone, and select 'Share Screen'."
