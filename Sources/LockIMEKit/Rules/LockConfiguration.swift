import Foundation

/// How LockIME behaves while a particular app is frontmost.
public enum AppRuleMode: String, Codable, Sendable, CaseIterable, Identifiable {
    /// Lock to `AppRule.lockedSourceID` while this app is frontmost.
    case locked
    /// Do not enforce any lock while this app is frontmost.
    case ignored
    /// Fall back to the global default source.
    case useDefault

    public var id: String { rawValue }
}

/// A per-app locking rule.
public struct AppRule: Codable, Sendable, Hashable, Identifiable {
    public var bundleID: String
    public var mode: AppRuleMode
    /// The locked source when `mode == .locked`.
    public var lockedSourceID: InputSourceID?

    public var id: String { bundleID }

    public init(bundleID: String, mode: AppRuleMode = .locked, lockedSourceID: InputSourceID? = nil) {
        self.bundleID = bundleID
        self.mode = mode
        self.lockedSourceID = lockedSourceID
    }
}

/// A per-URL rule for the optional Accessibility-gated enhanced mode.
public struct URLRule: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    /// Host pattern, e.g. `github.com` (matches subdomains) or `*.google.com`.
    public var hostPattern: String
    public var lockedSourceID: InputSourceID

    public init(id: UUID = UUID(), hostPattern: String, lockedSourceID: InputSourceID) {
        self.id = id
        self.hostPattern = hostPattern
        self.lockedSourceID = lockedSourceID
    }
}

/// The full persisted locking configuration.
public struct LockConfiguration: Codable, Sendable, Equatable {
    /// Master on/off (the tray "activate" toggle).
    public var isEnabled: Bool
    /// Global default locked source, used when no app rule applies.
    public var defaultSourceID: InputSourceID?
    /// Per-app overrides.
    public var appRules: [AppRule]
    /// Whether the Accessibility-gated enhanced mode is on.
    public var enhancedModeEnabled: Bool
    /// Per-URL rules (enhanced mode).
    public var urlRules: [URLRule]

    public init(
        isEnabled: Bool = false,
        defaultSourceID: InputSourceID? = nil,
        appRules: [AppRule] = [],
        enhancedModeEnabled: Bool = false,
        urlRules: [URLRule] = []
    ) {
        self.isEnabled = isEnabled
        self.defaultSourceID = defaultSourceID
        self.appRules = appRules
        self.enhancedModeEnabled = enhancedModeEnabled
        self.urlRules = urlRules
    }

    // Forward/backward-compatible decoding: missing keys fall back to defaults
    // so older saved configurations keep loading after upgrades.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? false
        defaultSourceID = try container.decodeIfPresent(InputSourceID.self, forKey: .defaultSourceID)
        appRules = try container.decodeIfPresent([AppRule].self, forKey: .appRules) ?? []
        enhancedModeEnabled = try container.decodeIfPresent(Bool.self, forKey: .enhancedModeEnabled) ?? false
        urlRules = try container.decodeIfPresent([URLRule].self, forKey: .urlRules) ?? []
    }

    public static let `default` = LockConfiguration()

    public func rule(for bundleID: String) -> AppRule? {
        appRules.first { $0.bundleID == bundleID }
    }
}
