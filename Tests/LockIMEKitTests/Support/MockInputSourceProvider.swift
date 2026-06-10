import Foundation

@testable import LockIMEKit

/// In-memory `InputSourceProviding` for state-machine tests.
///
/// `select` simulates the system by updating `current` and recording the call,
/// matching the real behavior where a successful `TISSelectInputSource` makes
/// the target the active source.
@MainActor
final class MockInputSourceProvider: InputSourceProviding {
    var current: InputSourceID?
    var sources: [InputSource]
    /// Per-id override of `select` success; default is `true`.
    var selectSucceeds: [InputSourceID: Bool] = [:]
    /// When set, `select` records the call but does NOT change `current`
    /// (simulates a switch that didn't take, e.g. a flaky CJKV switch).
    var selectIsNoOp = false

    private(set) var selectCalls: [InputSourceID] = []

    init(current: InputSourceID? = nil, sources: [InputSource] = []) {
        self.current = current
        self.sources = sources
    }

    func currentSourceID() -> InputSourceID? { current }

    func selectableSources() -> [InputSource] {
        sources.filter { $0.isEnabled && $0.isSelectCapable }
    }

    func source(for id: InputSourceID) -> InputSource? {
        sources.first { $0.id == id }
    }

    @discardableResult
    func select(_ id: InputSourceID) -> Bool {
        selectCalls.append(id)
        let ok = selectSucceeds[id] ?? true
        if ok && !selectIsNoOp {
            current = id
        }
        return ok
    }
}

extension InputSource {
    /// Convenience for tests.
    static func stub(_ id: String, name: String? = nil, cjkv: Bool = false) -> InputSource {
        InputSource(
            id: InputSourceID(id),
            localizedName: name ?? id,
            isSelectCapable: true,
            isEnabled: true,
            isCJKV: cjkv
        )
    }
}

/// A mutable monotonic clock for driving the suppression window in tests.
@MainActor
final class FakeUptime {
    var value: TimeInterval = 1000
    func read() -> TimeInterval { value }
    func advance(by seconds: TimeInterval) { value += seconds }
}
