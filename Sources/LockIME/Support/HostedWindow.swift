import AppKit
import SwiftUI

/// Closes the AppKit window currently hosting a SwiftUI view. Injected by
/// `HostedWindowController` so hosted content can dismiss itself without relying
/// on `\.dismiss` (which is unreliable for `NSHostingController`-backed windows).
struct CloseHostedWindowAction {
    fileprivate let action: () -> Void
    func callAsFunction() { action() }
}

extension EnvironmentValues {
    @Entry var closeHostedWindow = CloseHostedWindowAction(action: {})
}

/// Hosts a SwiftUI view in a single, reusable AppKit window. Because LockIME is
/// an accessory (menu-bar) app, windows opened from the menu must explicitly
/// activate the app and order front, or they appear *behind* whatever is
/// frontmost. This controller centralizes that so every auxiliary window comes
/// to the foreground reliably.
@MainActor
final class HostedWindowController {
    private var window: NSWindow?
    private var didCenter = false
    private var closeObserver: NSObjectProtocol?
    private let id: String
    /// Resolved on every `show()` (and via `refreshTitle()`) so the title
    /// follows the in-app language preference, which can change between opens.
    private let title: () -> String
    private let styleMask: NSWindow.StyleMask
    private let transparentTitleBar: Bool
    private let onClose: () -> Void
    private let makeContent: () -> AnyView

    init(
        id: String,
        title: @escaping () -> String,
        styleMask: NSWindow.StyleMask = [.titled, .closable],
        transparentTitleBar: Bool = false,
        onClose: @escaping () -> Void = {},
        content: @escaping () -> AnyView
    ) {
        self.id = id
        self.title = title
        self.styleMask = styleMask
        self.transparentTitleBar = transparentTitleBar
        self.onClose = onClose
        self.makeContent = content
    }

    /// Show (creating on first use), bring to front, and activate the app.
    func show() {
        let window = window ?? makeWindow()
        window.title = title()
        NSApp.activate(ignoringOtherApps: true)
        // Center only the first time, so a position the user dragged the window
        // to is preserved when it's reopened.
        if !didCenter {
            window.center()
            didCenter = true
        }
        window.makeKeyAndOrderFront(nil)
    }

    /// Re-resolve the title in the current language (no-op until the window
    /// exists). The hosted *content* re-localizes itself via observation; the
    /// AppKit title needs this explicit nudge.
    func refreshTitle() {
        window?.title = title()
    }

    func close() {
        window?.close()
    }

    private func makeWindow() -> NSWindow {
        let close = CloseHostedWindowAction(action: { [weak self] in self?.close() })
        let root = makeContent().environment(\.closeHostedWindow, close)
        let hosting = NSHostingController(rootView: root)
        hosting.sizingOptions = [.preferredContentSize]

        let window = NSWindow(contentViewController: hosting)
        window.title = title()
        window.styleMask = styleMask
        window.isReleasedWhenClosed = false
        window.identifier = NSUserInterfaceItemIdentifier("hosted.\(id)")
        if transparentTitleBar {
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
        }
        // App-lifetime controller, so this observer is never torn down.
        closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.onClose() }
        }
        self.window = window
        return window
    }
}
