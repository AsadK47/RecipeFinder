import Foundation

/// Represents an item in the kitchen inventory with expiration tracking and storage location
struct KitchenInventoryItemModel: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var category: IngredientCategory
    var quantity: Double
    var unit: String
    var storageLocation: StorageLocation
    var purchaseDate: Date
    var expiryDate: Date?
    var notes: String?
    var isLowStock: Bool
    var minimumQuantity: Double?
    
    init(
        id: UUID = UUID(),
        name: String,
        category: IngredientCategory,
        quantity: Double,
        unit: String,
        storageLocation: StorageLocation = .pantry,
        purchaseDate: Date = Date(),
        expiryDate: Date? = nil,
        notes: String? = nil,
        isLowStock: Bool = false,
        minimumQuantity: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.quantity = quantity
        self.unit = unit
        self.storageLocation = storageLocation
        self.purchaseDate = purchaseDate
        self.expiryDate = expiryDate
        self.notes = notes
        self.isLowStock = isLowStock
        self.minimumQuantity = minimumQuantity
    }
    
    // MARK: - Expiration Status
    
    /// Days until the item expires (negative if already expired)
    var daysUntilExpiry: Int? {
        guard let expiryDate = expiryDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expiryDate)
        return components.day
    }
    
    /// Whether the item is expiring soon (within 3 days)
    var isExpiringSoon: Bool {
        guard let days = daysUntilExpiry else { return false }
        return days >= 0 && days <= 3
    }
    
    /// Whether the item has expired
    var isExpired: Bool {
        guard let days = daysUntilExpiry else { return false }
        return days < 0
    }
    
    /// Status text for display
    var expiryStatusText: String {
        guard let days = daysUntilExpiry else { return "No expiry date" }
        
        if days < 0 {
            return "Expired \(abs(days)) day\(abs(days) == 1 ? "" : "s") ago"
        } else if days == 0 {
            return "Expires today"
        } else if days == 1 {
            return "Expires tomorrow"
        } else if days <= 3 {
            return "Expires in \(days) days"
        } else {
            return "Expires in \(days) days"
        }
    }
    
    /// Stock status check
    var needsRestock: Bool {
        guard let min = minimumQuantity else { return isLowStock }
        return quantity <= min
    }
}

// MARK: - Ingredient Categories

enum IngredientCategory: String, Codable, CaseIterable {
    case produce = "Produce"
    case dairy = "Dairy & Eggs"
    case meat = "Meat & Seafood"
    case grains = "Grains & Pasta"
    case spices = "Spices & Herbs"
    case condiments = "Condiments & Sauces"
    case beverages = "Beverages"
    case snacks = "Snacks"
    case frozen = "Frozen Foods"
    case canned = "Canned Goods"
    case baking = "Baking Supplies"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .produce: return "leaf.fill"
        case .dairy: return "drop.fill"
        case .meat: return "fork.knife"
        case .grains: return "basket.fill"
        case .spices: return "sparkles"
        case .condiments: return "eyedropper.full"
        case .beverages: return "cup.and.saucer.fill"
        case .snacks: return "bag.fill"
        case .frozen: return "snowflake"
        case .canned: return "cylinder.fill"
        case .baking: return "birthday.cake.fill"
        case .other: return "shippingbox.fill"
        }
    }
    
    /// Typical expiry duration in days for this category
    var typicalExpiryDays: Int {
        switch self {
        case .produce: return 7
        case .dairy: return 14
        case .meat: return 3
        case .grains: return 365
        case .spices: return 730
        case .condiments: return 180
        case .beverages: return 90
        case .snacks: return 60
        case .frozen: return 90
        case .canned: return 730
        case .baking: return 365
        case .other: return 30
        }
    }
}

// MARK: - Storage Locations

enum StorageLocation: String, Codable, CaseIterable {
    case pantry = "Pantry"
    case fridge = "Refrigerator"
    case freezer = "Freezer"
    case cabinet = "Cabinet"
    case counter = "Counter"
    
    var icon: String {
        switch self {
        case .pantry: return "cabinet.fill"
        case .fridge: return "refrigerator.fill"
        case .freezer: return "snowflake"
        case .cabinet: return "archivebox.fill"
        case .counter: return "square.grid.3x3.fill"
        }
    }
}

// MARK: - Sample Data

extension KitchenInventoryItemModel {
    static let samples = [
        KitchenInventoryItemModel(
            name: "Milk",
            category: .dairy,
            quantity: 1,
            unit: "gallon",
            storageLocation: .fridge,
            expiryDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())
        ),
        KitchenInventoryItemModel(
            name: "Chicken Breast",
            category: .meat,
            quantity: 2,
            unit: "lbs",
            storageLocation: .fridge,
            expiryDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())
        ),
        KitchenInventoryItemModel(
            name: "Rice",
            category: .grains,
            quantity: 5,
            unit: "lbs",
            storageLocation: .pantry,
            expiryDate: Calendar.current.date(byAdding: .day, value: 365, to: Date())
        ),
        KitchenInventoryItemModel(
            name: "Tomatoes",
            category: .produce,
            quantity: 6,
            unit: "count",
            storageLocation: .counter,
            expiryDate: Calendar.current.date(byAdding: .day, value: 4, to: Date())
        )
    ]
}
