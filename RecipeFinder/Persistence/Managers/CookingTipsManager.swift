import Combine
import Foundation

/// Manages cooking tips with filtering, searching, and favorites
@MainActor
final class CookingTipsManager: ObservableObject {
    static let shared = CookingTipsManager()
    private let logger = AppLogger.logger(category: "CookingTips")
    
    @Published private(set) var tips: [CookingTipModel] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: CookingTipCategory?
    @Published var selectedDifficulty: TipDifficulty?
    @Published var showFavoritesOnly: Bool = false
    
    private let saveKey = "cookingTipsStorage"
    private let storage = UserScopedStorage.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadTips()
        setupPublishers()
    }
    
    // MARK: - Publishers
    
    private func setupPublishers() {
        // Save tips whenever they change
        $tips
            .dropFirst() // Skip initial load
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveTips()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Computed Properties
    
    var filteredTips: [CookingTipModel] {
        var filtered = tips
        
        // Filter by favorites
        if showFavoritesOnly {
            filtered = filtered.filter { $0.isFavorite }
        }
        
        // Filter by category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Filter by difficulty
        if let difficulty = selectedDifficulty {
            filtered = filtered.filter { $0.difficulty == difficulty }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { tip in
                tip.title.localizedCaseInsensitiveContains(searchText) ||
                tip.content.localizedCaseInsensitiveContains(searchText) ||
                tip.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            }
        }
        
        return filtered.sorted { $0.createdDate > $1.createdDate }
    }
    
    var tipsByCategory: [CookingTipCategory: [CookingTipModel]] {
        Dictionary(grouping: tips) { $0.category }
    }
    
    var favoriteTips: [CookingTipModel] {
        tips.filter { $0.isFavorite }
    }
    
    // MARK: - CRUD Operations
    
    func addTip(_ tip: CookingTipModel) {
        tips.append(tip)
        HapticManager.shared.success()
    }
    
    func updateTip(_ tip: CookingTipModel) {
        guard let index = tips.firstIndex(where: { $0.id == tip.id }) else { return }
        tips[index] = tip
        HapticManager.shared.light()
    }
    
    func deleteTip(_ tip: CookingTipModel) {
        tips.removeAll { $0.id == tip.id }
        HapticManager.shared.medium()
    }
    
    func toggleFavorite(_ tip: CookingTipModel) {
        guard let index = tips.firstIndex(where: { $0.id == tip.id }) else { return }
        tips[index].isFavorite.toggle()
        HapticManager.shared.light()
    }
    
    // MARK: - Filtering
    
    func clearFilters() {
        selectedCategory = nil
        selectedDifficulty = nil
        showFavoritesOnly = false
        searchText = ""
    }
    
    func tipsForCategory(_ category: CookingTipCategory) -> [CookingTipModel] {
        tips.filter { $0.category == category }
    }
    
    func tipsForDifficulty(_ difficulty: TipDifficulty) -> [CookingTipModel] {
        tips.filter { $0.difficulty == difficulty }
    }
    
    // MARK: - Persistence
    
    func reloadForCurrentUser() {
        loadTips()
    }

    private func loadTips() {
        // Try to load saved tips first
        if let data = storage.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([CookingTipModel].self, from: data) {
            self.tips = decoded
            logger.debug("✅ Loaded \(self.tips.count) cooking tips")
        } else {
            // First time - populate with sample tips
            self.tips = CookingTipModel.samples
            saveTips()
            logger.debug("📚 Populated \(self.tips.count) sample cooking tips")
        }
    }
    
    private func saveTips() {
        if let encoded = try? JSONEncoder().encode(self.tips) {
            storage.set(encoded, forKey: saveKey)
        }
    }
    
    // MARK: - Utility
    
    func resetToSamples() {
        self.tips = CookingTipModel.samples
        saveTips()
        logger.debug("🔄 Reset to sample cooking tips")
    }
    
    func tipCount(for category: CookingTipCategory) -> Int {
        tips.filter { $0.category == category }.count
    }
}
