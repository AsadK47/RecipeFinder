import Testing
import Foundation
@testable import RecipeFinder

/// The session-timeout rule extracted from `AuthenticationManager`. A session is
/// expired once *more than* `timeout` seconds have elapsed since last activity;
/// exactly `timeout` is still valid. These pin the boundary and the clock-skew
/// edge (activity timestamped in the future) so a refactor can't silently sign
/// users out early or keep a stale session alive.
@Suite struct SessionExpiryPolicyTests {

    private let timeout: TimeInterval = 86_400   // 24h, matching AuthenticationManager

    @Test(arguments: [
        (elapsed: 0.0,        expired: false),   // just active
        (elapsed: 3_600.0,    expired: false),   // an hour in
        (elapsed: 86_399.0,   expired: false),   // one second short of the limit
        (elapsed: 86_400.0,   expired: false),   // exactly the limit is still valid (<=)
        (elapsed: 86_400.001, expired: true),    // a hair past the limit
        (elapsed: 172_800.0,  expired: true),    // long gone
    ])
    func expiryTracksElapsedTimeAgainstTimeout(elapsed: TimeInterval, expired: Bool) {
        let lastActive = Date()
        let now = lastActive.addingTimeInterval(elapsed)

        #expect(SessionExpiryPolicy.isExpired(lastActive: lastActive, now: now, timeout: timeout) == expired)
    }

    @Test func futureLastActive_isNotExpired() {
        // Clock skew / a timestamp written slightly ahead: negative elapsed must
        // never read as expired.
        let now = Date()
        let lastActive = now.addingTimeInterval(500)

        #expect(SessionExpiryPolicy.isExpired(lastActive: lastActive, now: now, timeout: timeout) == false)
    }

    @Test func zeroTimeout_expiresAnyElapsedButNotTheSameInstant() {
        let lastActive = Date()

        #expect(SessionExpiryPolicy.isExpired(lastActive: lastActive, now: lastActive, timeout: 0) == false)
        #expect(SessionExpiryPolicy.isExpired(lastActive: lastActive, now: lastActive.addingTimeInterval(0.001), timeout: 0) == true)
    }
}
