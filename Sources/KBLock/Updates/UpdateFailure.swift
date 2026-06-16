import Foundation
import Sparkle

/// Semantic category of an update failure, derived from Sparkle's error codes.
///
/// Sparkle localizes `NSError.localizedDescription` against the *system*
/// language, so showing it verbatim breaks the in-app language override
/// (English chrome around a Chinese error body, or vice versa). UI surfaces
/// carry this value instead and resolve `messageKey` in the app's chosen
/// language at render time — `Text(LocalizedStringKey(...))` on SwiftUI
/// surfaces, `AppKitStrings`/`loc` on AppKit ones.
enum UpdateFailure: Equatable {
    case checkFailed
    case downloadFailed
    case verificationFailed
    case installationFailed
    case unknown

    init(_ error: any Error) {
        let nsError = error as NSError
        guard nsError.domain == SUSparkleErrorDomain else {
            self = .unknown
            return
        }
        // Sparkle groups codes by phase (SUErrors.h): 0s configuration,
        // 1000s appcast, 2000s download, 3000s extraction/signature,
        // 4000s installation.
        switch nsError.code {
        case ..<2000: self = .checkFailed
        case 2000..<3000: self = .downloadFailed
        case 3000..<4000: self = .verificationFailed
        case 4000..<5000: self = .installationFailed
        default: self = .unknown
        }
    }

    /// The English source string — also the `Localizable.xcstrings` key.
    var messageKey: String {
        switch self {
        case .checkFailed:
            "Couldn't check for updates. Please check your internet connection and try again later."
        case .downloadFailed:
            "The update couldn't be downloaded. Please check your internet connection and try again."
        case .verificationFailed:
            "The update couldn't be verified. Please try again later."
        case .installationFailed:
            "The update couldn't be installed. Please try again later."
        case .unknown:
            "An unexpected error occurred. Please try again later."
        }
    }
}
