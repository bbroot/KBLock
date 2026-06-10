import ServiceManagement
import Testing

@testable import LockIMEKit

@Suite("LoginItemState")
struct LoginItemStateTests {
    @Test("maps every SMAppService.Status case")
    func mapping() {
        #expect(LoginItemState(.enabled) == .enabled)
        #expect(LoginItemState(.notRegistered) == .disabled)
        #expect(LoginItemState(.requiresApproval) == .requiresApproval)
        #expect(LoginItemState(.notFound) == .notFound)
    }

    @Test("only .enabled is active")
    func isActive() {
        #expect(LoginItemState.enabled.isActive)
        #expect(!LoginItemState.disabled.isActive)
        #expect(!LoginItemState.requiresApproval.isActive)
        #expect(!LoginItemState.notFound.isActive)
        #expect(!LoginItemState.unknown.isActive)
    }
}
