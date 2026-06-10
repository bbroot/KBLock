#!/bin/bash
# make-appicon.sh — regenerate LockIME's AppIcon.appiconset from the committed
# raster master (scripts/appicon-master.png). Fully headless; no design tool
# required.
#
#   ./scripts/make-appicon.sh
#
# Normalizes the master to a 1024 full-bleed square, then downscales with sips
# into the 7 unique pixel sizes the macOS .appiconset needs
# (16/32/64/128/256/512/1024). Contents.json (committed) maps those into the 10
# required @1x/@2x slots.
#
# If the raster master is absent, falls back to rendering the legacy SwiftUI
# vector padlock (scripts/MakeIcon.swift).
set -euo pipefail
cd "$(dirname "$0")/.."

SET="Sources/LockIME/Assets.xcassets/AppIcon.appiconset"
TMP="/tmp/lockime-icon"
MASTER="scripts/appicon-master.png"

mkdir -p "$TMP"
if [[ -f "$MASTER" ]]; then
  echo "→ normalizing ${MASTER} to 1024×1024…"
  sips -s format png -z 1024 1024 "$MASTER" --out "$TMP/master.png" >/dev/null
else
  echo "→ rendering master via ImageRenderer…"
  swift scripts/MakeIcon.swift
fi

echo "→ downscaling into ${SET}…"
mkdir -p "$SET"
for sz in 16 32 64 128 256 512; do
  sips -s format png -z "$sz" "$sz" "$TMP/master.png" --out "$SET/icon_${sz}.png" >/dev/null
done
cp "$TMP/master.png" "$SET/icon_1024.png"

echo "✓ appiconset updated:"
ls -1 "$SET" | sed 's/^/   /'
