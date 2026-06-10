import Foundation

/// The heart of LockIME: a small state machine that keeps the active input
/// source pinned to a target, debouncing against its own forced switches.
///
/// Anti-loop design (mirrors InputSourcePro):
///  1. On a change, if the current source already equals the target, do nothing
///     (idempotent — this absorbs the echo of our own `select`).
///  2. Otherwise, if we are still inside the suppression window of a recent
///     force, do nothing (let the switch settle).
///  3. Only a *verified* mismatch outside the window triggers a re-force.
@MainActor
public final class LockController {
    /// How long after a forced switch to ignore further change notifications.
    public static let suppressionWindow: TimeInterval = 0.30

    private let provider: any InputSourceProviding
    private let uptime: @MainActor () -> TimeInterval
    private let clock: @MainActor () -> Date

    public private(set) var target: InputSourceID?
    public private(set) var isEnabled: Bool
    public private(set) var activationCount: Int = 0

    /// Invoked on every successful forced switch (for logging / UI counters).
    public var onActivation: (@MainActor (ActivationEvent) -> Void)?

    private var settleUntil: TimeInterval = 0

    public init(
        provider: any InputSourceProviding,
        isEnabled: Bool = false,
        uptime: @escaping @MainActor () -> TimeInterval = { ProcessInfo.processInfo.systemUptime },
        clock: @escaping @MainActor () -> Date = { Date() }
    ) {
        self.provider = provider
        self.isEnabled = isEnabled
        self.uptime = uptime
        self.clock = clock
    }

    // MARK: - Public commands

    /// Engage or disengage locking. Engaging while mismatched forces immediately.
    public func setEnabled(_ on: Bool) {
        isEnabled = on
        guard on else { return }
        enforceIfNeeded(reason: .lockEngaged)
    }

    /// Set (or clear) the locked target. A non-nil target that differs from the
    /// current source is enforced immediately.
    public func setTarget(_ id: InputSourceID?, reason: ActivationReason = .lockEngaged) {
        let changed = id != target
        target = id
        // A genuinely new target supersedes any in-flight suppression window
        // (which only guarded re-forcing the *previous* target), so enforce now.
        if changed { settleUntil = 0 }
        enforceIfNeeded(reason: reason)
    }

    /// Call when the system posts a "selected input source changed" notification.
    public func selectedSourceDidChange() {
        enforceIfNeeded(reason: .revertedSwitch)
    }

    // MARK: - Core state machine

    private func enforceIfNeeded(reason: ActivationReason) {
        guard isEnabled, let target else { return }
        guard let current = provider.currentSourceID() else { return }
        if current == target { return }       // (1) idempotent — absorbs our echo
        if uptime() < settleUntil { return }  // (2) recent force still settling
        force(target, reason: reason)          // (3) verified mismatch → re-force
    }

    private func force(_ id: InputSourceID, reason: ActivationReason) {
        let start = uptime()
        let ok = provider.select(id)
        settleUntil = uptime() + Self.suppressionWindow
        guard ok else { return }
        activationCount += 1
        let name = provider.source(for: id)?.localizedName ?? id.rawValue
        let durationMs = max(0, (uptime() - start) * 1000)
        onActivation?(
            ActivationEvent(
                timestamp: clock(),
                inputSource: id,
                inputSourceName: name,
                reason: reason,
                durationMs: durationMs
            )
        )
    }
}
