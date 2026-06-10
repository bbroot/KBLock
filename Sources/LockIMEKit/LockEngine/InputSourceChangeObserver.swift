import Carbon
import Foundation

/// Observes the system-wide "selected keyboard input source changed"
/// distributed notification and invokes a handler on the main actor.
///
/// CFNotificationCenter's distributed center delivers on the run loop of the
/// registering thread; we register from the main actor, so delivery is on main.
@MainActor
public final class InputSourceChangeObserver {
    private var handler: (@MainActor () -> Void)?
    private var isRegistered = false

    public init() {}

    public func start(_ handler: @escaping @MainActor () -> Void) {
        guard !isRegistered else { return }
        self.handler = handler

        let observer = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDistributedCenter(),
            observer,
            { _, observer, _, _, _ in
                guard let observer else { return }
                let instance = Unmanaged<InputSourceChangeObserver>
                    .fromOpaque(observer)
                    .takeUnretainedValue()
                MainActor.assumeIsolated {
                    instance.handler?()
                }
            },
            kTISNotifySelectedKeyboardInputSourceChanged,
            nil,
            .deliverImmediately
        )
        isRegistered = true
    }

    public func stop() {
        guard isRegistered else { return }
        CFNotificationCenterRemoveEveryObserver(
            CFNotificationCenterGetDistributedCenter(),
            Unmanaged.passUnretained(self).toOpaque()
        )
        isRegistered = false
        handler = nil
    }

    deinit {
        CFNotificationCenterRemoveEveryObserver(
            CFNotificationCenterGetDistributedCenter(),
            Unmanaged.passUnretained(self).toOpaque()
        )
    }
}
