#!/usr/bin/env bash
# Package a macOS .app into a distributable, drag-to-install .dmg.
#
# The image holds the app beside an /Applications symlink so it opens to the
# familiar "drag the app onto Applications" layout. Intentionally dependency-free
# (hdiutil only) so it behaves identically on a developer's machine and on the CI
# runners, which install nothing beyond xcodegen.
#
# Signing and notarization are deliberately NOT done here: CI signs and notarizes
# the resulting image as separate, auditable steps (see build-publish.yml), and
# local `make dmg` needs neither.
#
#   make-dmg.sh <app-path> <output-dmg> [volume-name]
set -euo pipefail

APP="${1:?usage: make-dmg.sh <app-path> <output-dmg> [volume-name]}"
OUT="${2:?usage: make-dmg.sh <app-path> <output-dmg> [volume-name]}"
VOL="${3:-$(basename "${APP%.app}")}"

[ -d "$APP" ] || { echo "make-dmg: app not found: $APP" >&2; exit 1; }

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

# Copy the bundle (ditto preserves symlinks, xattrs and the code signature) and
# drop an /Applications alias next to it for drag-to-install.
ditto "$APP" "$STAGE/$(basename "$APP")"
ln -s /Applications "$STAGE/Applications"

mkdir -p "$(dirname "$OUT")"
rm -f "$OUT"

hdiutil create \
	-volname "$VOL" \
	-srcfolder "$STAGE" \
	-fs HFS+ \
	-format UDZO \
	-ov -quiet \
	"$OUT"

echo "make-dmg: wrote $OUT"
