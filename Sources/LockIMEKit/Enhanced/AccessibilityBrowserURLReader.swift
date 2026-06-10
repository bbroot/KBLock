import AppKit
import ApplicationServices

/// Reads the frontmost browser's active-tab URL via the Accessibility API.
///
/// Best-effort and browser-dependent: it walks the focused window looking for an
/// element exposing `kAXURLAttribute` (the `AXWebArea`). Requires Accessibility
/// to be granted; returns `nil` otherwise. Node visits are budget-capped so a
/// large page can't make traversal expensive.
@MainActor
public final class AccessibilityBrowserURLReader: BrowserURLProviding {
    private let visitBudget: Int

    public init(visitBudget: Int = 4000) {
        self.visitBudget = visitBudget
    }

    public func currentURL(forBundleID bundleID: String?) -> String? {
        guard BrowserBundleIDs.isBrowser(bundleID),
              AXIsProcessTrusted(),
              let app = NSWorkspace.shared.frontmostApplication,
              app.bundleIdentifier == bundleID
        else { return nil }

        let axApp = AXUIElementCreateApplication(app.processIdentifier)

        // Chromium browsers build their accessibility tree lazily; setting
        // `AXManualAccessibility` makes them expose the `AXWebArea`/`AXURL` for
        // non-VoiceOver clients like us. Safari needs no such opt-in.
        if BrowserBundleIDs.isChromium(bundleID) {
            AXUIElementSetAttributeValue(axApp, "AXManualAccessibility" as CFString, kCFBooleanTrue)
        }

        guard let window = element(axApp, kAXFocusedWindowAttribute) else { return nil }
        var budget = visitBudget
        return findURL(in: window, budget: &budget)
    }

    private func findURL(in element: AXUIElement, budget: inout Int) -> String? {
        guard budget > 0 else { return nil }
        budget -= 1

        var urlValue: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXURLAttribute as CFString, &urlValue) == .success {
            if let url = urlValue as? URL { return url.absoluteString }
            if let string = urlValue as? String, !string.isEmpty { return string }
        }

        var childrenValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenValue) == .success,
              let children = childrenValue as? [AXUIElement]
        else { return nil }

        for child in children {
            if let url = findURL(in: child, budget: &budget) { return url }
        }
        return nil
    }

    private func element(_ element: AXUIElement, _ attribute: String) -> AXUIElement? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let value, CFGetTypeID(value) == AXUIElementGetTypeID()
        else { return nil }
        // Safe: the CFGetTypeID check above guarantees this is an AXUIElement.
        return (value as! AXUIElement)
    }
}
