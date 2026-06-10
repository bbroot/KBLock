import AppKit
import LockIMEKit
import SwiftUI

/// Per-URL rules, gated behind the Accessibility-powered "enhanced mode". Rules
/// can only be edited once enhanced mode is enabled (which itself needs the
/// Accessibility permission).
struct URLRulesSettingsPane: View {
    @Environment(AppState.self) private var state

    @State private var newHost = ""
    @State private var newSourceID: InputSourceID?

    var body: some View {
        let enhancedBinding = Binding(
            get: { state.config.enhancedModeEnabled },
            set: { state.setEnhancedMode($0) }
        )

        Form {
            Section {
                Toggle("Enhanced mode (per-URL rules)", isOn: enhancedBinding)
                    .disabled(!state.accessibilityGranted)

                if !state.accessibilityGranted {
                    GrantAccessibilityButton()
                }
            } header: {
                Text("Enhanced mode")
            } footer: {
                SectionFooter("Enhanced mode reads the active browser URL via Accessibility to apply per-URL rules. The core lock needs no permissions.")
            }

            Section {
                if state.config.enhancedModeEnabled {
                    if state.config.urlRules.isEmpty {
                        emptyState
                    } else {
                        ForEach(state.config.urlRules) { rule in
                            URLRuleRow(rule: rule)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    addRow
                } else {
                    HStack(spacing: DS.Spacing.md) {
                        Image(systemName: "lock")
                            .foregroundStyle(.secondary)
                        Text("Enable enhanced mode to add per-URL rules.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, DS.Spacing.xxs)
                }
            } header: {
                Text("URL rules")
            } footer: {
                SectionFooter("Per-URL rules work in Safari and Chromium-based browsers (Chrome, Edge, Brave, Arc, Vivaldi, Opera). Firefox is not supported, because it does not expose the active tab's URL through the macOS Accessibility API.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle(state.loc("URL Rules"))
        .onAppear { state.refreshAccessibilityStatus() }
        .onDisappear { state.stopAccessibilityWatch() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            state.refreshAccessibilityStatus()
        }
    }

    private var emptyState: some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: "globe")
                .foregroundStyle(.secondary)
            Text("No URL rules yet.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, DS.Spacing.xxs)
    }

    private var addRow: some View {
        HStack(spacing: DS.Spacing.md) {
            TextField("Host (e.g. github.com)", text: $newHost)
                .textFieldStyle(.roundedBorder)
            Picker("", selection: $newSourceID) {
                Text("Default").tag(InputSourceID?.none)
                ForEach(state.availableSources) { source in
                    Text(source.localizedName).tag(InputSourceID?.some(source.id))
                }
            }
            .labelsHidden()
            .fixedSize()
            Button("Add") {
                let host = newHost.trimmingCharacters(in: .whitespaces)
                guard !host.isEmpty, let sourceID = newSourceID ?? state.config.defaultSourceID else { return }
                withAnimation(DS.Motion.list) {
                    state.upsertURLRule(URLRule(hostPattern: host, lockedSourceID: sourceID))
                }
                newHost = ""
                newSourceID = nil
            }
            .disabled(
                newHost.trimmingCharacters(in: .whitespaces).isEmpty
                    || (newSourceID == nil && state.config.defaultSourceID == nil)
            )
        }
    }
}

/// Opens the Accessibility privacy pane with the floating drag helper. The
/// grant is detected by `AppState`, which closes the helper and enables the
/// toggle the instant access is allowed (the system sends no notification).
private struct GrantAccessibilityButton: View {
    @Environment(AppState.self) private var state
    @Environment(\.locale) private var locale

    var body: some View {
        Button {
            state.requestAccessibilityAccess(
                localeIdentifier: locale.identifier,
                suggestedAppURLs: [Bundle.main.bundleURL],
                sourceFrame: Self.clickSourceFrame()
            )
        } label: {
            Label("Grant Accessibility Access", systemImage: "arrow.right.circle.fill")
        }
    }

    /// Uses the click location so the helper panel flies out from the button.
    private static func clickSourceFrame() -> CGRect {
        let mouse = NSEvent.mouseLocation
        return CGRect(x: mouse.x - 16, y: mouse.y - 16, width: 32, height: 32)
    }
}

private struct URLRuleRow: View {
    @Environment(AppState.self) private var state
    let rule: URLRule

    var body: some View {
        HStack(spacing: DS.Spacing.lg) {
            Image(systemName: "globe")
                .foregroundStyle(.secondary)
            Text(rule.hostPattern)
            Spacer(minLength: DS.Spacing.md)
            Picker("", selection: sourceBinding) {
                ForEach(state.availableSources) { source in
                    Text(source.localizedName).tag(source.id)
                }
            }
            .labelsHidden()
            .fixedSize()
            Button(role: .destructive) {
                withAnimation(DS.Motion.list) {
                    state.removeURLRule(id: rule.id)
                }
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("Remove rule")
        }
        .padding(.vertical, DS.Spacing.xxs)
    }

    private var sourceBinding: Binding<InputSourceID> {
        Binding(
            get: { rule.lockedSourceID },
            set: { state.upsertURLRule(URLRule(id: rule.id, hostPattern: rule.hostPattern, lockedSourceID: $0)) }
        )
    }
}
