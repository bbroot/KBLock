import Foundation

/// Persists `LockConfiguration` to `UserDefaults` as JSON (small data, no
/// querying — SwiftData would be overkill here).
///
/// `UserDefaults` is thread-safe and `key` is immutable, so this is safely
/// `@unchecked Sendable`.
public final class RuleStore: @unchecked Sendable {
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = "lockConfiguration") {
        self.defaults = defaults
        self.key = key
    }

    public func load() -> LockConfiguration {
        guard let data = defaults.data(forKey: key),
              let config = try? JSONDecoder().decode(LockConfiguration.self, from: data)
        else {
            return .default
        }
        return config
    }

    public func save(_ config: LockConfiguration) {
        guard let data = try? JSONEncoder().encode(config) else { return }
        defaults.set(data, forKey: key)
    }
}
