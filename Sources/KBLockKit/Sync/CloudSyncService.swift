import Foundation
import OSLog

/// Syncs the lock configuration to iCloud via `NSUbiquitousKeyValueStore`.
/// Simple key-value approach: one key for the encoded config, one for a
/// monotonic timestamp so we can detect and merge conflicts.
///
/// Thread safety: all iCloud KV store operations must happen on the main
/// thread (the notification fires there). The class enforces this with
/// `@MainActor`.
@MainActor
public final class CloudSyncService {
    private static let log = Logger(subsystem: "com.bbroot.KBLock", category: "CloudSync")
    private static let configKey = "kbLockConfig"
    private static let timestampKey = "kbLockConfigTimestamp"

    private let store = NSUbiquitousKeyValueStore.default
    private let defaults: UserDefaults
    private let ruleStore: RuleStore

    /// The last known remote timestamp, used to avoid repeated merges.
    private var lastRemoteTimestamp: TimeInterval = 0
    /// If set, the remote data was strictly newer and we updated local config.
    public var onRemoteUpdate: ((LockConfiguration) -> Void)?

    public init(defaults: UserDefaults = .standard, ruleStore: RuleStore) {
        self.defaults = defaults
        self.ruleStore = ruleStore
        lastRemoteTimestamp = store.double(forKey: Self.timestampKey)
    }

    // MARK: - Push

    /// Push the current local config to iCloud. Call after every config change.
    public func push(config: LockConfiguration) {
        let timestamp = Date.now.timeIntervalSince1970
        guard let data = try? JSONEncoder().encode(config) else { return }
        store.set(data, forKey: Self.configKey)
        store.set(timestamp, forKey: Self.timestampKey)
        lastRemoteTimestamp = timestamp
        store.synchronize()
        Self.log.debug("Pushed config to iCloud (ts=\(timestamp))")
    }

    // MARK: - Pull (notification-driven)

    /// Call when `NSUbiquitousKeyValueStore.didChangeExternallyNotification`
    /// fires on the main thread. Returns `true` if local config was updated.
    @discardableResult
    public func handleRemoteChange() -> Bool {
        let remoteTimestamp = store.double(forKey: Self.timestampKey)
        guard remoteTimestamp > self.lastRemoteTimestamp else {
            Self.log.debug("Ignored stale/identical remote (ts=\(remoteTimestamp) ≤ local=\(self.lastRemoteTimestamp))")
            return false
        }

        guard let data = store.data(forKey: Self.configKey),
              let remoteConfig = try? JSONDecoder().decode(LockConfiguration.self, from: data)
        else {
            Self.log.error("Received invalid config from iCloud")
            return false
        }

        Self.log.info("Applied remote config from iCloud (ts=\(remoteTimestamp))")
        lastRemoteTimestamp = remoteTimestamp
        ruleStore.save(remoteConfig)
        onRemoteUpdate?(remoteConfig)
        return true
    }

    /// Synchronous initial pull at launch. If remote data is fresher, apply it.
    public func pullIfNewer() -> Bool {
        handleRemoteChange()
    }
}
