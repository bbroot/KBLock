import LockIMEKit
import SwiftUI

@main
struct LockIMEApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    private var appState: AppState { delegate.appState }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .localized(with: appState)
        } label: {
            // The mascot is the state: hugging the keyboard = locked,
            // snacking on bamboo = unlocked. Monochrome template glyphs so the
            // system supplies the menu-bar tint (light/dark/active).
            Image(appState.isLocked ? "TrayLocked" : "TrayUnlocked")
        }
        .menuBarExtraStyle(.menu)

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
