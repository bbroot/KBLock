import AppKit

/// Owns the shared `AppState` and starts the lock engine at launch. Using a
/// delegate guarantees startup runs even though menu-bar scenes are lazy.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        #if DEBUG
        // Headless self-test of the Accessibility grant UX. Skips engine startup
        // (no input-source side effects) and exits when done.
        if ProcessInfo.processInfo.environment["LOCKIME_AXFLOW_TEST"] == "1" {
            Task { @MainActor in
                await appState.runAccessibilityGrantSelfTest()
                NSApp.terminate(nil)
            }
            return
        }
        #endif
        appState.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        appState.stop()
    }
}
