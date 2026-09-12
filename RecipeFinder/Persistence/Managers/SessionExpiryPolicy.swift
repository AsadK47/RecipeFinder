import Foundation

/// The pure rule deciding whether an authenticated session has timed out.
///
/// Extracted from `AuthenticationManager`'s session checks so the policy is
/// unit-testable without touching `UserDefaults`, the Keychain, or the sign-out
/// side effects those methods perform. A session is expired once *more than*
/// `timeout` seconds have elapsed since the last recorded activity; exactly
/// `timeout` seconds is still valid, preserving the original
/// `timeAway <= sessionTimeoutSeconds` guard.
enum SessionExpiryPolicy {
    static func isExpired(
        lastActive: Date,
        now: Date = Date(),
        timeout: TimeInterval
    ) -> Bool {
        now.timeIntervalSince(lastActive) > timeout
    }
}
