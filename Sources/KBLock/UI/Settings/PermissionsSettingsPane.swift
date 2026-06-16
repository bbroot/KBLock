import AppKit
import KBLockKit
import SwiftUI

/// The single home for KBLock's optional system permissions. Today that's just
/// Accessibility, which gates launcher/Spotlight detection; the feature panes
/// only carry a passive `AccessibilityRequiredNote` that routes here, so the
/// grant is requested in exactly one place.
struct PermissionsSettingsPane: View {
    @Environment(AppState.self) private var state

    var body: some View {
        Form {
            Section {
                if state.accessibilityGranted {
                    Label("Accessibility access granted", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                        Text("Grant once to unlock an optional feature:")
                        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                            FeatureBullet("Targeting launchers like Spotlight in app rules")
                        }
                    }
                    GrantAccessibilityButton()
                }
            } header: {
                Text("Accessibility")
            } footer: {
                SectionFooter("The core lock needs no permissions.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle(state.loc("Permissions"))
        // The watcher's abandon-stop lives on SettingsRootView (window close), so
        // switching tabs mid-grant doesn't kill detection; panes only reconcile
        // the shared status, which also recovers a grant the watcher missed.
        .onAppear { state.refreshAccessibilityStatus() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            state.refreshAccessibilityStatus()
        }
    }
}

/// One unlocked-feature line in the Accessibility section's rationale.
private struct FeatureBullet: View {
    private let text: LocalizedStringKey
    init(_ text: LocalizedStringKey) { self.text = text }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.sm) {
            Image(systemName: "checkmark")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(text)
                .foregroundStyle(.secondary)
        }
    }
}
