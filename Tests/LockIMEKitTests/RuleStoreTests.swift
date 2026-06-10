import Foundation
import Testing

@testable import LockIMEKit

@Suite("RuleStore")
struct RuleStoreTests {
    private func freshDefaults() -> UserDefaults {
        let suite = "lockime.tests.\(UUID().uuidString)"
        return UserDefaults(suiteName: suite)!
    }

    @Test("missing data loads the default configuration")
    func loadsDefault() {
        let store = RuleStore(defaults: freshDefaults())
        #expect(store.load() == LockConfiguration.default)
    }

    @Test("save then load round-trips the configuration")
    func roundTrip() {
        let store = RuleStore(defaults: freshDefaults())
        let config = LockConfiguration(
            isEnabled: true,
            defaultSourceID: "com.apple.keylayout.US",
            appRules: [
                AppRule(bundleID: "com.apple.Terminal", mode: .locked, lockedSourceID: "com.apple.keylayout.ABC"),
                AppRule(bundleID: "com.game.App", mode: .ignored),
                AppRule(bundleID: "com.foo.App", mode: .useDefault),
            ]
        )
        store.save(config)
        #expect(store.load() == config)
    }

    @Test("a later save overwrites an earlier one")
    func overwrite() {
        let defaults = freshDefaults()
        let store = RuleStore(defaults: defaults)
        store.save(LockConfiguration(isEnabled: true))
        store.save(LockConfiguration(isEnabled: false, defaultSourceID: "com.apple.keylayout.US"))
        let loaded = store.load()
        #expect(loaded.isEnabled == false)
        #expect(loaded.defaultSourceID == "com.apple.keylayout.US")
    }
}
