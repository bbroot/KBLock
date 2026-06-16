import AppKit
import KeyboardShortcuts
import KBLockKit
import SwiftUI

/// The menu-bar popover (`.menuBarExtraStyle(.window)`): a custom popover view
/// instead of a native NSMenu, so AppKit cannot auto-insert "About"/"Quit"
/// items in English. Every label uses `state.loc(...)` for proper localization.
struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 0) {
            let state = appState
            let pendingUpdate = state.updateController.pendingUpdateVersion
            let status = state.loc(state.isLocked ? "Locked" : "Unlocked")
            let shortcutText = state.toggleLockShortcut?.description

            // ── Status header ──────────────────────────────────────────
            HStack {
                Label {
                    Text(verbatim: status)
                } icon: {
                    Image(systemName: state.isLocked ? "lock.fill" : "lock.open.fill")
                }
                .disabled(true)

                if let text = shortcutText {
                    Spacer()
                    Text(text)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // ── Input sources ──────────────────────────────────────────
            ForEach(state.availableSources) { source in
                let isLockedTo = state.isLocked && state.config.defaultSourceID == source.id
                Button {
                    if isLockedTo {
                        state.setMasterEnabled(false)
                    } else {
                        state.lockToSource(source.id)
                    }
                } label: {
                    HStack {
                        Image(systemName: isLockedTo ? "checkmark" : "square")
                            .frame(width: 16)
                            .foregroundStyle(isLockedTo ? Color.accentColor : .clear)
                        Text(verbatim: source.localizedName)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }

            if !state.availableSources.isEmpty {
                Divider()
            }

            // ── Settings / Update / About ──────────────────────────────
            menuButton(loc: state.loc("Settings…"), symbol: "gearshape") {
                NSApp.activate(ignoringOtherApps: true)
                openSettings()
            }
            .keyboardShortcut(",", modifiers: .command)

            menuButton(
                loc: pendingUpdate != nil ? state.loc("Install Update…") : state.loc("Check for Updates…"),
                symbol: pendingUpdate != nil ? "arrow.down.circle.fill" : "arrow.down.circle"
            ) {
                state.checkForUpdates()
            }
            .keyboardShortcut("u", modifiers: .command)
            .disabled(!state.updateController.canCheckForUpdates)

            menuButton(loc: state.loc("About"), symbol: "info.circle") {
                state.showAbout()
            }

            Divider()

            menuButton(loc: state.loc("Quit"), symbol: "power") {
                state.quit()
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .frame(width: 150)
        .padding(.vertical, 6)
    }

    // MARK: - Helpers

    /// A plain left-aligned menu row with icon and label.
    private func menuButton(loc label: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .frame(width: 16)
                Text(verbatim: label)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}
