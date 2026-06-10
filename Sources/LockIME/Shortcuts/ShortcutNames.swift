import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// Global shortcut that toggles input-source locking on/off.
    /// `KeyboardShortcuts.Name` is an immutable name wrapper; safe as a constant.
    nonisolated(unsafe) static let toggleLock = Self("toggleLock")
}
