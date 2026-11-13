import Testing
import CoreData
import Foundation
@testable import RecipeFinder

/// iCloud store setup (Data safety 2/4 slice 3a). The model check runs on the shipped model so a future model
/// version that CloudKit would refuse fails here, not on a cook's phone with sync on.
@MainActor
@Suite struct CloudSyncStoreTests {
    // MARK: - Store options

    @Test func withSyncOffTheStoreStaysOnThisDevice() {
        let description = NSPersistentStoreDescription()

        CloudSyncStore.configure(description, syncOn: false)

        #expect(description.cloudKitContainerOptions == nil)
    }

    @Test func withSyncOnTheStoreMirrorsToTheAppsICloudContainer() {
        let description = NSPersistentStoreDescription()

        CloudSyncStore.configure(description, syncOn: true)

        #expect(description.cloudKitContainerOptions?.containerIdentifier == "iCloud.com.asadkhan.recipefinder")
    }

    @Test(arguments: [false, true])
    func historyAndRemoteChangesAreAlwaysTracked(syncOn: Bool) {
        let description = NSPersistentStoreDescription()

        CloudSyncStore.configure(description, syncOn: syncOn)

        #expect(description.options[NSPersistentHistoryTrackingKey] as? NSNumber == true)
        #expect(description.options[NSPersistentStoreRemoteChangeNotificationPostOptionKey] as? NSNumber == true)
    }

    @Test func theAppsStoreIsSetUpWithSyncOffByDefault() throws {
        let controller = PersistenceController(inMemory: true)
        let description = try #require(controller.container.persistentStoreDescriptions.first)

        #expect(controller.container is NSPersistentCloudKitContainer)
        #expect(description.cloudKitContainerOptions == nil)
        #expect(description.options[NSPersistentHistoryTrackingKey] as? NSNumber == true)
        #expect(controller.isStoreLoaded)
    }

    // MARK: - Model check

    @Test func theShippedModelIsOneCloudKitAccepts() {
        let model = PersistenceController(inMemory: true).container.managedObjectModel

        #expect(CloudSyncStore.problems(in: model).isEmpty)
    }

    @Test func aRequiredAttributeWithNoDefaultIsReported() {
        let model = Self.model(attribute: { $0.isOptional = false })

        #expect(CloudSyncStore.problems(in: model) == ["Thing.title is required with no default"])
    }

    @Test func aRequiredAttributeWithADefaultIsAccepted() {
        let model = Self.model(attribute: { $0.isOptional = false; $0.defaultValue = "" })

        #expect(CloudSyncStore.problems(in: model).isEmpty)
    }

    @Test func aUniqueConstraintIsReported() {
        let model = Self.model(entity: { $0.uniquenessConstraints = [["title"]] })

        #expect(CloudSyncStore.problems(in: model) == ["Thing has a unique constraint"])
    }

    @Test func aRelationshipWithoutAnInverseIsReported() {
        let model = Self.model(entity: { entity in
            let relationship = NSRelationshipDescription()
            relationship.name = "parent"
            relationship.destinationEntity = entity
            relationship.maxCount = 1
            relationship.isOptional = true
            entity.properties.append(relationship)
        })

        #expect(CloudSyncStore.problems(in: model) == ["Thing.parent has no inverse"])
    }

    @Test func aRequiredOrderedDenyRelationshipReportsEachProblem() {
        let model = Self.model(entity: { entity in
            let children = NSRelationshipDescription()
            children.name = "children"
            children.destinationEntity = entity
            children.maxCount = 0
            children.isOptional = false
            children.isOrdered = true
            children.deleteRule = .denyDeleteRule
            let parent = NSRelationshipDescription()
            parent.name = "parent"
            parent.destinationEntity = entity
            parent.maxCount = 1
            parent.isOptional = true
            children.inverseRelationship = parent
            parent.inverseRelationship = children
            entity.properties.append(contentsOf: [children, parent])
        })

        #expect(CloudSyncStore.problems(in: model) == [
            "Thing.children is required",
            "Thing.children is ordered",
            "Thing.children uses the Deny delete rule",
        ])
    }

    private static func model(
        entity configureEntity: (NSEntityDescription) -> Void = { _ in },
        attribute configureAttribute: (NSAttributeDescription) -> Void = { _ in }
    ) -> NSManagedObjectModel {
        let attribute = NSAttributeDescription()
        attribute.name = "title"
        attribute.attributeType = .stringAttributeType
        attribute.isOptional = true
        configureAttribute(attribute)
        let entity = NSEntityDescription()
        entity.name = "Thing"
        entity.properties = [attribute]
        configureEntity(entity)
        let model = NSManagedObjectModel()
        model.entities = [entity]
        return model
    }
}
