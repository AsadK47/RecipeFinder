import Testing
@testable import RecipeFinder

@Suite("MealTimeReorder")
struct MealTimeReorderTests {
    @Test("Moving an item downward places it after the target")
    func movesDownwardAfterTarget() {
        let order: [MealTime] = [.breakfast, .lunch, .dinner]
        #expect(MealTimeReorder.moved(order, moving: .breakfast, to: .dinner) == [.lunch, .dinner, .breakfast])
    }

    @Test("Moving an item upward places it before the target")
    func movesUpwardBeforeTarget() {
        let order: [MealTime] = [.breakfast, .lunch, .dinner]
        #expect(MealTimeReorder.moved(order, moving: .dinner, to: .breakfast) == [.dinner, .breakfast, .lunch])
    }

    @Test("Adjacent downward move swaps the two")
    func adjacentSwap() {
        let order: [MealTime] = [.breakfast, .lunch, .dinner, .snack]
        #expect(MealTimeReorder.moved(order, moving: .lunch, to: .dinner) == [.breakfast, .dinner, .lunch, .snack])
    }

    @Test("Dropping an item onto itself is a no-op")
    func sameItemNoOp() {
        let order: [MealTime] = [.breakfast, .lunch, .dinner]
        #expect(MealTimeReorder.moved(order, moving: .lunch, to: .lunch) == order)
    }

    @Test("Items absent from the order leave it unchanged")
    func absentItemsNoOp() {
        let order: [MealTime] = [.breakfast, .lunch]
        #expect(MealTimeReorder.moved(order, moving: .dinner, to: .breakfast) == order)
        #expect(MealTimeReorder.moved(order, moving: .breakfast, to: .snack) == order)
    }
}
