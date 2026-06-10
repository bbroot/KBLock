# LockIME

<div align="center">

**English** · [简体中文](README.zh-CN.md)

[![Latest release](https://img.shields.io/github/v/release/oomol-lab/LockIME?sort=semver&color=3A5BD9)](https://github.com/oomol-lab/LockIME/releases/latest)
[![CI](https://img.shields.io/github/actions/workflow/status/oomol-lab/LockIME/ci.yml?branch=main&label=CI)](https://github.com/oomol-lab/LockIME/actions/workflows/ci.yml)
[![License: GPL-3.0](https://img.shields.io/github/license/oomol-lab/LockIME?color=3A5BD9)](LICENSE)
[![macOS 26+](https://img.shields.io/badge/macOS-26%2B%20Tahoe-000000?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white)](https://swift.org)

</div>

A macOS menu-bar app that **locks your keyboard input source**. Whenever you (or
another app) switch input methods, LockIME immediately switches back to the locked
one — globally, or per-frontmost-app, or (with the optional enhanced mode) per
browser URL.

> macOS 26 (Tahoe) · Apple silicon only · built with SwiftUI + Liquid Glass.

## Screenshots

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/settings-general-en-dark.png">
    <img alt="General settings" src="docs/images/settings-general-en-light.png" width="32%">
  </picture>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/settings-app-rules-en-dark.png">
    <img alt="Per-app rules" src="docs/images/settings-app-rules-en-light.png" width="32%">
  </picture>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/settings-url-rules-en-dark.png">
    <img alt="Per-URL rules" src="docs/images/settings-url-rules-en-light.png" width="32%">
  </picture>
</p>

## Features

- **Instant re-lock** — switches the active input source back the moment you (or
  another app) change it, globally or per-app.
- **Menu-bar control** — activate/deactivate, view the current source, and track
  the activation count from the menu bar.
- **Global toggle shortcut** — turn locking on or off with a configurable keyboard
  shortcut.
- **Launch at login** — starts automatically when you log in (off by default).
- **Light & dark mode** — a unified, system-native design language that adapts to
  light and dark appearance, plus a bespoke app icon. See
  [docs/DESIGN.md](docs/DESIGN.md).
- **Live language switching** — switch between 9 languages instantly, no restart.
- **24-hour activation log** — review what was switched, why, and for how long.
- **Auto-update** — stable and beta channels via Sparkle, with a custom update
  window.
- **No system permissions for core locking** — an optional Accessibility-gated
  enhanced mode unlocks finer-grained per-URL and focused-field rules.

## Design

LockIME follows a single design system (`Sources/LockIME/UI/DesignSystem.swift`):
semantic colors, system materials, and SF Symbols drive light/dark adaptation;
Liquid Glass is reserved for the floating/navigation layer only. The brand
"Lock Indigo" accent ships as an `AccentColor` asset. The full spec lives in
[docs/DESIGN.md](docs/DESIGN.md).

The app icon is generated programmatically (no design tool) — regenerate it with:

```sh
./scripts/make-appicon.sh   # renders the master via SwiftUI and rebuilds the appiconset
```

## Development

Requires Xcode 26+, macOS 26+, and [XcodeGen](https://github.com/yonaskolb/XcodeGen)
+ [xcbeautify](https://github.com/cpisciotta/xcbeautify) (`brew install xcodegen xcbeautify`).

```sh
make gen     # generate LockIME.xcodeproj from project.yml
make build   # build (Debug)
make run     # build & launch
make test    # run unit tests
make archive # Release archive (Developer ID)
```

The Xcode project is generated from `project.yml` and is not checked in.

Hardware-touching integration tests (real TIS switching) are excluded from
`make test`; run them with `make test-hw` (briefly changes the input source).

## Releasing

Dispatch-driven, notarized Developer ID releases with Sparkle auto-update over
**stable** and **beta** channels: run the Release workflow (Actions → Release)
and it computes the version from git tags, builds, and creates the tag and
GitHub Release automatically — never push a tag by hand. The beta channel is
the nightly build. See [docs/RELEASING.md](docs/RELEASING.md).

## Architecture

- **LockIMEKit** (static library) — pure, fully unit-tested logic using only system
  frameworks: lock engine, app monitor, rules, enhanced (Accessibility) observer,
  logging model, localization.
- **LockIME** (app) — `@main`, SwiftUI UI, the design system, and the thin
  integration shims for Sparkle, KeyboardShortcuts, PermissionFlow, and MarkdownUI.

## License

Copyright © 2026 Hangzhou Wumou Software Co., Ltd.
