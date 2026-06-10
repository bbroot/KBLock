import Testing

@testable import LockIMEKit

/// Exercises the exact poll-and-react mechanism `AppState` uses to detect the
/// Accessibility grant. The trust signal is injected so the false→true
/// transition can be driven deterministically, without the real (SIP-protected,
/// GUI-only) permission.
@Suite("AccessibilityGrantWatcher")
@MainActor
struct AccessibilityGrantWatcherTests {
    /// A trust check that flips to `true` after a set number of polls, modelling
    /// the user granting access partway through the watch.
    private func flipping(after polls: Int, calls: Box) -> () -> Bool {
        { calls.value += 1; return calls.value > polls }
    }

    final class Box { var value = 0 }

    @Test("fires onGranted exactly once when trust flips true, then stops")
    func firesOnGrant() async {
        let calls = Box()
        let watcher = AccessibilityGrantWatcher(
            pollInterval: .milliseconds(5),
            isTrusted: flipping(after: 2, calls: calls)
        )

        var granted = 0
        watcher.start { granted += 1 }
        #expect(watcher.isRunning)

        await whileRunning(watcher)

        #expect(granted == 1)
        #expect(!watcher.isRunning)
    }

    @Test("keeps polling while access is not granted")
    func keepsPollingUntilGranted() async {
        let watcher = AccessibilityGrantWatcher(
            pollInterval: .milliseconds(5),
            isTrusted: { false }
        )

        var granted = false
        watcher.start { granted = true }

        // Give the loop several intervals; it must not fire while untrusted.
        try? await Task.sleep(for: .milliseconds(40))
        #expect(!granted)
        #expect(watcher.isRunning)

        watcher.stop()
        #expect(!watcher.isRunning)
    }

    @Test("stop() cancels the watch without firing onGranted")
    func stopCancels() async {
        let watcher = AccessibilityGrantWatcher(
            pollInterval: .milliseconds(5),
            isTrusted: { true }
        )

        var granted = false
        watcher.stop() // before start: no-op
        #expect(!watcher.isRunning)

        // Stop immediately after start, before the first poll can elapse.
        watcher.start { granted = true }
        watcher.stop()
        try? await Task.sleep(for: .milliseconds(40))
        #expect(!granted)
        #expect(!watcher.isRunning)
    }

    @Test("start is a no-op while already running")
    func startIsIdempotent() async {
        let calls = Box()
        let watcher = AccessibilityGrantWatcher(
            pollInterval: .milliseconds(5),
            isTrusted: flipping(after: 3, calls: calls)
        )

        var granted = 0
        watcher.start { granted += 1 }
        watcher.start { granted += 1 } // ignored: a loop is already running
        await whileRunning(watcher)

        #expect(granted == 1)
    }

    /// Awaits, with a bounded ceiling, until the watcher stops polling.
    private func whileRunning(_ watcher: AccessibilityGrantWatcher) async {
        for _ in 0..<200 where watcher.isRunning {
            try? await Task.sleep(for: .milliseconds(5))
        }
    }
}
