import KBLockKit
import SwiftUI

@main
struct KBLockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    private var appState: AppState { delegate.appState }

    var body: some Scene {
        // Use `.menuBarExtraStyle(.window)` (popover) instead of `.menu` to
        // avoid AppKit auto-inserting "About <AppName>" and "Quit <AppName>"
        // in English. The popover renders pure SwiftUI — every label comes
        // through `state.loc(...)`, so localization works without fight.
        MenuBarExtra {
            MenuBarView()
                .localized(with: appState)
                .modelContainer(appState.modelContainer)
        } label: {
            Image(appState.isLocked ? "TrayLocked" : "TrayUnlocked")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsRootView()
                .localized(with: appState)
                .modelContainer(appState.modelContainer)
        }
    }
}

private extension View {
    /// Inject the shared state plus the chosen locale, rebuilding the subtree
    /// on language change so every string re-resolves live (no restart).
    func localized(with appState: AppState) -> some View {
        environment(appState)
            .environment(\.locale, appState.locale)
            .id(appState.localeIdentifier)
    }
}
