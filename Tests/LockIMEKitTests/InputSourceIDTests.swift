import Foundation
import Testing

@testable import LockIMEKit

@Suite("InputSourceID")
struct InputSourceIDTests {
    @Test("raw value round-trips through every initializer")
    func rawValue() {
        #expect(InputSourceID("com.apple.keylayout.US").rawValue == "com.apple.keylayout.US")
        #expect(InputSourceID(rawValue: "x").rawValue == "x")
        let literal: InputSourceID = "com.apple.keylayout.ABC"
        #expect(literal.rawValue == "com.apple.keylayout.ABC")
    }

    @Test("equality and hashing are value-based")
    func equality() {
        let a: InputSourceID = "com.apple.keylayout.ABC"
        let b = InputSourceID(rawValue: "com.apple.keylayout.ABC")
        #expect(a == b)
        #expect(Set([a, b]).count == 1)
    }

    @Test("Codable encodes as a bare string")
    func codable() throws {
        let id = InputSourceID("com.apple.inputmethod.SCIM.ITABC")
        let data = try JSONEncoder().encode(id)
        #expect(String(decoding: data, as: UTF8.self) == "\"com.apple.inputmethod.SCIM.ITABC\"")
        let decoded = try JSONDecoder().decode(InputSourceID.self, from: data)
        #expect(decoded == id)
    }
}
