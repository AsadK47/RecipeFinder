import CoreData
import Foundation

/// How the recipe database is set up for iCloud sync (Data safety 2/4). History tracking and remote-change
/// notifications are always on, so a store that later syncs already has the history CloudKit needs; the
/// CloudKit mirror itself is only attached while the cook's sync switch is on.
enum CloudSyncStore {
    static let containerIdentifier = "iCloud.com.asadkhan.recipefinder"

    static func configure(_ description: NSPersistentStoreDescription, syncOn: Bool) {
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description.cloudKitContainerOptions = syncOn
            ? NSPersistentCloudKitContainerOptions(containerIdentifier: containerIdentifier)
            : nil
    }

    /// Reasons CloudKit would refuse this model. CloudKit can't enforce unique constraints or required values
    /// across devices, so a model that has them fails to load with sync on — caught here, in tests, instead.
    static func problems(in model: NSManagedObjectModel) -> [String] {
        model.entities.sorted { ($0.name ?? "") < ($1.name ?? "") }.flatMap { entity -> [String] in
            let name = entity.name ?? "?"
            var found: [String] = []
            if !entity.uniquenessConstraints.isEmpty {
                found.append("\(name) has a unique constraint")
            }
            for attribute in entity.attributesByName.values.sorted(by: { $0.name < $1.name })
            where !attribute.isOptional && attribute.defaultValue == nil {
                found.append("\(name).\(attribute.name) is required with no default")
            }
            for relationship in entity.relationshipsByName.values.sorted(by: { $0.name < $1.name }) {
                if relationship.inverseRelationship == nil {
                    found.append("\(name).\(relationship.name) has no inverse")
                }
                if !relationship.isOptional {
                    found.append("\(name).\(relationship.name) is required")
                }
                if relationship.isOrdered {
                    found.append("\(name).\(relationship.name) is ordered")
                }
                if relationship.deleteRule == .denyDeleteRule {
                    found.append("\(name).\(relationship.name) uses the Deny delete rule")
                }
            }
            return found
        }
    }
}
