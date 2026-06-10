@testable import LockIMEKit

@MainActor
final class MockBrowserURLProvider: BrowserURLProviding {
    var url: String?

    init(url: String? = nil) {
        self.url = url
    }

    func currentURL(forBundleID bundleID: String?) -> String? { url }
}
