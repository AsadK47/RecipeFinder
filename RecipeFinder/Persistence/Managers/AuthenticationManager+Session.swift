import Foundation

/// Session status, expiry, and sign out.
extension AuthenticationManager {

    func checkAuthenticationStatus() {
        let authed = UserDefaults.standard.bool(forKey: isAuthenticatedKey)
        setAuthState(isAuthenticated: authed, user: currentUser)
        guard authed else { return }
        
        if let lastActive = UserDefaults.standard.object(forKey: lastActiveTimestampKey) as? Date {
            let timeAway = Date().timeIntervalSince(lastActive)
            guard timeAway <= sessionTimeoutSeconds else {
                logger.debug("⏱️ Session expired after \(Int(timeAway))s away")
                signOut()
                return
            }
        }
        
        loadUser()
        guard let user = currentUser else { return }
        
        UserScopedStorage.shared.currentUserId = user.id
        reloadAllManagers()
        updateLastActiveTimestamp()
    }

    func checkSessionExpiration() {
        guard isAuthenticated else { return }
        guard let lastActive = UserDefaults.standard.object(forKey: lastActiveTimestampKey) as? Date else { return }
        
        let timeAway = Date().timeIntervalSince(lastActive)
        guard timeAway <= sessionTimeoutSeconds else {
            logger.debug("⏱️ Session expired - signing out")
            signOut()
            return
        }
    }

    func signOut() {
        logger.debug("🚪 Sign out initiated")
        
        if let email = UserDefaults.standard.string(forKey: currentEmailKey) {
            credentialManager.deleteSessionToken(for: email)
            logger.debug("🗑️ Deleted session token for: \(email)")
        }
        
        UserScopedStorage.shared.currentUserId = nil
        
        setAuthState(isAuthenticated: false, user: nil)
        
        UserDefaults.standard.set(false, forKey: self.isAuthenticatedKey)
        UserDefaults.standard.removeObject(forKey: self.currentEmailKey)
        UserDefaults.standard.removeObject(forKey: self.lastActiveTimestampKey)
        
        self.logger.debug("✅ Sign out complete - UI should now show login screen")
        HapticManager.shared.light()
    }
}
