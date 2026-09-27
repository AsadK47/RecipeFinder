import Foundation

/// Pure session-timeout rule extracted for unit-testing; expired once *more than* `timeout` seconds elapse since last activity (exactly `timeout` is still valid).
enum SessionExpiryPolicy {
    static func isExpired(
        lastActive: Date,
        now: Date = Date(),
        timeout: TimeInterval
    ) -> Bool {
        now.timeIntervalSince(lastActive) > timeout
    }
}
