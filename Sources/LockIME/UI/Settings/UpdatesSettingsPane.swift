import LockIMEKit
import SwiftUI

struct UpdatesSettingsPane: View {
    @Environment(AppState.self) private var state
    @AppStorage("usesBetaChannel") private var usesBeta = false

    var body: some View {
        Form {
            Section {
                Picker("Update channel", selection: $usesBeta) {
                    Text("Stable").tag(false)
                    Text("Beta").tag(true)
                }
                .pickerStyle(.segmented)
                .onChange(of: usesBeta) { state.updateController.channelDidChange() }
            } header: {
                Text("Channel")
            } footer: {
                SectionFooter("Stable ships from tagged releases. Beta tracks the nightly build (built automatically around 01:00 UTC) — newer features, but less tested.")
            }

            if let version = state.updateController.pendingUpdateVersion {
                Section {
                    LabeledContent {
                        Button("Install Update…") { state.checkForUpdates() }
                            .buttonStyle(.borderedProminent)
                    } label: {
                        Label {
                            Text("Version \(version) is available")
                        } icon: {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundStyle(DS.Palette.accent)
                        }
                    }
                }
            }

            Section {
                let autoChecks = Binding(
                    get: { state.updateController.automaticallyChecksForUpdates },
                    set: { state.updateController.automaticallyChecksForUpdates = $0 }
                )
                Toggle("Automatically check for updates", isOn: autoChecks)

                LabeledContent("Last checked", value: lastCheckedDescription)

                Button("Check for Updates…") {
                    state.checkForUpdates()
                }
                .disabled(!state.updateController.canCheckForUpdates)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(state.loc("Updates"))
    }

    private var lastCheckedDescription: String {
        guard let date = state.updateController.lastCheckDate else {
            return state.loc("Never")
        }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}
