import Foundation
import Testing

@testable import LockIMEKit

@MainActor
@Suite("LockEngine")
struct LockEngineTests {
    private let us: InputSourceID = "com.apple.keylayout.US"
    private let abc: InputSourceID = "com.apple.keylayout.ABC"

    private func makeEngine(
        current: InputSourceID,
        frontmost: String?
    ) -> (LockEngine, MockInputSourceProvider, MockFrontmostMonitor) {
        let provider = MockInputSourceProvider(
            current: current,
            sources: [.stub(us.rawValue), .stub(abc.rawValue)]
        )
        let monitor = MockFrontmostMonitor(bundleID: frontmost)
        let engine = LockEngine(provider: provider, appMonitor: monitor)
        engine.start()
        return (engine, provider, monitor)
    }

    @Test("applying an enabled global default enforces it")
    func appliesDefault() {
        let (engine, provider, _) = makeEngine(current: abc, frontmost: "com.foo.App")
        engine.apply(LockConfiguration(isEnabled: true, defaultSourceID: us))
        #expect(provider.selectCalls == [us])
        #expect(provider.current == us)
    }

    @Test("a disabled configuration enforces nothing")
    func disabledDoesNothing() {
        let (engine, provider, _) = makeEngine(current: abc, frontmost: "com.foo.App")
        engine.apply(LockConfiguration(isEnabled: false, defaultSourceID: us))
        #expect(provider.selectCalls.isEmpty)
        #expect(provider.current == abc)
    }

    @Test("a frontmost-app change retargets to that app's rule")
    func frontmostRetargets() {
        let (engine, provider, monitor) = makeEngine(current: us, frontmost: "com.foo.App")
        engine.apply(LockConfiguration(
            isEnabled: true,
            defaultSourceID: us,
            appRules: [AppRule(bundleID: "com.apple.Terminal", mode: .locked, lockedSourceID: abc)]
        ))
        #expect(provider.current == us) // foo app → default

        monitor.activate("com.apple.Terminal")
        #expect(provider.current == abc) // retargeted to Terminal's rule
    }

    @Test("enhanced URL rule overrides the app rule when matched")
    func enhancedURLOverrides() {
        let pinyin: InputSourceID = "com.apple.inputmethod.SCIM.ITABC"
        let provider = MockInputSourceProvider(
            current: us,
            sources: [.stub(us.rawValue), .stub(abc.rawValue), .stub(pinyin.rawValue, cjkv: true)]
        )
        let monitor = MockFrontmostMonitor(bundleID: "com.apple.Safari")
        let urls = MockBrowserURLProvider(url: "https://github.com/x")
        let engine = LockEngine(provider: provider, appMonitor: monitor, urlProvider: urls)
        engine.start()

        engine.apply(LockConfiguration(
            isEnabled: true,
            defaultSourceID: us,
            appRules: [AppRule(bundleID: "com.apple.Safari", mode: .locked, lockedSourceID: abc)],
            enhancedModeEnabled: true,
            urlRules: [URLRule(hostPattern: "github.com", lockedSourceID: pinyin)]
        ))
        #expect(provider.current == pinyin) // URL rule wins over the app rule
    }

    @Test("re-resolving after the URL changes switches to the new rule")
    func urlChangeReResolves() {
        let pinyin: InputSourceID = "com.apple.inputmethod.SCIM.ITABC"
        let provider = MockInputSourceProvider(
            current: us,
            sources: [.stub(us.rawValue), .stub(abc.rawValue), .stub(pinyin.rawValue, cjkv: true)]
        )
        let monitor = MockFrontmostMonitor(bundleID: "com.apple.Safari")
        let urls = MockBrowserURLProvider(url: "https://github.com/x")
        let engine = LockEngine(provider: provider, appMonitor: monitor, urlProvider: urls)
        engine.start()
        engine.apply(LockConfiguration(
            isEnabled: true,
            defaultSourceID: us,
            enhancedModeEnabled: true,
            urlRules: [
                URLRule(hostPattern: "github.com", lockedSourceID: abc),
                URLRule(hostPattern: "translate.google.com", lockedSourceID: pinyin),
            ]
        ))
        #expect(provider.current == abc) // github rule

        // Navigate to a different URL; the engine re-reads it on re-activation
        // (the same path the URL poll uses).
        urls.url = "https://translate.google.com/?sl=en"
        monitor.activate("com.apple.Safari")
        #expect(provider.current == pinyin) // re-resolved to the google rule
    }

    @Test("URL rules are ignored when enhanced mode is off")
    func enhancedDisabledIgnoresURL() {
        let pinyin: InputSourceID = "com.apple.inputmethod.SCIM.ITABC"
        let provider = MockInputSourceProvider(
            current: us,
            sources: [.stub(us.rawValue), .stub(abc.rawValue), .stub(pinyin.rawValue, cjkv: true)]
        )
        let monitor = MockFrontmostMonitor(bundleID: "com.apple.Safari")
        let urls = MockBrowserURLProvider(url: "https://github.com/x")
        let engine = LockEngine(provider: provider, appMonitor: monitor, urlProvider: urls)
        engine.start()

        engine.apply(LockConfiguration(
            isEnabled: true,
            defaultSourceID: us,
            appRules: [AppRule(bundleID: "com.apple.Safari", mode: .locked, lockedSourceID: abc)],
            enhancedModeEnabled: false,
            urlRules: [URLRule(hostPattern: "github.com", lockedSourceID: pinyin)]
        ))
        #expect(provider.current == abc) // app rule applies; URL rule ignored
    }

    @Test("activating an ignored app disengages locking")
    func ignoredAppDisengages() {
        let (engine, provider, monitor) = makeEngine(current: abc, frontmost: "com.game.App")
        engine.apply(LockConfiguration(
            isEnabled: true,
            defaultSourceID: us,
            appRules: [AppRule(bundleID: "com.game.App", mode: .ignored)]
        ))
        // game app is ignored → no enforcement, current untouched
        #expect(provider.selectCalls.isEmpty)
        #expect(provider.current == abc)

        // switching to a normal app re-engages the default
        monitor.activate("com.other.App")
        #expect(provider.current == us)
    }
}
