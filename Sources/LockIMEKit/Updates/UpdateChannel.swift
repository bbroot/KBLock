import Foundation

/// The update channel a user follows. Stable items carry no `sparkle:channel`
/// tag (the always-included default channel); beta items are tagged `beta`.
public enum UpdateChannel: String, CaseIterable, Sendable, Identifiable {
    case stable
    case beta

    public var id: String { rawValue }

    /// The set to return from `SPUUpdaterDelegate.allowedChannels(for:)`.
    /// The default (channel-less) channel is always included by Sparkle, so the
    /// stable channel maps to the empty set.
    public static func allowedChannels(for channel: UpdateChannel) -> Set<String> {
        switch channel {
        case .stable: []
        case .beta: ["beta"]
        }
    }

    public static func from(usesBeta: Bool) -> UpdateChannel {
        usesBeta ? .beta : .stable
    }
}
