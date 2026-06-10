import Foundation
import SwiftData

/// A persisted record of one forced input-source switch. Kept for 24 hours.
@Model
public final class ActivationLogEntry {
    public var timestamp: Date
    public var inputSourceID: String
    public var inputSourceName: String
    /// `ActivationReason.rawValue` (stored as a string for SwiftData simplicity).
    public var reasonRaw: String
    /// Wall time the switch took, in milliseconds.
    public var durationMs: Double

    public init(
        timestamp: Date,
        inputSourceID: String,
        inputSourceName: String,
        reasonRaw: String,
        durationMs: Double
    ) {
        self.timestamp = timestamp
        self.inputSourceID = inputSourceID
        self.inputSourceName = inputSourceName
        self.reasonRaw = reasonRaw
        self.durationMs = durationMs
    }

    public convenience init(_ event: ActivationEvent) {
        self.init(
            timestamp: event.timestamp,
            inputSourceID: event.inputSource.rawValue,
            inputSourceName: event.inputSourceName,
            reasonRaw: event.reason.rawValue,
            durationMs: event.durationMs
        )
    }

    public var reason: ActivationReason? { ActivationReason(rawValue: reasonRaw) }
}
