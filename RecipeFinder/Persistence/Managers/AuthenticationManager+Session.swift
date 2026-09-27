import Foundation

/// Session status, expiry, and sign out.
extension AuthenticationManager {

    func checkAuthenticationStatus() {
        let authed = UserDefaults.standard.bool(forKey: isAuthenticatedKey)
        setAuthState(isAuthenticated: authed, user: currentUser)
        guard authed else { return }
        
        if let lastActive = UserDefaults.standard.object(forKey: lastActiveTimestampKey) as? Date,
           SessionExpiryPolicy.isExpired(lastActive: lastActive, timeout: sessionTimeoutSeconds) {
            let timeAway = Date().timeIntervalSince(lastActive)
            logger.debug("⏱️ Session expired after \(Int(timeAway))s away")
            signOut()
            return
        }
        
        loadUser()
        guard let user = currentUser else { return }
        
        UserScopedStorage.shared.currentUserId = user.id
        reloadAllManagers()
        updateLastActiveTimestamp()

        let personalSeedKey = "user_\(user.id)_personal_seeded"
        if !UserDefaults.standard.bool(forKey: personalSeedKey) {
            UserDefaults.standard.set(true, forKey: personalSeedKey)
            Task {
                let result = await PersonalRecipeSeedService().seed()
                if result.imported > 0 {
                    NotificationCenter.default.post(name: .userScopeDidChange, object: nil)
                }
            }
        }
    }

    func checkSessionExpiration() {
        guard isAuthenticated else { return }
        guard let lastActive = UserDefaults.standard.object(forKey: lastActiveTimestampKey) as? Date else { return }
        
        guard SessionExpiryPolicy.isExpired(lastActive: lastActive, timeout: sessionTimeoutSeconds) else { return }
        logger.debug("⏱️ Session expired - signing out")
        signOut()
    }

    func signOut() {
        logger.debug("🚪 Sign out initiated")
        
        UserScopedStorage.shared.currentUserId = nil
        
        setAuthState(isAuthenticated: false, user: nil)
        
        UserDefaults.standard.set(false, forKey: self.isAuthenticatedKey)
        UserDefaults.standard.removeObject(forKey: self.currentEmailKey)
        UserDefaults.standard.removeObject(forKey: self.lastActiveTimestampKey)
        
        self.logger.debug("✅ Sign out complete - UI should now show login screen")
        HapticManager.shared.light()
    }
}
