import Foundation

/// Abstraction over the Text Input Sources layer.
///
/// The real implementation (`TISInputSourceProvider`) talks to Carbon; tests
/// inject a mock so the `LockController` state machine can be verified without
/// touching the system keyboard.
@MainActor
public protocol InputSourceProviding: AnyObject {
    /// The identifier of the currently active keyboard input source.
    func currentSourceID() -> InputSourceID?

    /// All enabled, selectable input sources (for pickers).
    func selectableSources() -> [InputSource]

    /// Metadata for a specific source, if present and selectable.
    func source(for id: InputSourceID) -> InputSource?

    /// Force-select the given source. Returns `true` on success.
    @discardableResult
    func select(_ id: InputSourceID) -> Bool
}
