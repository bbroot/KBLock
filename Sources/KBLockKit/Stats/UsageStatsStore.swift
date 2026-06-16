import Foundation
import OSLog

/// Tracks per-app, per-source usage from engine activations and user switches.
/// Persisted to UserDefaults so it survives restarts and can be synced via iCloud.
public final class UsageStatsStore: @unchecked Sendable {
    private static let log = Logger(subsystem: "com.bbroot.KBLock", category: "UsageStats")
    private static let storeKey = "kbLockUsageStats"

    private let defaults: UserDefaults
    private let lock = NSLock()
    private var stats: [String: AppUsageStat] = [:]

    /// Minimum data points before a suggestion is shown.
    public let minSuggestionCount: Int = 5

    /// Minimum confidence threshold for auto-suggestion.
    public let minConfidence: Double = 0.6

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    // MARK: - Recording

    /// Record that `sourceID` (with `sourceName`) was used while `bundleID` was
    /// frontmost. Thread-safe.
    public func record(bundleID: String, sourceID: String, sourceName: String) {
        lock.lock()
        defer { lock.unlock() }

        let key = "\(bundleID):\(sourceID)"
        if var existing = stats[key] {
            existing.count += 1
            existing.lastUsed = .now
            stats[key] = existing
        } else {
            stats[key] = AppUsageStat(
                bundleID: bundleID,
                sourceID: sourceID,
                sourceName: sourceName,
                count: 1,
                lastUsed: .now
            )
        }
        save()
    }

    // MARK: - Queries

    /// All usage data, grouped by app. Returns snapshots with computed totals.
    public func allAppSnapshots() -> [AppUsageSnapshot] {
        lock.lock()
        defer { lock.unlock() }

        var byApp: [String: [AppUsageStat]] = [:]
        for stat in stats.values {
            byApp[stat.bundleID, default: []].append(stat)
        }

        // Resolve display names and sort by total activations (most active first).
        return byApp.compactMap { bundleID, sources in
            let total = sources.reduce(0) { $0 + $1.count }
            guard total > 0 else { return nil }
            return AppUsageSnapshot(
                bundleID: bundleID,
                appName: AppDisplayName.name(for: bundleID),
                sources: sources.sorted { $0.count > $1.count },
                totalCount: total
            )
        }
        .sorted { $0.totalCount > $1.totalCount }
    }

    /// Smart suggestions: apps where confidence meets the threshold.
    public func suggestions() -> [AppSuggestion] {
        allAppSnapshots().compactMap { snap in
            guard snap.totalCount >= minSuggestionCount,
                  let dominant = snap.dominantSource,
                  snap.topConfidence >= minConfidence,
                  dominant.sourceID != "—"
            else { return nil }
            return AppSuggestion(
                bundleID: snap.bundleID,
                appName: snap.appName,
                sourceID: dominant.sourceID,
                sourceName: dominant.sourceName,
                confidence: snap.topConfidence,
                totalActivations: snap.totalCount
            )
        }
    }

    // MARK: - Persistence

    private func load() {
        guard let data = defaults.data(forKey: Self.storeKey),
              let decoded = try? JSONDecoder().decode([String: AppUsageStat].self, from: data)
        else { return }
        stats = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(stats) else { return }
        defaults.set(data, forKey: Self.storeKey)
    }

    /// Reset all usage data.
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        stats = [:]
        save()
    }
}

// MARK: - App display name helper (minimal, no NSWorkspace dependency)

private enum AppDisplayName {
    static func name(for bundleID: String) -> String {
        // Common app bundle IDs → display names (cached lookup).
        switch bundleID {
        case "com.apple.dt.Xcode": return "Xcode"
        case "com.apple.Safari": return "Safari"
        case "com.apple.finder": return "Finder"
        case "com.apple.Terminal": return "Terminal"
        case "com.apple.iTerm2": return "iTerm2"
        case "com.google.Chrome": return "Chrome"
        case "com.microsoft.edgemac": return "Edge"
        case "org.mozilla.firefox": return "Firefox"
        case "com.tencent.xinWeChat": return "WeChat"
        case "com.tencent.qq": return "QQ"
        case "com.microsoft.VSCode": return "VS Code"
        case "com.jetbrains.apps.PhpStorm": return "PhpStorm"
        case "com.jetbrains.intellij": return "IntelliJ IDEA"
        case "com.jetbrains.AppCode": return "AppCode"
        case "com.sublimetext.4": return "Sublime Text"
        case "com.apple.TextEdit": return "TextEdit"
        case "com.apple.Notes": return "Notes"
        case "com.apple.Mail": return "Mail"
        case "com.apple.MobileSMS": return "Messages"
        case "com.apple.iCal": return "Calendar"
        case "com.apple.Pages": return "Pages"
        case "com.apple.Keynote": return "Keynote"
        case "com.apple.Numbers": return "Numbers"
        default:
            // Fall back to bundle ID's last component, humanized.
            let parts = bundleID.split(separator: ".")
            return parts.last.map(String.init) ?? bundleID
        }
    }
}
