import CoreData
import Foundation

/// Where meal plans live once moved out of the `LocalStore` blob: Core Data in the app, a fake in tests.
@MainActor
protocol MealPlanStoring: AnyObject {
    /// Every stored plan, in list order.
    func fetchMealPlans() throws -> [MealPlanModel]
    /// Makes the store hold exactly these plans, in this order.
    func replaceMealPlans(with plans: [MealPlanModel]) throws
}

enum MealPlanStoreError: LocalizedError {
    case storeUnavailable

    var errorDescription: String? {
        switch self {
        case .storeUnavailable: "The recipe database isn't open."
        }
    }
}

/// `MealPlanEntity` rows (RecipeModel 16), one per plan, `sortOrder` = list position, updated in place by id like
/// `CoreDataCollectionStore`.
@MainActor
final class CoreDataMealPlanStore: MealPlanStoring {
    static let entityName = "MealPlanEntity"

    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    private func readyContext() throws -> NSManagedObjectContext {
        guard persistence.ensureStoreIsReady() else { throw MealPlanStoreError.storeUnavailable }
        return persistence.container.viewContext
    }

    private func fetchRows(in context: NSManagedObjectContext) throws -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: Self.entityName)
        request.sortDescriptors = [
            NSSortDescriptor(key: "sortOrder", ascending: true),
            NSSortDescriptor(key: "createdDate", ascending: true),
        ]
        return try context.fetch(request)
    }

    func fetchMealPlans() throws -> [MealPlanModel] {
        try fetchRows(in: readyContext()).compactMap(Self.plan(from:))
    }

    /// A row missing what a plan can't do without (ids, day) is skipped; anything else falls back to the
    /// struct's defaults, so one odd row never hides the rest of the week.
    private static func plan(from row: NSManagedObject) -> MealPlanModel? {
        guard let id = row.value(forKey: "id") as? UUID,
              let recipeId = row.value(forKey: "recipeId") as? UUID,
              let date = row.value(forKey: "date") as? Date else { return nil }
        return MealPlanModel(
            id: id,
            recipeId: recipeId,
            recipeName: row.value(forKey: "recipeName") as? String ?? "",
            date: date,
            mealTime: (row.value(forKey: "mealTime") as? String).flatMap(MealTime.init(rawValue:)) ?? .dinner,
            servings: (row.value(forKey: "servings") as? NSNumber)?.intValue ?? 4,
            notes: row.value(forKey: "notes") as? String,
            isCompleted: (row.value(forKey: "isCompleted") as? NSNumber)?.boolValue ?? false,
            isRecurring: (row.value(forKey: "isRecurring") as? NSNumber)?.boolValue ?? false,
            createdDate: row.value(forKey: "createdDate") as? Date ?? date,
            reminderTime: row.value(forKey: "reminderTime") as? Date
        )
    }

    func replaceMealPlans(with plans: [MealPlanModel]) throws {
        let context = try readyContext()
        guard let entity = NSEntityDescription.entity(forEntityName: Self.entityName, in: context) else {
            throw MealPlanStoreError.storeUnavailable
        }
        do {
            try apply(plans, entity: entity, in: context)
            if context.hasChanges { try context.save() }
        } catch {
            // Rolled back so half-applied rows don't ride along with the next unrelated save.
            context.rollback()
            throw error
        }
    }

    private func apply(_ plans: [MealPlanModel], entity: NSEntityDescription, in context: NSManagedObjectContext) throws {
        var rowsByID: [UUID: NSManagedObject] = [:]
        for row in try fetchRows(in: context) {
            // Rows without an id, or a second row with the same id, can't be matched to a plan.
            if let id = row.value(forKey: "id") as? UUID, rowsByID[id] == nil {
                rowsByID[id] = row
            } else {
                context.delete(row)
            }
        }
        for (index, plan) in plans.enumerated() {
            let row = rowsByID.removeValue(forKey: plan.id) ?? NSManagedObject(entity: entity, insertInto: context)
            row.setIfChanged(plan.id as NSUUID, forKey: "id")
            row.setIfChanged(plan.recipeId as NSUUID, forKey: "recipeId")
            row.setIfChanged(plan.recipeName as NSString, forKey: "recipeName")
            row.setIfChanged(plan.date as NSDate, forKey: "date")
            row.setIfChanged(plan.mealTime.rawValue as NSString, forKey: "mealTime")
            row.setIfChanged(NSNumber(value: Int64(plan.servings)), forKey: "servings")
            row.setIfChanged(plan.notes.map { $0 as NSString }, forKey: "notes")
            row.setIfChanged(NSNumber(value: plan.isCompleted), forKey: "isCompleted")
            row.setIfChanged(NSNumber(value: plan.isRecurring), forKey: "isRecurring")
            row.setIfChanged(plan.createdDate as NSDate, forKey: "createdDate")
            row.setIfChanged(plan.reminderTime.map { $0 as NSDate }, forKey: "reminderTime")
            row.setIfChanged(NSNumber(value: Int32(clamping: index)), forKey: "sortOrder")
        }
        for leftover in rowsByID.values { context.delete(leftover) }
    }
}
