import LockIMEKit
import SwiftUI

struct AppRulesSettingsPane: View {
    @Environment(AppState.self) private var state
    @State private var isPickingApp = false

    var body: some View {
        let defaultBinding = Binding<InputSourceID?>(
            get: { state.config.defaultSourceID },
            set: { state.setDefaultSource($0) }
        )

        Form {
            Section {
                Picker("Locked input source", selection: defaultBinding) {
                    Text("None").tag(InputSourceID?.none)
                    ForEach(state.availableSources) { source in
                        Text(source.localizedName).tag(InputSourceID?.some(source.id))
                    }
                }
            } header: {
                Text("Global default")
            } footer: {
                SectionFooter("Used whenever the frontmost app has no rule of its own.")
            }

            Section {
                if state.config.appRules.isEmpty {
                    emptyState
                } else {
                    ForEach(state.config.appRules) { rule in
                        AppRuleRow(rule: rule)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                Button {
                    isPickingApp = true
                } label: {
                    Label("Add App…", systemImage: "plus")
                }
            } header: {
                Text("Per-app rules")
            } footer: {
                SectionFooter("Pin a specific app to its own input source, ignore it, or fall back to the global default.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle(state.loc("App Rules"))
        .sheet(isPresented: $isPickingApp) {
            AppPickerSheet { app in
                withAnimation(DS.Motion.list) {
                    state.upsertRule(
                        AppRule(bundleID: app.bundleID, mode: .locked, lockedSourceID: state.config.defaultSourceID)
                    )
                }
            }
        }
    }

    private var emptyState: some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: "macwindow")
                .foregroundStyle(.secondary)
            Text("No app rules yet.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, DS.Spacing.xs)
    }
}

private struct AppRuleRow: View {
    @Environment(AppState.self) private var state
    let rule: AppRule

    var body: some View {
        HStack(spacing: DS.Spacing.lg) {
            AppRowLabel(bundleID: rule.bundleID)

            Spacer(minLength: DS.Spacing.md)

            Picker("", selection: modeBinding) {
                Text("Lock to").tag(AppRuleMode.locked)
                Text("Ignore").tag(AppRuleMode.ignored)
                Text("Use default").tag(AppRuleMode.useDefault)
            }
            .labelsHidden()
            .fixedSize()

            if rule.mode == .locked {
                Picker("", selection: sourceBinding) {
                    Text("Default").tag(InputSourceID?.none)
                    ForEach(state.availableSources) { source in
                        Text(source.localizedName).tag(InputSourceID?.some(source.id))
                    }
                }
                .labelsHidden()
                .fixedSize()
            }

            Button(role: .destructive) {
                withAnimation(DS.Motion.list) {
                    state.removeRule(bundleID: rule.bundleID)
                }
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("Remove rule")
        }
        .padding(.vertical, DS.Spacing.xxs)
    }

    private var modeBinding: Binding<AppRuleMode> {
        Binding(
            get: { rule.mode },
            set: { state.upsertRule(AppRule(bundleID: rule.bundleID, mode: $0, lockedSourceID: rule.lockedSourceID)) }
        )
    }

    private var sourceBinding: Binding<InputSourceID?> {
        Binding(
            get: { rule.lockedSourceID },
            set: { state.upsertRule(AppRule(bundleID: rule.bundleID, mode: rule.mode, lockedSourceID: $0)) }
        )
    }
}
