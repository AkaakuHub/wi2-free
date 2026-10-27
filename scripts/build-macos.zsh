#!/bin/zsh
set -euo pipefail

swift build -c release --disable-index-store --arch arm64 --package-path macos/Wi2Agent
bin_path="$(swift build -c release --disable-index-store --arch arm64 --package-path macos/Wi2Agent --show-bin-path)/wi2-agent"
app_path="macos/Wi2Agent/.build/Wi2Agent.app"
mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"
cp "$bin_path" "$app_path/Contents/MacOS/wi2-agent"
cp macos/Wi2Agent/Info.plist "$app_path/Contents/Info.plist"
cp macos/Wi2Agent/Resources/AppIcon.icns "$app_path/Contents/Resources/AppIcon.icns"
codesign --force --sign - --identifier "app.wi2-agent" "$app_path"
codesign --verify --strict "$app_path"
version="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$app_path/Contents/Info.plist")"
pkgbuild --component "$app_path" --install-location /Applications \
  --identifier "app.wi2-agent" --version "$version" \
  macos/Wi2Agent/.build/Wi2Agent-macos-arm64.pkg
