import Foundation
import ServiceManagement

/// A normalized view of the app's login-item registration status.
public enum LoginItemState: Equatable, Sendable {
    case enabled
    case disabled
    case requiresApproval
    case notFound
    case unknown

    public init(_ status: SMAppService.Status) {
        switch status {
        case .enabled: self = .enabled
        case .notRegistered: self = .disabled
        case .requiresApproval: self = .requiresApproval
        case .notFound: self = .notFound
        @unknown default: self = .unknown
        }
    }

    public var isActive: Bool { self == .enabled }
}

/// Launch-at-login via `SMAppService.mainApp` (no helper bundle).
@MainActor
public final class LoginItemController {
    public init() {}

    /// Always read live — never cache (per Apple guidance).
    public var state: LoginItemState { LoginItemState(SMAppService.mainApp.status) }

    public var isEnabled: Bool { state.isActive }

    @discardableResult
    public func setEnabled(_ enabled: Bool) -> Result<Void, Error> {
        let service = SMAppService.mainApp
        do {
            if enabled {
                if service.status != .enabled { try service.register() }
            } else {
                if service.status == .enabled { try service.unregister() }
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}
