import Foundation

/// A keyboard input source (layout or input method) as surfaced by the
/// Text Input Sources (TIS) API.
public struct InputSource: Hashable, Sendable, Identifiable {
    public let id: InputSourceID
    public let localizedName: String
    public let isSelectCapable: Bool
    public let isEnabled: Bool
    /// Whether this is a Chinese/Japanese/Korean/Vietnamese input *method*,
    /// which needs the focus-stealing workaround to switch reliably.
    public let isCJKV: Bool

    public init(
        id: InputSourceID,
        localizedName: String,
        isSelectCapable: Bool,
        isEnabled: Bool,
        isCJKV: Bool
    ) {
        self.id = id
        self.localizedName = localizedName
        self.isSelectCapable = isSelectCapable
        self.isEnabled = isEnabled
        self.isCJKV = isCJKV
    }
}

/// Why the engine forced the input source — recorded in the activation log.
public enum ActivationReason: String, Sendable, Codable, CaseIterable {
    /// The user or another app switched away and we reverted.
    case revertedSwitch
    /// The frontmost app changed and we applied its rule.
    case appActivated
    /// Enhanced mode: the browser URL matched a rule.
    case urlMatched
    /// Locking was just enabled, or the target was changed by the user.
    case lockEngaged
}

/// A single enforcement event, emitted whenever the engine forces the source.
public struct ActivationEvent: Hashable, Sendable {
    public let timestamp: Date
    public let inputSource: InputSourceID
    public let inputSourceName: String
    public let reason: ActivationReason
    /// Wall time the `select` call took, in milliseconds.
    public let durationMs: Double

    public init(
        timestamp: Date,
        inputSource: InputSourceID,
        inputSourceName: String,
        reason: ActivationReason,
        durationMs: Double
    ) {
        self.timestamp = timestamp
        self.inputSource = inputSource
        self.inputSourceName = inputSourceName
        self.reason = reason
        self.durationMs = durationMs
    }
}
