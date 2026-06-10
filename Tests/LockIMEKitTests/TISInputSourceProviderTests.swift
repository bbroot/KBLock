import Foundation
import Testing

@testable import LockIMEKit

/// Integration tests against the real TIS API. Opt in with `LOCKIME_HW_TESTS=1`
/// (`make test` skips them so it stays non-destructive and CI-safe).
@MainActor
@Suite(
    "TISInputSourceProvider (hardware)",
    .tags(.hardware),
    .enabled(if: FileManager.default.fileExists(atPath: "/tmp/lockime_hw_tests"))
)
struct TISInputSourceProviderTests {
    @Test("enumerates selectable sources")
    func enumerates() {
        let provider = TISInputSourceProvider()
        let sources = provider.selectableSources()
        #expect(!sources.isEmpty)
        #expect(sources.allSatisfy { $0.isEnabled && $0.isSelectCapable })
    }

    @Test("reads the current source and its metadata")
    func current() {
        let provider = TISInputSourceProvider()
        let id = provider.currentSourceID()
        #expect(id != nil)
        if let id {
            #expect(provider.source(for: id) != nil)
        }
    }

    @Test("forces a switch and restores the original")
    func roundTrip() {
        let provider = TISInputSourceProvider()
        guard let original = provider.currentSourceID() else {
            Issue.record("no current input source")
            return
        }
        // Prefer a non-CJKV target so the test doesn't steal focus.
        let candidates = provider.selectableSources().filter { !$0.isCJKV && $0.id != original }
        guard let target = candidates.first else { return } // only one source

        #expect(provider.select(target.id))
        #expect(provider.currentSourceID() == target.id)

        #expect(provider.select(original))
        #expect(provider.currentSourceID() == original)
    }
}
