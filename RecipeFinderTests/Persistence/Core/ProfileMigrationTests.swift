import Testing
import CoreData
import Foundation
import UIKit
@testable import RecipeFinder

/// Profile fake: one optional row, with switches to make reads or writes fail like a broken store.
@MainActor
final class InMemoryProfileStore: ProfileStoring {
    var record: ProfileRecord?
    var failWrites = false
    var failReads = false
    private(set) var writeCount = 0

    init(_ record: ProfileRecord? = nil) {
        self.record = record
    }

    func fetchProfile() throws -> ProfileRecord? {
        if failReads { throw ProfileStoreError.storeUnavailable }
        return record
    }

    func replaceProfile(with replacement: ProfileRecord?) throws {
        if failWrites { throw ProfileStoreError.storeUnavailable }
        writeCount += 1
        record = replacement
    }
}

/// Moving the profile out of its six `LocalStore` keys into `ProfileEntity` (Data safety 1/4, slice 3g). The shared
/// copy/fallback rules are covered by `CollectionMigrationTests` (same `MirroredSnapshot`); these pin the profile
/// wiring, the old per-field shape and the Core Data mapping.
@MainActor
@Suite struct ProfileMigrationTests {
    private let storage = LocalStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
    private let joined = Date(timeIntervalSinceReferenceDate: 815_000_000.25)
    private let photo = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x01, 0x02, 0x03])

    private var asad: ProfileRecord {
        ProfileRecord(
            uuid: "11111111-2222-3333-4444-555555555555", firstName: "Asad", lastName: "Khan",
            chefType: ChefType.baker.rawValue, createdDate: joined, imageData: photo
        )
    }

    /// What a build before this slice left behind: one key per field.
    private func writeOldKeys(_ record: ProfileRecord) {
        storage.set(record.uuid, forKey: ProfileManager.uuidKey)
        storage.set(record.firstName, forKey: ProfileManager.firstNameKey)
        storage.set(record.lastName, forKey: ProfileManager.lastNameKey)
        storage.set(record.chefType, forKey: ProfileManager.chefTypeKey)
        storage.set(record.createdDate, forKey: ProfileManager.createdDateKey)
        storage.set(record.imageData, forKey: ProfileManager.profileImageKey)
    }

    private var migrated: Bool {
        storage.bool(forKey: MirroredSnapshot<ProfileRecord>.flagKey(for: ProfileManager.uuidKey))
    }

    private func manager(_ store: any ProfileStoring) -> ProfileManager {
        ProfileManager(storage: storage, profileStore: store)
    }

    private func testImage() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
    }

    // MARK: - iCloud sync (Data safety 2/4)

    /// A profile another device started later and left unnamed (a new phone before the cook typed anything).
    private var newDevice: ProfileRecord {
        ProfileRecord(uuid: "00000000-new-device", createdDate: joined.addingTimeInterval(86_400))
    }

    @Test func withSyncOnANewDeviceTakesTheProfileAlreadyInICloud() {
        storage.set(true, forKey: SyncPreference.key)
        let store = InMemoryProfileStore(asad)
        let sut = manager(store)
        #expect(sut.uuid == asad.uuid)
        #expect(sut.firstName == "Asad")
        #expect(store.record == asad)
        #expect(store.writeCount == 0)
        #expect(storage.string(forKey: ProfileManager.uuidKey) == asad.uuid)
    }

    @Test func withSyncOnTheProfileInICloudReplacesThisDevicesOwn() {
        var sam = newDevice
        sam.firstName = "Sam"
        writeOldKeys(sam)
        let store = InMemoryProfileStore()
        _ = manager(store)
        store.record = asad   // the store settled on the shared profile once iCloud brought it in
        storage.set(true, forKey: SyncPreference.key)
        let sut = manager(store)
        #expect(sut.uuid == asad.uuid)
        #expect(sut.firstName == "Asad")
        #expect(store.record == asad)
        #expect(storage.string(forKey: ProfileManager.uuidKey) == asad.uuid)
        #expect(storage.string(forKey: ProfileManager.firstNameKey) == "Asad")
    }

    @Test func withSyncOnAnEditReachesTheSharedProfile() {
        storage.set(true, forKey: SyncPreference.key)
        let store = InMemoryProfileStore(asad)
        let sut = manager(store)
        sut.updateProfile(firstName: " Asad ", lastName: "K", chefType: .foodie)
        #expect(store.record?.uuid == asad.uuid)
        #expect(store.record?.lastName == "K")
        #expect(store.record?.chefType == ChefType.foodie.rawValue)
        #expect(store.record?.imageData == photo)
        #expect(storage.string(forKey: ProfileManager.lastNameKey) == "K")
    }

    @Test func withSyncOnAnotherDevicesEditIsTakenOnTheNextLaunch() {
        storage.set(true, forKey: SyncPreference.key)
        let store = InMemoryProfileStore(asad)
        _ = manager(store)
        store.record?.firstName = "Asadullah"   // edited on another device
        let sut = manager(store)
        #expect(sut.firstName == "Asadullah")
        #expect(store.record?.firstName == "Asadullah")
        #expect(storage.string(forKey: ProfileManager.firstNameKey) == "Asadullah")
    }

    @Test(arguments: [false, true])
    func aNamedProfileIsPickedOverANewDevicesEmptyOne(reversed: Bool) {
        let rows = reversed ? [asad, newDevice] : [newDevice, asad]
        #expect(ProfileRecord.shared(from: rows) == asad)
    }

    @Test(arguments: [false, true])
    func ofTwoNamedProfilesEveryDevicePicksTheOldest(reversed: Bool) {
        var later = newDevice
        later.firstName = "Sam"
        var older = asad
        older.uuid = "ffffffff-first-device"   // sorts after the later one: age decides, not the uuid
        let rows = reversed ? [older, later] : [later, older]
        #expect(ProfileRecord.shared(from: rows) == older)
    }

    @Test func profilesStartedAtTheSameMomentArePickedByUUID() {
        let first = ProfileRecord(uuid: "a", firstName: "A", createdDate: joined)
        let second = ProfileRecord(uuid: "b", firstName: "B", createdDate: joined)
        #expect(ProfileRecord.shared(from: [second, first]) == first)
        #expect(ProfileRecord.shared(from: [first, second]) == first)
    }

    @Test func aProfileWithAStartDateIsPickedOverOneWithout() {
        let undated = ProfileRecord(uuid: "a", firstName: "A")
        let dated = ProfileRecord(uuid: "b", firstName: "B", createdDate: joined)
        #expect(ProfileRecord.shared(from: [undated, dated]) == dated)
    }

    @Test func aPhotoTheChosenProfileDoesNotHaveIsNotTakenFromTheOther() {
        var bare = asad
        bare.imageData = nil   // removed by the cook
        var other = newDevice
        other.imageData = Data([0x01])
        #expect(ProfileRecord.shared(from: [other, bare]) == bare)
    }

    @Test func withSyncOnAnEditThatOnlyReachedTheKeptCopyIsAddedAndLaterEditsReachTheStore() {
        var sam = newDevice
        sam.firstName = "Sam"
        writeOldKeys(sam)
        let store = InMemoryProfileStore()
        _ = manager(store)
        store.record = asad
        let aheadKey = "keptCopyAhead.\(ProfileManager.uuidKey)"
        storage.set(true, forKey: aheadKey)   // this device's last save failed
        storage.set(true, forKey: SyncPreference.key)
        let sut = manager(store)
        #expect(sut.firstName == "Sam")
        #expect(store.record == sam)
        #expect(!storage.bool(forKey: aheadKey))
        sut.updateProfile(firstName: "Sam", lastName: "Lee", chefType: .baker)
        #expect(store.record?.lastName == "Lee")
    }

    @Test func noProfilesPickNothing() {
        #expect(ProfileRecord.shared(from: []) == nil)
    }

    // MARK: - Migration

    @Test func everyProfileKeyBecomesOneRowAndTheKeyIsMarked() {
        writeOldKeys(asad)
        let store = InMemoryProfileStore()
        let sut = manager(store)
        #expect(store.record == asad)
        #expect(sut.firstName == "Asad")
        #expect(sut.lastName == "Khan")
        #expect(sut.chefType == .baker)
        #expect(sut.uuid == asad.uuid)
        #expect(sut.loadProfileImage() == nil)   // not a decodable JPEG, but the bytes moved untouched
        #expect(migrated)
        #expect(storage.data(forKey: ProfileManager.profileImageKey) == photo)
    }

    @Test func aRealPhotoSurvivesTheMove() throws {
        let jpeg = try #require(testImage().jpegData(compressionQuality: 0.8))
        var withPhoto = asad
        withPhoto.imageData = jpeg
        writeOldKeys(withPhoto)
        let store = InMemoryProfileStore()
        _ = manager(store)
        #expect(store.record?.imageData == jpeg)
        #expect(manager(store).loadProfileImage() != nil)
    }

    @Test func aChefTypeThisBuildDoesNotKnowIsKeptButShowsAsHomeCook() {
        var future = asad
        future.chefType = "Pastry Wizard"
        writeOldKeys(future)
        let store = InMemoryProfileStore()
        let sut = manager(store)
        #expect(sut.chefType == .homeCook)
        #expect(store.record?.chefType == "Pastry Wizard")
    }

    @Test func aFreshInstallGetsANewProfileInTheStoreAndTheKeptCopy() {
        let store = InMemoryProfileStore()
        let sut = manager(store)
        #expect(!sut.uuid.isEmpty)
        #expect(store.record == ProfileRecord(uuid: sut.uuid))
        #expect(storage.string(forKey: ProfileManager.uuidKey) == sut.uuid)
        #expect(manager(store).uuid == sut.uuid)
    }

    @Test func withoutAKeptCopyTheStoresProfileStands() {
        let store = InMemoryProfileStore(asad)
        let sut = manager(store)
        #expect(sut.firstName == "Asad")
        #expect(store.record == asad)
    }

    @Test func aFailedWriteLeavesTheKeyUnmarkedAndTheCookKeepsTheirProfile() {
        writeOldKeys(asad)
        let store = InMemoryProfileStore()
        store.failWrites = true
        let sut = manager(store)
        #expect(!migrated)
        #expect(sut.firstName == "Asad")
        #expect(sut.chefType == .baker)
    }

    @Test func anUnreadableStoreFallsBackToTheKeptCopy() {
        writeOldKeys(asad)
        let store = InMemoryProfileStore(asad)
        store.failReads = true
        let sut = manager(store)
        #expect(sut.lastName == "Khan")
        #expect(!migrated)
    }

    @Test func anEditMadeWhileTheStoreFailsIsKeptNextLaunch() {
        let store = InMemoryProfileStore()
        let sut = manager(store)
        store.failWrites = true
        sut.updateProfile(firstName: "Sam", lastName: "Lee", chefType: .grillMaster)

        store.failWrites = false
        let nextLaunch = manager(store)
        #expect(nextLaunch.firstName == "Sam")
        #expect(nextLaunch.chefType == .grillMaster)
        #expect(store.record?.lastName == "Lee")
    }

    // MARK: - Manager on entities

    @Test func editsGoToTheStoreAndTheKeptCopyTrimmed() {
        let store = InMemoryProfileStore()
        let sut = manager(store)
        sut.updateProfile(firstName: "  Sam ", lastName: " Lee", chefType: .foodie)
        #expect(store.record?.firstName == "Sam")
        #expect(store.record?.lastName == "Lee")
        #expect(store.record?.chefType == ChefType.foodie.rawValue)
        #expect(storage.string(forKey: ProfileManager.firstNameKey) == "Sam")
        #expect(storage.string(forKey: ProfileManager.chefTypeKey) == ChefType.foodie.rawValue)
        #expect(manager(store).fullName == sut.fullName)
    }

    @Test func aPhotoIsSavedAndClearedInBothPlaces() {
        let store = InMemoryProfileStore()
        let sut = manager(store)
        sut.saveProfileImage(testImage())
        #expect(store.record?.imageData != nil)
        #expect(storage.data(forKey: ProfileManager.profileImageKey) != nil)
        #expect(manager(store).loadProfileImage() != nil)

        sut.clearProfileImage()
        #expect(store.record?.imageData == nil)
        #expect(storage.data(forKey: ProfileManager.profileImageKey) == nil)
        #expect(sut.loadProfileImage() == nil)
    }

    @Test func aCameraSizePhotoIsStoredSmall() throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let big = UIGraphicsImageRenderer(size: CGSize(width: 3000, height: 2000), format: format).image { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 3000, height: 2000))
        }
        let store = InMemoryProfileStore()
        manager(store).saveProfileImage(big)
        let data = try #require(store.record?.imageData)
        let stored = try #require(UIImage(data: data)?.cgImage)
        #expect(max(stored.width, stored.height) == ProfileManager.maxPhotoPixelSize)
        #expect(stored.width > stored.height)
    }

    @Test func aSmallPhotoIsNotUpscaled() throws {
        let small = testImage()
        let original = try #require(small.cgImage)
        let data = try #require(ProfileManager.storedPhotoData(for: small))
        let stored = try #require(UIImage(data: data)?.cgImage)
        #expect(stored.width == original.width)
        #expect(stored.height == original.height)
    }

    @Test func savingBackThePhotoMeJustLoadedWritesNothing() throws {
        // ProfileView's onChange saves whatever loadProfileImage() returned when Me appears.
        let jpeg = try #require(testImage().jpegData(compressionQuality: 0.8))
        var withPhoto = asad
        withPhoto.imageData = jpeg
        let store = InMemoryProfileStore(withPhoto)
        let sut = manager(store)
        let writes = store.writeCount
        sut.saveProfileImage(sut.loadProfileImage())
        #expect(store.writeCount == writes)
        #expect(store.record?.imageData == jpeg)

        sut.saveProfileImage(testImage())
        #expect(store.writeCount == writes + 1)
    }

    @Test func anUnchangedProfileIsNotRewrittenOnRelaunch() {
        writeOldKeys(asad)
        let store = InMemoryProfileStore()
        _ = manager(store)
        let writes = store.writeCount
        _ = manager(store)
        #expect(store.writeCount == writes)
    }

    @Test func resetAsSettingsRunsItClearsTheProfile() {
        // DataManagementSettingsView: LocalStore.clearAll() (drops keys + flags), then removeProfile().
        writeOldKeys(asad)
        let store = InMemoryProfileStore()
        let sut = manager(store)
        storage.clearAll()
        sut.removeProfile()
        #expect(sut.firstName.isEmpty)
        #expect(sut.chefType == .homeCook)
        #expect(sut.loadProfileImage() == nil)
        #expect(sut.uuid != asad.uuid)
        #expect(store.record == ProfileRecord(uuid: sut.uuid))
        #expect(manager(store).firstName.isEmpty)
    }

    @Test func aResetWhoseDeleteFailsIsFinishedNextLaunch() {
        let store = InMemoryProfileStore(asad)
        writeOldKeys(asad)
        let sut = manager(store)
        store.failWrites = true
        storage.clearAll()
        sut.removeProfile()
        #expect(sut.firstName.isEmpty)

        store.failWrites = false
        let nextLaunch = manager(store)
        #expect(nextLaunch.firstName.isEmpty)
        #expect(store.record?.firstName == "")
        #expect(store.record?.imageData == nil)
    }

    // MARK: - Core Data store (framework exemption: in-memory SQLite, like CoreDataStorePersistenceTests)

    @Test func coreDataStoreRoundTripsEveryField() throws {
        let sut = CoreDataProfileStore(persistence: PersistenceController(inMemory: true))
        try sut.replaceProfile(with: asad)
        #expect(try sut.fetchProfile() == asad)
    }

    @Test func coreDataStoreKeepsTodaysExactTime() throws {
        let now = ProfileRecord(uuid: "u", createdDate: Date())
        let sut = CoreDataProfileStore(persistence: PersistenceController(inMemory: true))
        try sut.replaceProfile(with: now)
        #expect(try sut.fetchProfile() == now)
    }

    @Test func coreDataStoreClearsOptionalFieldsAndUpdatesTheRowInPlace() throws {
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        let sut = CoreDataProfileStore(persistence: persistence)
        try sut.replaceProfile(with: asad)
        let request = NSFetchRequest<NSManagedObject>(entityName: CoreDataProfileStore.entityName)
        let before = try context.fetch(request)
        #expect(before.count == 1)
        #expect(before.first?.value(forKey: "id") is UUID)

        let cleared = ProfileRecord(uuid: asad.uuid)
        try sut.replaceProfile(with: cleared)
        #expect(try sut.fetchProfile() == cleared)
        #expect(try context.fetch(request).map { $0.objectID } == before.map { $0.objectID })
    }

    @Test func coreDataStoreRemovesTheProfile() throws {
        let persistence = PersistenceController(inMemory: true)
        let sut = CoreDataProfileStore(persistence: persistence)
        try sut.replaceProfile(with: asad)
        try sut.replaceProfile(with: nil)
        #expect(try sut.fetchProfile() == nil)
        let request = NSFetchRequest<NSManagedObject>(entityName: CoreDataProfileStore.entityName)
        #expect(try persistence.container.viewContext.count(for: request) == 0)
    }

    @Test func coreDataStoreIgnoresRowsWithoutAUUIDAndCleansUpDuplicates() throws {
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        let sut = CoreDataProfileStore(persistence: persistence)
        try sut.replaceProfile(with: asad)
        let entity = try #require(NSEntityDescription.entity(
            forEntityName: CoreDataProfileStore.entityName, in: context
        ))
        NSManagedObject(entity: entity, insertInto: context).setValue(UUID(), forKey: "id")   // no uuid
        let duplicate = NSManagedObject(entity: entity, insertInto: context)                  // a sync duplicate
        duplicate.setValue(UUID(), forKey: "id")
        duplicate.setValue("ffffffff-other-device", forKey: "uuid")
        try context.save()
        #expect(try sut.fetchProfile() == asad)

        try sut.replaceProfile(with: asad)
        let request = NSFetchRequest<NSManagedObject>(entityName: CoreDataProfileStore.entityName)
        #expect(try context.count(for: request) == 1)
        #expect(try sut.fetchProfile() == asad)
    }

    @Test func coreDataStoreReadsTheSharedProfileAndASaveLeavesOnlyIt() throws {
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        let sut = CoreDataProfileStore(persistence: persistence)
        var phone = newDevice
        phone.imageData = Data([0x01])
        try sut.replaceProfile(with: phone)
        let entity = try #require(NSEntityDescription.entity(
            forEntityName: CoreDataProfileStore.entityName, in: context
        ))
        let fromICloud = NSManagedObject(entity: entity, insertInto: context)
        fromICloud.setValue(UUID(), forKey: "id")
        fromICloud.setValue(asad.uuid, forKey: "uuid")
        fromICloud.setValue(asad.firstName, forKey: "firstName")
        fromICloud.setValue(asad.lastName, forKey: "lastName")
        fromICloud.setValue(asad.createdDate, forKey: "createdDate")
        try context.save()

        var expected = asad   // the older, named profile, as iCloud brought it in
        expected.chefType = nil
        expected.imageData = nil
        let shared = try #require(try sut.fetchProfile())
        #expect(shared == expected)

        try sut.replaceProfile(with: shared)
        let request = NSFetchRequest<NSManagedObject>(entityName: CoreDataProfileStore.entityName)
        #expect(try context.count(for: request) == 1)
        #expect(try sut.fetchProfile() == expected)
    }
}
