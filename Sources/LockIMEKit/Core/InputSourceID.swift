import Foundation

/// A strongly-typed wrapper around a Text Input Source identifier
/// (the value of `kTISPropertyInputSourceID`, e.g. `com.apple.keylayout.US`).
///
/// Using a dedicated value type instead of bare `String` keeps input-source
/// identity unambiguous across the engine, rules, and logging layers.
public struct InputSourceID: Hashable, Sendable, Codable, RawRepresentable,
    ExpressibleByStringLiteral, CustomStringConvertible
{
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: StringLiteralType) {
        self.rawValue = value
    }

    public var description: String { rawValue }

    // Encode/decode as a plain string so persisted rules stay human-readable.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
