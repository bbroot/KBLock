import LockIMEKit
import SwiftData
import SwiftUI

struct ActivationLogPane: View {
    @Environment(AppState.self) private var state
    @Query private var entries: [ActivationLogEntry]

    init() {
        let cutoff = Date.now.addingTimeInterval(-LogStore.retention)
        _entries = Query(
            filter: #Predicate<ActivationLogEntry> { $0.timestamp > cutoff },
            sort: \ActivationLogEntry.timestamp,
            order: .reverse
        )
    }

    var body: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView(
                    "No activity yet",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Forced input-source switches from the last 24 hours appear here.")
                )
            } else {
                Table(entries) {
                    TableColumn("Time") { entry in
                        Text(entry.timestamp, format: .dateTime.hour().minute().second())
                            .monospacedDigit()
                    }
                    TableColumn("Input source") { entry in
                        Text(entry.inputSourceName)
                    }
                    TableColumn("Reason") { entry in
                        Text(Self.reasonLabel(entry.reasonRaw))
                    }
                    TableColumn("Duration") { entry in
                        (Text(entry.durationMs, format: .number.precision(.fractionLength(1)))
                            + Text(verbatim: " ms"))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(state.loc("Activation Log"))
        .onAppear { state.purgeLog() }
    }

    static func reasonLabel(_ raw: String) -> LocalizedStringKey {
        switch ActivationReason(rawValue: raw) {
        case .revertedSwitch: "Reverted switch"
        case .appActivated: "App activated"
        case .urlMatched: "URL matched"
        case .lockEngaged: "Lock engaged"
        case nil: LocalizedStringKey(raw)
        }
    }
}
