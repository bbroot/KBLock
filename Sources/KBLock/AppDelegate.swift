import AppKit

/// Owns the shared `AppState` and starts the lock engine at launch.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        #if DEBUG
        if ProcessInfo.processInfo.environment["KBLOCK_AXFLOW_TEST"] == "1" {
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
