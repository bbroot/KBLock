import Foundation

extension Bundle {
    var shortVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    var buildVersion: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "0"
    }

    var copyright: String {
        infoDictionary?["NSHumanReadableCopyright"] as? String ?? ""
    }
}
