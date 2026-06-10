import Foundation

/// Abstraction over frontmost-app tracking, so the engine can be tested with a
/// mock instead of the real `NSWorkspace`.
@MainActor
public protocol FrontmostAppMonitoring: AnyObject {
    /// The bundle identifier of the currently frontmost app.
    func currentBundleID() -> String?
    /// Begin delivering frontmost-app changes (debounced).
    func start(onChange: @escaping @MainActor (String?) -> Void)
    func stop()
}
