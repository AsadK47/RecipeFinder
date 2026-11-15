import Foundation

/// How the recipe's ingredient checklist is laid out while you gather: rows still to get stay on top in recipe order
/// under their group titles, and ticked rows move into a "Got it" group at the bottom (also in recipe order).
enum IngredientChecklist {

    enum Entry: Hashable, Identifiable {
        /// A group title ("For the sauce"); `groupStart` is the group's first row in the recipe, so the id is stable
        /// while rows inside the group are ticked off.
        case groupTitle(String, groupStart: Int)
        case gotItTitle(count: Int)
        case row(index: Int, isTicked: Bool)

        // Rows keep their recipe index as identity, so SwiftUI animates a ticked row sliding down rather than
        // rebuilding the list.
        var id: String {
            switch self {
            case .groupTitle(_, let groupStart): "group-\(groupStart)"
            case .gotItTitle: "got-it"
            case .row(let index, _): "row-\(index)"
            }
        }
    }

    /// The checklist in display order. `ticked` may be shorter than `sections` for one frame after an edit (the
    /// parent resizes it in `onChange`); missing ticks read as not ticked.
    static func entries(sections: [String?], ticked: [Bool]) -> [Entry] {
        let isTicked = { (index: Int) in ticked.indices.contains(index) && ticked[index] }
        var toGet: [Entry] = []
        var gotIt: [Entry] = []
        var groupStart = 0
        var titleShown = false
        for (index, section) in sections.enumerated() {
            if index == 0 || sections[index - 1] != section {
                groupStart = index
                titleShown = false
            }
            if isTicked(index) {
                gotIt.append(.row(index: index, isTicked: true))
                continue
            }
            if let section, !titleShown {
                toGet.append(.groupTitle(section, groupStart: groupStart))
                titleShown = true
            }
            toGet.append(.row(index: index, isTicked: false))
        }
        guard !gotIt.isEmpty else { return toGet }
        return toGet + [.gotItTitle(count: gotIt.count)] + gotIt
    }

    /// True once every ingredient is ticked — the moment to offer cooking mode.
    static func isAllSet(count: Int, ticked: [Bool]) -> Bool {
        count > 0 && ticked.count >= count && ticked.prefix(count).allSatisfy { $0 }
    }

    /// The row whose circle pulses to show it can be tapped: the first one, until the cook has ticked a row once.
    static func pulseIndex(count: Int, hasTickedBefore: Bool) -> Int? {
        !hasTickedBefore && count > 0 ? 0 : nil
    }
}
