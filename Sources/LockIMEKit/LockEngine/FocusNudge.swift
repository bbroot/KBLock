import AppKit
import Foundation

/// CJKV input-method switching workaround (from macism/InputSourcePro):
/// a momentary, off-screen key window makes a `TISSelectInputSource` for a
/// CJKV source actually take effect, after which we restore the prior app.
@MainActor
enum FocusNudge {
    static func perform() {
        let previous = NSWorkspace.shared.frontmostApplication

        let window = NSWindow(
            contentRect: NSRect(x: -10_000, y: -10_000, width: 3, height: 3),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.alphaValue = 0
        window.ignoresMouseEvents = true
        window.level = .floating
        window.makeKeyAndOrderFront(nil)
        window.orderOut(nil)

        if let previous, previous.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            previous.activate()
        }
    }
}
