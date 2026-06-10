import AppKit
import Foundation

/// Tracks the frontmost application via `NSWorkspace`, debouncing rapid
/// activations (e.g. Cmd-Tab) so we don't thrash the lock target.
@MainActor
public final class AppActivationMonitor: FrontmostAppMonitoring {
    private var task: Task<Void, Never>?
    private let debounce: Duration

    public init(debounce: Duration = .milliseconds(40)) {
        self.debounce = debounce
    }

    public func currentBundleID() -> String? {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    public func start(onChange: @escaping @MainActor (String?) -> Void) {
        guard task == nil else { return }
        let debounce = self.debounce
        task = Task { @MainActor in
            let activations = NSWorkspace.shared.notificationCenter.notifications(
                named: NSWorkspace.didActivateApplicationNotification
            )
            for await _ in activations {
                try? await Task.sleep(for: debounce)
                if Task.isCancelled { break }
                onChange(NSWorkspace.shared.frontmostApplication?.bundleIdentifier)
            }
        }
    }

    public func stop() {
        task?.cancel()
        task = nil
    }

    deinit {
        task?.cancel()
    }
}
