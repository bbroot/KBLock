import Foundation

@testable import LockIMEKit

@MainActor
final class MockFrontmostMonitor: FrontmostAppMonitoring {
    var bundleID: String?
    private var handler: (@MainActor (String?) -> Void)?

    init(bundleID: String? = nil) {
        self.bundleID = bundleID
    }

    func currentBundleID() -> String? { bundleID }

    func start(onChange: @escaping @MainActor (String?) -> Void) {
        handler = onChange
    }

    func stop() { handler = nil }

    /// Simulate the frontmost app changing.
    func activate(_ bundleID: String?) {
        self.bundleID = bundleID
        handler?(bundleID)
    }
}
