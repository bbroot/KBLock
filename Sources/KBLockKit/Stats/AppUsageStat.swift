import Foundation

/// A single per-app, per-source usage counter.
public struct AppUsageStat: Codable, Sendable, Hashable, Identifiable {
    public let bundleID: String
    public let sourceID: String
    public let sourceName: String
    public var count: Int
    public var lastUsed: Date

    public var id: String { "\(bundleID):\(sourceID)" }

    public init(bundleID: String, sourceID: String, sourceName: String, count: Int = 1, lastUsed: Date = .now) {
        self.bundleID = bundleID
        self.sourceID = sourceID
        self.sourceName = sourceName
        self.count = count
        self.lastUsed = lastUsed
    }
}

/// A suggested rule derived from usage statistics.
public struct AppSuggestion: Identifiable, Sendable {
    public let bundleID: String
    public let appName: String
    public let sourceID: String
    public let sourceName: String
    /// How often this source was used, as a fraction [0-1].
    public let confidence: Double
    public let totalActivations: Int

    public var id: String { bundleID }
}

/// The full usage stats snapshot for one app.
public struct AppUsageSnapshot: Sendable, Identifiable {
    public var id: String { bundleID }
    public let bundleID: String
    public let appName: String
    public let sources: [AppUsageStat]
    public let totalCount: Int

    /// The dominant source, if usage data exists.
    public var dominantSource: AppUsageStat? {
        sources.max(by: { $0.count < $1.count })
    }

    /// Confidence in the top source (0-1).
    public var topConfidence: Double {
        guard totalCount > 0, let top = dominantSource else { return 0 }
        return Double(top.count) / Double(totalCount)
    }
}
