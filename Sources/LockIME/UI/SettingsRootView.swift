import LockIMEKit
import SwiftUI

/// Root of the Settings window — a standard multi-pane macOS settings TabView,
/// the same shape as System Settings. Each pane is its own grouped `Form`.
struct SettingsRootView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        TabView {
            Tab("General", systemImage: "gearshape") {
                GeneralSettingsPane()
            }
            Tab("App Rules", systemImage: "macwindow.on.rectangle") {
                AppRulesSettingsPane()
            }
            Tab("URL Rules", systemImage: "globe") {
                URLRulesSettingsPane()
            }
            Tab("Shortcuts", systemImage: "command") {
                ShortcutsSettingsPane()
            }
            Tab("Updates", systemImage: "arrow.down.circle") {
                UpdatesSettingsPane()
            }
            .badge(state.updateController.pendingUpdateVersion != nil ? 1 : 0)
            Tab("Log", systemImage: "list.bullet.rectangle") {
                ActivationLogPane()
            }
        }
        .scenePadding()
        .frame(minWidth: 680, idealWidth: 700, minHeight: 460)
    }
}
