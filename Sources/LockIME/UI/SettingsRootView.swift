import LockIMEKit
import SwiftUI

/// Root of the Settings window — a standard multi-pane macOS settings TabView,
/// the same shape as System Settings. Each pane is its own grouped `Form`.
///
/// Two bodies for one view: the `Tab` builder (and tab badges) is macOS 15+,
/// and the deployment floor is 14 — Sonoma falls back to the `.tabItem` API,
/// which draws the same settings tabs minus the Updates badge. Keep both in
/// sync when adding a pane.
struct SettingsRootView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        Group {
            if #available(macOS 15.0, *) {
                tabs
            } else {
                legacyTabs
            }
        }
        .scenePadding()
        .frame(minWidth: 680, idealWidth: 700, minHeight: 460)
    }

    @available(macOS 15.0, *)
    private var tabs: some View {
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
    }

    private var legacyTabs: some View {
        TabView {
            GeneralSettingsPane()
                .tabItem { Label("General", systemImage: "gearshape") }
            AppRulesSettingsPane()
                .tabItem { Label("App Rules", systemImage: "macwindow.on.rectangle") }
            URLRulesSettingsPane()
                .tabItem { Label("URL Rules", systemImage: "globe") }
            ShortcutsSettingsPane()
                .tabItem { Label("Shortcuts", systemImage: "command") }
            UpdatesSettingsPane()
                .tabItem { Label("Updates", systemImage: "arrow.down.circle") }
            ActivationLogPane()
                .tabItem { Label("Log", systemImage: "list.bullet.rectangle") }
        }
    }
}
