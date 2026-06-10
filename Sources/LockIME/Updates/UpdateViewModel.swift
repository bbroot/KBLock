import Foundation
import Observation

/// Observable state for the custom update window, driven by `LockIMEUserDriver`.
@MainActor
@Observable
final class UpdateViewModel {
    enum Phase: Equatable {
        case idle
        case checking
        case upToDate
        case found(version: String)
        case downloading(fraction: Double)
        case extracting(fraction: Double)
        case readyToInstall
        case installing
        case error(UpdateFailure)
    }

    var phase: Phase = .idle
    var availableVersion: String = ""
    /// Publication date of the offered update (appcast `pubDate`), if present.
    var publishedDate: Date?
    /// Download byte progress, for the detail line under the progress bar.
    var downloadedBytes: UInt64 = 0
    var expectedBytes: UInt64 = 0
    /// Average download speed in bytes/sec (0 until measurable).
    var downloadSpeed: Double = 0
    /// Whether the offered update came from the beta channel.
    var isBetaChannel = false
    var releaseNotesMarkdown: String = ""

    /// Sparkle reply blocks. Exactly one must be invoked per prompt; invoking
    /// any one clears all so a window close can't double-reply.
    @ObservationIgnored var installAction: (() -> Void)?
    @ObservationIgnored var skipAction: (() -> Void)?
    @ObservationIgnored var dismissAction: (() -> Void)?

    /// Whether skipping is offered (only on the initial "found" prompt).
    var canSkip: Bool { skipAction != nil }

    /// Affirmative reply (install). One-shot.
    func install() {
        let action = installAction
        clearReplies()
        action?()
    }

    /// Skip this version (Sparkle remembers and won't re-offer it). One-shot.
    func skip() {
        let action = skipAction
        clearReplies()
        action?()
    }

    /// Dismiss/cancel reply. One-shot; safe to call on window close — it's a
    /// no-op if a choice was already made (so Sparkle never hangs waiting).
    func dismissReply() {
        let action = dismissAction
        clearReplies()
        action?()
    }

    func clearReplies() {
        installAction = nil
        skipAction = nil
        dismissAction = nil
    }

    func reset() {
        phase = .idle
        availableVersion = ""
        publishedDate = nil
        downloadedBytes = 0
        expectedBytes = 0
        downloadSpeed = 0
        isBetaChannel = false
        releaseNotesMarkdown = ""
        clearReplies()
    }
}
