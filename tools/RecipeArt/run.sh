#!/bin/bash
# Builds RecipeArt, wraps it in a real Mac app (Image Playground only draws for a proper foreground app) and opens it.
# Run from anywhere: tools/RecipeArt/run.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PKG="$ROOT/tools/RecipeArt"
swift build -c release --package-path "$PKG"
BIN="$(swift build -c release --package-path "$PKG" --show-bin-path)/RecipeArt"
APP="$PKG/.build/RecipeArt.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/RecipeArt"
cp "$PKG/Info.plist" "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"
echo "Opening Recipe Art — keep its window in front while it draws."
open -W "$APP" --args "$ROOT"
