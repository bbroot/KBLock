import Foundation

/// Integration facade tying together the input-source provider, the lock state
/// machine, the change observer, and the frontmost-app monitor. Driven entirely
/// by a `LockConfiguration`; the testable logic lives in `LockController` and
/// `RuleResolver`.
@MainActor
public final class LockEngine {
    private let provider: any InputSourceProviding
    private let controller: LockController
    private let observer: InputSourceChangeObserver
    private let enabledSourcesObserver: InputSourceChangeObserver
    private let appMonitor: any FrontmostAppMonitoring
    private let floatingAppMonitor: any FloatingAppMonitoring

    /// Fired after every successful forced switch.
    public var onActivation: (@MainActor (ActivationEvent) -> Void)?
    /// Fired whenever the displayed current-source name may have changed.
    public var onCurrentSourceChange: (@MainActor (String) -> Void)?
    /// Fired when the frontmost app changes.
    public var onFrontmostChange: (@MainActor (String?) -> Void)?
    /// Fired when the system's enabled input sources change (e.g. the user adds
    /// or removes one in System Settings), with the refreshed selectable list.
    public var onSelectableSourcesChange: (@MainActor ([InputSource]) -> Void)?

    private var config: LockConfiguration = .default
    private var frontmostBundleID: String?
    /// The launcher overlay (Spotlight, Raycast, …) currently holding keyboard
    /// focus, if any. It shadows `frontmostBundleID` for rule resolution because
    /// macOS leaves the frontmost app unchanged while an overlay is up.
    private var launcherBundleID: String?

    /// The app rules should resolve against right now: the focused launcher
    /// overlay when one is up, otherwise the `NSWorkspace` frontmost app.
    private var effectiveBundleID: String? { launcherBundleID ?? frontmostBundleID }

    public var activationCount: Int { controller.activationCount }

    public init(
        provider: (any InputSourceProviding)? = nil,
        appMonitor: (any FrontmostAppMonitoring)? = nil,
        floatingAppMonitor: (any FloatingAppMonitoring)? = nil
    ) {
        let provider = provider ?? TISInputSourceProvider()
        self.provider = provider
        self.controller = LockController(provider: provider)
        self.observer = InputSourceChangeObserver()
        self.enabledSourcesObserver = InputSourceChangeObserver(.enabledSourcesChanged)
        self.appMonitor = appMonitor ?? AppActivationMonitor()
        self.floatingAppMonitor = floatingAppMonitor ?? FloatingAppMonitor()
        self.controller.onActivation = { [weak self] event in
            self?.onActivation?(event)
        }
    }

    public func start() {
        frontmostBundleID = appMonitor.currentBundleID()
        observer.start { [weak self] in self?.handleSourceChange() }
        enabledSourcesObserver.start { [weak self] in self?.handleEnabledSourcesChange() }
        appMonitor.start { [weak self] id in self?.handleFrontmostChange(id) }
        floatingAppMonitor.start { [weak self] id in self?.handleLauncherChange(id) }
        notifyCurrent()
    }

    public func stop() {
        observer.stop()
        enabledSourcesObserver.stop()
        appMonitor.stop()
        floatingAppMonitor.stop()
    }

    /// Re-attempt launcher-overlay observer attachment. macOS doesn't notify us
    /// when Accessibility is granted, so the app calls this once it detects the
    /// grant — only then can the overlay observers attach.
    public func accessibilityDidChange() {
        floatingAppMonitor.refresh()
    }

    /// Apply a configuration: update rules/default, set master enable, and
    /// re-resolve + enforce the appropriate target for the frontmost app.
    ///
    /// `reason` attributes the enforcing force to its cause — a config edit
    /// (`.configChanged`, the default), turning the master toggle on
    /// (`.lockEngaged`), or the launch/restore apply (`.startupApplied`). It
    /// flows into both the target re-resolution and the enable-time enforce,
    /// since whichever fires is the one that emits the activation event.
    public func apply(_ config: LockConfiguration, reason: ActivationReason = .configChanged) {
        self.config = config
        // Order matters so disabling is side-effect free. When enabling (or
        // re-applying while on), set the target first, then enforce. When
        // disabling, stop enforcing *first* — otherwise reevaluate could force
        // one last switch under the still-enabled state before the lock turns
        // off (e.g. the source has drifted off target and the revert is pending).
        if config.isEnabled {
            reevaluate(reason: reason)                       // set target
            controller.setEnabled(true, reason: reason)      // then enforce on enable
        } else {
            controller.setEnabled(false, reason: reason)     // stop enforcing first
            reevaluate(reason: reason)                       // update cached target only
        }
        notifyCurrent()
    }

    public func selectableSources() -> [InputSource] { provider.selectableSources() }

    public func currentSourceID() -> InputSourceID? { provider.currentSourceID() }

    public func currentSourceName() -> String {
        guard let id = provider.currentSourceID() else { return "—" }
        return provider.source(for: id)?.localizedName ?? id.rawValue
    }

    // MARK: - Internal event handling

    private func handleSourceChange() {
        controller.selectedSourceDidChange()
        notifyCurrent()
    }

    private func handleEnabledSourcesChange() {
        onSelectableSourcesChange?(provider.selectableSources())
    }

    private func handleFrontmostChange(_ bundleID: String?) {
        frontmostBundleID = bundleID
        // A normal app activating means no launcher overlay is up (overlays
        // never raise an activation), so clear any stale launcher attribution.
        launcherBundleID = nil
        onFrontmostChange?(effectiveBundleID)
        reevaluate(reason: .appActivated)
        notifyCurrent()
    }

    /// A launcher overlay (Spotlight, Raycast, …) took or released keyboard
    /// focus. While it holds focus, rules resolve against *it* rather than the
    /// unchanged frontmost app; `nil` reverts to the frontmost app.
    private func handleLauncherChange(_ bundleID: String?) {
        launcherBundleID = bundleID
        onFrontmostChange?(effectiveBundleID)
        reevaluate(reason: bundleID != nil ? .launcherFocused : .launcherDismissed)
        notifyCurrent()
    }

    private func reevaluate(reason: ActivationReason) {
        switch RuleResolver.resolve(config: config, frontmostBundleID: effectiveBundleID) {
        case .lock(let id, let ruleSource):
            controller.setTarget(
                id,
                reason: reason,
                bundleID: effectiveBundleID,
                ruleSource: ruleSource
            )
        case .ignore, .noTarget:
            controller.setTarget(nil)
        }
    }

    private func notifyCurrent() {
        onCurrentSourceChange?(currentSourceName())
    }
}
