import Foundation

/// Reads the active tab URL of the frontmost browser (enhanced mode).
/// Abstracted so the engine's URL-rule path is testable with a mock.
@MainActor
public protocol BrowserURLProviding: AnyObject {
    /// The active tab URL for the given frontmost app, or `nil` when it is not a
    /// browser, the URL can't be read, or Accessibility isn't granted.
    func currentURL(forBundleID bundleID: String?) -> String?
}
