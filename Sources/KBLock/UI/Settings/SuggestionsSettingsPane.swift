import KBLockKit
import SwiftUI

/// Smart suggestions derived from per-app input source usage statistics.
/// Shows which sources each app actually uses and offers one-click rule creation.
struct SuggestionsSettingsPane: View {
    @Environment(AppState.self) private var state
    @State private var snapshots: [AppUsageSnapshot] = []
    @State private var showClearConfirmation = false

    var body: some View {
        Form {
            headerSection
            if snapshots.isEmpty {
                emptySection
            } else {
                controlsSection
                suggestionsSections
            }
        }
        .formStyle(.grouped)
        .alert("Clear All Usage Data?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) { clearData() }
        } message: {
            Text("This resets all usage statistics. Suggestions will regenerate as new data accumulates.")
        }
        .onAppear { refresh() }
        .onReceive(
            NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
        ) { _ in refresh() }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        Section {
            HStack(spacing: DS.Spacing.md) {
                Image(systemName: "lightbulb")
                    .font(.title)
                    .foregroundStyle(DS.Palette.accent)
                Text("Usage Insights")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text("KBLock tracks which input sources are used in each app. "
                     + "Over time, patterns emerge — suggestions appear here.")
                    .font(DS.Font.sectionFooter)
                    .foregroundStyle(.secondary)
                Text("Suggestions require at least \(state.usageStats.minSuggestionCount) data points "
                     + "and \(Int(state.usageStats.minConfidence * 100))% confidence.")
                    .font(DS.Font.sectionFooter)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var emptySection: some View {
        Section {
            HStack {
                Spacer()
                VStack(spacing: DS.Spacing.sm) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.largeTitle)
                        .foregroundStyle(.quaternary)
                    Text("No usage data yet")
                        .foregroundStyle(.secondary)
                    Text("Use KBLock for a while, then check back here.")
                        .font(DS.Font.sectionFooter)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 40)
                Spacer()
            }
        }
    }

    private var controlsSection: some View {
        Section {
            Button("Clear All Data") {
                showClearConfirmation = true
            }
            .buttonStyle(.plain)
            .foregroundStyle(DS.Palette.warning)
            .controlSize(.small)
        }
    }

    private var suggestionsSections: some View {
        ForEach(snapshots) { snap in
            suggestionSection(snap: snap)
        }
    }

    private func suggestionSection(snap: AppUsageSnapshot) -> some View {
        Section(snap.appName) {
            ForEach(snap.sources) { stat in
                sourceRow(stat: stat, total: snap.totalCount)
            }
            suggestionButton(snap: snap)
        }
    }

    private func sourceRow(stat: AppUsageStat, total: Int) -> some View {
        HStack {
            Text(stat.sourceName)
                .font(DS.Font.rowTitle)
            Spacer()
            Text("\(stat.count) times")
                .font(DS.Font.rowSubtitle)
                .foregroundStyle(.secondary)
            ProgressView(value: Double(stat.count), total: Double(total))
                .frame(width: 60)
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func suggestionButton(snap: AppUsageSnapshot) -> some View {
        let alreadyHasRule = state.config.appRules.contains(where: { $0.bundleID == snap.bundleID })
        if let top = snap.dominantSource,
           snap.topConfidence >= state.usageStats.minConfidence,
           snap.totalCount >= state.usageStats.minSuggestionCount,
           !alreadyHasRule
        {
            HStack {
                Spacer()
                Button {
                    applySuggestion(snap: snap, source: top)
                } label: {
                    let pct = Int(snap.topConfidence * 100)
                    Label("Add rule: \(top.sourceName) (\(pct)%)", systemImage: "plus.circle")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(DS.Palette.accent)
            }
        }
    }

    // MARK: - Actions

    private func refresh() {
        snapshots = state.usageStats.allAppSnapshots()
    }

    private func clearData() {
        state.usageStats.clear()
        snapshots = []
    }

    private func applySuggestion(snap: AppUsageSnapshot, source: AppUsageStat) {
        let rule = AppRule(
            bundleID: snap.bundleID,
            mode: .locked,
            lockedSourceID: InputSourceID(source.sourceID)
        )
        state.upsertRule(rule)
        refresh()
    }
}
