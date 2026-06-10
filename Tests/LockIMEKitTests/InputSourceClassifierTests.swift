import Testing

@testable import LockIMEKit

@Suite("InputSourceClassifier")
struct InputSourceClassifierTests {
    @Test("CJKV languages are detected", arguments: [
        ["zh-Hans"], ["zh-Hant"], ["ja"], ["ko"], ["vi"], ["yue-Hans"], ["en", "zh"],
    ])
    func detectsCJKV(languages: [String]) {
        #expect(InputSourceClassifier.isCJKV(languages: languages))
    }

    @Test("non-CJKV languages are not flagged", arguments: [
        ["en"], ["fr"], ["de"], ["ru"], ["en-US"], [],
    ])
    func ignoresNonCJKV(languages: [String]) {
        #expect(!InputSourceClassifier.isCJKV(languages: languages))
    }
}
