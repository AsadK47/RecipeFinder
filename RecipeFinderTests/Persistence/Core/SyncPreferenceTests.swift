import Testing
import Foundation
@testable import RecipeFinder

/// The Settings "iCloud sync" switch (Data safety 2/4): opt-in, applied only at launch, kept through Reset.
@Suite struct SyncPreferenceTests {
    private func makeStorage() -> LocalStore {
        // A fresh, uniquely named suite: never the shared defaults.
        LocalStore(userDefaults: UserDefaults(suiteName: "SyncPreferenceTests.\(UUID().uuidString)")!)
    }

    @Test func syncIsOffOnAFreshInstall() {
        let storage = makeStorage()
        #expect(!SyncPreference.isWanted(in: storage))
        #expect(!SyncPreference.applyAtLaunch(in: storage))
        #expect(!SyncPreference.isOn(in: storage))
    }

    @Test func flippingTheSwitchLeavesThisLaunchsRulesAlone() {
        let storage = makeStorage()
        SyncPreference.setWanted(true, in: storage)
        #expect(SyncPreference.isWanted(in: storage))
        #expect(!SyncPreference.isOn(in: storage))
    }

    @Test func theSwitchTakesEffectAtTheNextLaunch() {
        let storage = makeStorage()
        SyncPreference.setWanted(true, in: storage)
        #expect(SyncPreference.applyAtLaunch(in: storage))
        #expect(SyncPreference.isOn(in: storage))

        SyncPreference.setWanted(false, in: storage)
        #expect(SyncPreference.isOn(in: storage))
        #expect(!SyncPreference.applyAtLaunch(in: storage))
        #expect(!SyncPreference.isOn(in: storage))
    }

    @Test func aDeviceThatAlreadyHadSyncOnKeepsIt() {
        let storage = makeStorage()
        storage.set(true, forKey: SyncPreference.key)
        #expect(SyncPreference.isWanted(in: storage))
        #expect(SyncPreference.applyAtLaunch(in: storage))
    }

    @Test(arguments: [true, false])
    func resetKeepsTheSyncChoice(on: Bool) {
        let storage = makeStorage()
        SyncPreference.setWanted(on, in: storage)
        SyncPreference.applyAtLaunch(in: storage)
        storage.set("x", forKey: "someList")

        storage.clearAll(keeping: SyncPreference.keptThroughReset)

        #expect(storage.string(forKey: "someList") == nil)
        #expect(SyncPreference.isOn(in: storage) == on)
        #expect(SyncPreference.isWanted(in: storage) == on)
        #expect(SyncPreference.hasEverSynced(in: storage) == on)
    }

    @Test func aDeviceThatSyncedOnceRemembersItAfterTurningSyncOff() {
        let storage = makeStorage()
        SyncPreference.setWanted(true, in: storage)
        SyncPreference.applyAtLaunch(in: storage)
        SyncPreference.setWanted(false, in: storage)
        SyncPreference.applyAtLaunch(in: storage)

        #expect(!SyncPreference.isOn(in: storage))
        #expect(SyncPreference.hasEverSynced(in: storage))
    }

    @Test func aDeviceThatNeverSyncedSaysSo() {
        let storage = makeStorage()
        SyncPreference.applyAtLaunch(in: storage)
        #expect(!SyncPreference.hasEverSynced(in: storage))
    }

    // MARK: - Status line

    @Test func offWhenNeverTurnedOn() {
        #expect(SyncStatus(wanted: false, launchedOn: false, isSyncing: false, hasICloudAccount: nil) == .off)
    }

    @Test func turningOnWaitsForARestart() {
        #expect(SyncStatus(wanted: true, launchedOn: false, isSyncing: false, hasICloudAccount: nil) == .startsAfterRestart)
    }

    @Test func turningOffWaitsForARestart() {
        #expect(SyncStatus(wanted: false, launchedOn: true, isSyncing: true, hasICloudAccount: true) == .stopsAfterRestart)
    }

    @Test func onWhenTheStoreOpenedWithICloud() {
        #expect(SyncStatus(wanted: true, launchedOn: true, isSyncing: true, hasICloudAccount: true) == .on)
        #expect(SyncStatus(wanted: true, launchedOn: true, isSyncing: true, hasICloudAccount: nil) == .on)
    }

    @Test func offOnThisDeviceWhenTheStoreFellBackToLocal() {
        #expect(SyncStatus(wanted: true, launchedOn: true, isSyncing: false, hasICloudAccount: nil) == .unavailableHere)
    }

    @Test func asksToSignInWhenThereIsNoICloudAccount() {
        #expect(SyncStatus(wanted: true, launchedOn: true, isSyncing: true, hasICloudAccount: false) == .signInNeeded)
    }

    @Test(arguments: [SyncStatus.off, .on, .startsAfterRestart, .stopsAfterRestart, .unavailableHere, .signInNeeded])
    func everyStatusHasWords(status: SyncStatus) {
        #expect(!status.title.isEmpty)
        #expect(!status.detail.isEmpty)
    }

    @Test(arguments: [SyncStatus.on, .startsAfterRestart, .stopsAfterRestart, .unavailableHere, .signInNeeded])
    func resetWarnsItErasesEveryDeviceOnceSyncIsInPlay(status: SyncStatus) {
        #expect(status.resetErasesEveryDevice(everSynced: false))
    }

    @Test func resetWithSyncNeverOnErasesThisDeviceOnly() {
        #expect(!SyncStatus.off.resetErasesEveryDevice(everSynced: false))
    }

    @Test func resetAfterSyncWasTurnedOffStillWarnsAboutEveryDevice() {
        #expect(SyncStatus.off.resetErasesEveryDevice(everSynced: true))
    }
}
