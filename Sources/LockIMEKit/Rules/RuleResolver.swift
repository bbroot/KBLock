import Foundation

/// The outcome of resolving which source (if any) to enforce right now.
public enum LockResolution: Equatable, Sendable {
    /// Enforce this source.
    case lock(InputSourceID)
    /// The frontmost app is explicitly ignored — do not enforce.
    case ignore
    /// No applicable target — locking is effectively idle.
    case noTarget
}

/// Pure resolution of the active lock target. Precedence:
/// enhanced URL match → per-app rule → global default.
public enum RuleResolver {
    public static func resolve(
        config: LockConfiguration,
        frontmostBundleID: String?,
        urlMatch: InputSourceID? = nil
    ) -> LockResolution {
        // 1. Enhanced mode (P6): a matched browser-URL rule wins outright.
        if let urlMatch {
            return .lock(urlMatch)
        }

        // 2. Per-app rule.
        if let bundleID = frontmostBundleID, let rule = config.rule(for: bundleID) {
            switch rule.mode {
            case .ignored:
                return .ignore
            case .locked:
                if let id = rule.lockedSourceID {
                    return .lock(id)
                }
                // "locked" with no source set → fall through to the default.
            case .useDefault:
                break
            }
        }

        // 3. Global default.
        if let def = config.defaultSourceID {
            return .lock(def)
        }
        return .noTarget
    }
}
