import Foundation

/// The cook's iCloud sync switch (Data safety 2/4), off until they turn it on in Settings.
///
/// Two keys: `wantedKey` is the switch; `key` is what this launch runs with (the CloudKit mirror and every list's
/// merge rules read it). The switch is copied over only at launch, before the database opens: the mirror is attached
/// when the store opens, and switching the rules to "this device's copy wins" while the store still syncs would
/// delete other devices' rows everywhere.
enum SyncPreference {
    static let key = "iCloudSyncEnabled"
    static let wantedKey = "iCloudSyncWanted"
    /// Set the first launch that runs with sync on; never cleared. Once a store has been mirrored, CloudKit sends
    /// its history (deletes included) whenever the mirror is attached again, so "off" no longer means "this device only".
    static let everSyncedKey = "iCloudSyncEverOn"
    /// Kept through Reset: forgetting the choice mid-launch would switch the rules against a syncing store.
    static let keptThroughReset: Set<String> = [key, wantedKey, everSyncedKey]

    /// What this launch runs with.
    static func isOn(in storage: LocalStore) -> Bool {
        storage.bool(forKey: key)
    }

    /// The Settings switch. Before the switch existed, a device with sync on wanted it on.
    static func isWanted(in storage: LocalStore) -> Bool {
        storage.object(forKey: wantedKey) == nil ? isOn(in: storage) : storage.bool(forKey: wantedKey)
    }

    static func setWanted(_ wanted: Bool, in storage: LocalStore) {
        storage.set(wanted, forKey: wantedKey)
    }

    /// Makes the switch this launch's setting. Call once, at launch, before `PersistenceController.shared` opens.
    @discardableResult
    static func applyAtLaunch(in storage: LocalStore) -> Bool {
        let wanted = isWanted(in: storage)
        storage.set(wanted, forKey: key)
        if wanted { storage.set(true, forKey: everSyncedKey) }
        return wanted
    }

    static func hasEverSynced(in storage: LocalStore) -> Bool {
        storage.bool(forKey: everSyncedKey) || isOn(in: storage)
    }
}

/// What Settings shows under the iCloud sync switch.
enum SyncStatus: Equatable, Sendable {
    case off
    case on
    case startsAfterRestart
    case stopsAfterRestart
    /// Sync is on, but the store wouldn't open with iCloud this launch and runs on this device alone.
    case unavailableHere
    case signInNeeded

    /// `hasICloudAccount`: nil while unknown (not checked yet, or sync isn't running).
    init(wanted: Bool, launchedOn: Bool, isSyncing: Bool, hasICloudAccount: Bool?) {
        switch (wanted, launchedOn) {
        case (false, false): self = .off
        case (false, true): self = .stopsAfterRestart
        case (true, false): self = .startsAfterRestart
        case (true, true):
            if !isSyncing {
                self = .unavailableHere
            } else if hasICloudAccount == false {
                self = .signInNeeded
            } else {
                self = .on
            }
        }
    }

    var title: String {
        switch self {
        case .off: "Off"
        case .on: "On"
        case .startsAfterRestart: "Turns on next time you open the app"
        case .stopsAfterRestart: "Turns off next time you open the app"
        case .unavailableHere: "Paused on this device"
        case .signInNeeded: "Sign in to iCloud to sync"
        }
    }

    var detail: String {
        switch self {
        case .off:
            "Turn on to keep your recipes, plans and lists in your own iCloud and on every device signed in to it. Recipe photos stay on this device for now."
        case .on:
            "Your recipes, plans and lists are kept in your iCloud and appear on every device signed in to it. Recipe photos stay on this device for now. Everything keeps working offline."
        case .startsAfterRestart:
            "Close RecipeFinder from the app switcher and open it again to start syncing."
        case .stopsAfterRestart:
            "Close RecipeFinder from the app switcher and open it again. Everything stays on this device; copies already in iCloud stay there."
        case .unavailableHere:
            "iCloud couldn't be reached when the app opened, so your library is working on this device. It will try again next time you open the app."
        case .signInNeeded:
            "Sign in to iCloud in the Settings app. Your library keeps working on this device meanwhile."
        }
    }

    /// Erasing a store that is, was or is about to be mirrored can erase the same data on every device: CloudKit
    /// exports the store's history, deletes included, once the mirror is attached. `.off` is only safe when sync
    /// has never been on here (`SyncPreference.hasEverSynced`).
    func resetErasesEveryDevice(everSynced: Bool) -> Bool {
        self != .off || everSynced
    }
}
