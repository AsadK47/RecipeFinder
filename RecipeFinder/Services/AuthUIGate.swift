import Foundation

/// Master switch for account / sign-in UI.
///
/// `false` = **guest-only** build: no sign-up / sign-in surfaces are shown; everyone uses the app
/// as a local guest. Flip to `true` once Sign in with Apple is live (needs paid Apple Developer
/// Program enrolment). Mirrors `PremiumGate.isEnabled`.
///
/// The auth engine (`AuthenticationManager` + the Authentication views) is kept intact behind this
/// flag, not deleted, so re-enabling is a one-line change. UI tests that cover the dormant auth flow
/// force it on with the DEBUG-only `-force-auth-ui` launch argument.
enum AuthUIGate {
    static var showAuthUI: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-force-auth-ui") { return true }
        #endif
        return false
    }
}
