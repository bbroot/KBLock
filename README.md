# KBLock — Keep your keyboard locked.

Fix your macOS input source. No more typing Chinese in terminals.

A macOS menu-bar utility that pins your keyboard input source, so it never jumps between Chinese and English at the wrong moment.

## Features

- **Global lock**: Pin to one input source system-wide.
- **Per-app rules**: Auto-lock to a specific source when a particular app is frontmost (Terminal, VS Code → English; WeChat → Chinese).
- **Smart suggestions**: Learns which apps use which sources and suggests rules.
- **iCloud sync** (beta): Your rules on every Mac.
- **Usage statistics**: See how much you use each input source, per app.
- **Lightweight**: Built with SwiftUI, runs as a menu-bar app.

## Requirements

- macOS 14 Sonoma or later
- Apple Silicon or Intel (universal binary)

## Install

Download the latest release from the [Releases](https://github.com/bbroot/KBLock/releases/latest) page. Drag KBLock.app to your Applications folder.

First launch → click the keyboard icon in your menu bar → grant Accessibility access → pick your target input source.

## Build from source

```bash
git clone https://github.com/bbroot/KBLock.git
cd KBLock

brew install xcodegen
make run
```

## Architecture

- **KBLockKit** (dynamic framework) — pure, unit-tested logic using only system frameworks.
- **KBLock** (app) — `@main`, SwiftUI UI, design system, delegate layer.

## License

MIT
