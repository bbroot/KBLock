import KeyboardShortcuts
import SwiftUI

struct ShortcutsSettingsPane: View {
    @Environment(AppState.self) private var state

    var body: some View {
        Form {
            Section {
                KeyboardShortcuts.Recorder("Toggle lock", name: .toggleLock)
            } header: {
                Text("Global shortcuts")
            } footer: {
                SectionFooter("Works anywhere. Prefer a Command- or Control-based combination.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle(state.loc("Shortcuts"))
    }
}
