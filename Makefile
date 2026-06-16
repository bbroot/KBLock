SCHEME      := KBLock
CONFIG      ?= Debug
# We ship one app per architecture (no universal binaries — download size).
# `make build ARCH=x86_64` cross-builds the Intel app (via the generic
# destination — `arch=x86_64` is not a valid destination on Apple Silicon);
# the result runs locally under Rosetta. Tests always run on the host arch.
ARCH        ?= arm64
DERIVED     := build/DerivedData
ifeq ($(CONFIG),Debug)
APP_NAME    := KBLock Dev
else
APP_NAME    := KBLock
endif
ifeq ($(ARCH),arm64)
DEST        := platform=macOS,arch=arm64
ARCHFLAGS   := ARCHS=arm64
else
DEST        := generic/platform=macOS
ARCHFLAGS   := ARCHS=$(ARCH) ONLY_ACTIVE_ARCH=NO
endif
APP         := $(DERIVED)/Build/Products/$(CONFIG)/$(APP_NAME).app
DMG         := build/dmg/KBLock.dmg
XCB         := set -o pipefail && xcodebuild
PRETTY      := | cat

.PHONY: gen build run test archive dmg clean kill

## Regenerate the Xcode project from project.yml
gen:
	xcodegen generate

## Build the app (Debug by default; ARCH=x86_64 for the Intel app)
build: gen
	$(XCB) -scheme $(SCHEME) -configuration $(CONFIG) \
		-derivedDataPath $(DERIVED) -destination '$(DEST)' \
		$(ARCHFLAGS) build $(PRETTY)

## Build and launch the app
run: build
	@pkill -x "$(APP_NAME)" 2>/dev/null || true
	@i=0; while pgrep -x "$(APP_NAME)" >/dev/null && [ $$i -lt 50 ]; do sleep 0.1; i=$$((i+1)); done
	open "$(APP)"

## Run the unit tests (hardware-touching suites skipped)
test: gen
	$(XCB) -scheme $(SCHEME) -configuration $(CONFIG) \
		-derivedDataPath $(DERIVED) -destination '$(DEST)' test $(PRETTY)

## Run ALL tests including hardware suites (briefly switches the input source)
test-hw: gen
	@touch /tmp/kblock_hw_tests
	@$(XCB) -scheme $(SCHEME) -configuration $(CONFIG) \
		-derivedDataPath $(DERIVED) -destination '$(DEST)' test $(PRETTY); \
		status=$$?; rm -f /tmp/kblock_hw_tests; exit $$status

## Build a Release archive (Developer ID)
archive: gen
	$(XCB) -scheme $(SCHEME) -configuration Release \
		-derivedDataPath $(DERIVED) -destination 'generic/platform=macOS' \
		-archivePath build/KBLock.xcarchive archive $(PRETTY)

## Package the built app into a drag-to-install .dmg (CONFIG=Release for a
## release-config bundle; the image is unsigned/unnotarized — CI handles that)
dmg: build
	scripts/make-dmg.sh "$(APP)" "$(DMG)"

## Terminate a running instance
kill:
	@pkill -x "$(APP_NAME)" 2>/dev/null || true
## Remove generated project and build artifacts
clean:
	rm -rf build KBLock.xcodeproj
