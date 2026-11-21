import Testing
import SwiftUI
import ViewInspector
@testable import RecipeFinder

/// The one collapsible aisle header both halves of Groceries share (To buy and At home used to each draw their own).
@MainActor
@Suite struct GroceryCategoryHeaderTests {

    /// Holds the collapsed set the header writes to, so a tap's effect can be read back; single-threaded under `@MainActor`.
    private final class Box: @unchecked Sendable { var collapsed: Set<String> = [] }

    private func header(_ box: Box, count: String = "(2)") -> GroceryCategoryHeader {
        GroceryCategoryHeader(
            category: "Produce", count: count,
            collapsed: Binding(get: { box.collapsed }, set: { box.collapsed = $0 })
        )
    }

    @Test(arguments: ["(2)", "(1/3)"])
    func showsTheCategoryAndTheCountItIsGiven(count: String) throws {
        let view = try header(Box(), count: count).inspect()
        _ = try view.find(text: "Produce")
        _ = try view.find(text: count)
    }

    @Test func tapCollapsesThenExpandsItsCategoryOnly() throws {
        let box = Box()
        box.collapsed = ["Dairy & Eggs"]
        try header(box).inspect().find(ViewType.Button.self).tap()
        #expect(box.collapsed == ["Dairy & Eggs", "Produce"])
        try header(box).inspect().find(ViewType.Button.self).tap()
        #expect(box.collapsed == ["Dairy & Eggs"])
    }

    /// To buy's header showed a down chevron both ways (a down arrow, then an up arrow turned half round).
    @Test func chevronPointsUpOpenAndDownCollapsed() throws {
        let box = Box()
        let open = try header(box).inspect().find(ViewType.Image.self) { try $0.actualImage().name() == "chevron.up" }
        #expect(try open.rotation().angle.degrees == 0)
        box.collapsed = ["Produce"]
        let shut = try header(box).inspect().find(ViewType.Image.self) { try $0.actualImage().name() == "chevron.up" }
        #expect(try shut.rotation().angle.degrees == 180)
    }

    @Test func remainingCountReadsLeftOverTotal() {
        let items = [ShoppingListModel(name: "Onion", isChecked: true), ShoppingListModel(name: "Leek")]
        #expect(GroceryCategoryHeader.remainingCount(items) == "(1/2)")
    }
}
