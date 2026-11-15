import Foundation

/// How the recipe's ingredient checklist is laid out while you gather: rows still to get stay on top in recipe order
/// under their group titles, and ticked rows move into a "Got it" group at the bottom (also in recipe order).
enum IngredientChecklist {

    enum Entry: Hashable, Identifiable {
        /// A group title ("For the sauce"); `groupStart` is the group's first row in the recipe, so the id is stable
        /// while rows inside the group are ticked off.
        case groupTitle(String, groupStart: Int)
        /// Every row is in "Got it": offer cooking mode where the last rows were, so it appears under the finger.
        case allSetPrompt
        case gotItTitle(count: Int)
        case row(index: Int, isTicked: Bool)

        // Rows keep their recipe index as identity, so SwiftUI animates a ticked row sliding down rather than
        // rebuilding the list.
        var id: String {
            switch self {
            case .groupTitle(_, let groupStart): "group-\(groupStart)"
            case .allSetPrompt: "all-set"
            case .gotItTitle: "got-it"
            case .row(let index, _): "row-\(index)"
            }
        }
    }

    /// The checklist in display order. `ticked` drives each row's circle; `inGotIt` decides where it sits — the two
    /// differ while a fresh tick waits to settle (see `IngredientTicks`). A state array whose length doesn't match the
    /// rows (the frame after an edit, before the parent remaps it) reads as nothing ticked rather than wrong ticks.
    static func entries(sections: [String?], ticked: [Bool], inGotIt: [Bool]) -> [Entry] {
        let ticksFit = ticked.count == sections.count
        let placesFit = inGotIt.count == sections.count
        var toGet: [Entry] = []
        var gotIt: [Entry] = []
        var groupStart = 0
        var titleShown = false
        for (index, section) in sections.enumerated() {
            if index == 0 || sections[index - 1] != section {
                groupStart = index
                titleShown = false
            }
            let isTicked = ticksFit && ticked[index]
            if placesFit && inGotIt[index] {
                gotIt.append(.row(index: index, isTicked: isTicked))
                continue
            }
            if let section, !titleShown {
                toGet.append(.groupTitle(section, groupStart: groupStart))
                titleShown = true
            }
            toGet.append(.row(index: index, isTicked: isTicked))
        }
        guard !gotIt.isEmpty else { return toGet }
        let prompt: [Entry] = toGet.isEmpty && ticksFit && ticked.allSatisfy({ $0 }) ? [.allSetPrompt] : []
        return toGet + prompt + [.gotItTitle(count: gotIt.count)] + gotIt
    }

    /// Where VoiceOver goes after ticking `index`: the next row still to get below it in display order, wrapping
    /// to the top; nil when nothing is left.
    static func nextRowToGet(after index: Int, in entries: [Entry]) -> Int? {
        let rows: [(index: Int, isTicked: Bool)] = entries.compactMap { entry in
            guard case .row(let row, let isTicked) = entry else { return nil }
            return (row, isTicked)
        }
        guard let position = rows.firstIndex(where: { $0.index == index }) else { return nil }
        let wrapped = rows[(position + 1)...] + rows[..<position]
        return wrapped.first { !$0.isTicked }?.index
    }

    /// True once every ingredient is ticked. A state array that doesn't match the rows is never "all set".
    static func isAllSet(count: Int, ticked: [Bool]) -> Bool {
        count > 0 && ticked.count == count && ticked.allSatisfy { $0 }
    }

    /// How many recipe visits the pulse plays on at most. It can play while the ingredients are scrolled out of
    /// view, so it isn't spent on the first visit — but it stops for a cook who never ticks.
    static let maxPulses = 3

    /// The row whose circle pulses to show it can be tapped: the first one, until the cook has ticked a row once
    /// or it has played on `maxPulses` visits.
    static func pulseIndex(count: Int, hasTickedBefore: Bool, timesPulsed: Int) -> Int? {
        !hasTickedBefore && timesPulsed < maxPulses && count > 0 ? 0 : nil
    }
}

/// The recipe screen's ingredient ticks. A tap ticks a row in place at once; rows move into "Got it" only once the
/// cook has stopped tapping for `settleDelay` (each tap restarts the wait), so the next row never slides under a
/// finger that is still ticking.
struct IngredientTicks: Equatable {
    typealias Instant = ContinuousClock.Instant

    static let settleDelay: Duration = .seconds(1)

    /// What each row's circle shows.
    private(set) var ticked: [Bool]
    /// Which rows sit in "Got it" — `ticked` as of the last settle.
    private(set) var inGotIt: [Bool]
    /// When the pending ticks move into "Got it"; nil when nothing is waiting.
    private(set) var settleDeadline: Instant?

    init(count: Int) {
        ticked = Array(repeating: false, count: count)
        inGotIt = ticked
    }

    var isAllSet: Bool { IngredientChecklist.isAllSet(count: ticked.count, ticked: ticked) }

    mutating func toggle(_ index: Int, at now: Instant) {
        guard ticked.indices.contains(index) else { return }
        ticked[index].toggle()
        settleDeadline = now + Self.settleDelay
    }

    /// Moves the ticks into place once the wait since the last tap has passed; earlier calls change nothing.
    mutating func settleIfDue(at now: Instant) {
        guard let settleDeadline, now >= settleDeadline else { return }
        inGotIt = ticked
        self.settleDeadline = nil
    }

    /// After a recipe edit: ticks follow their ingredient (`ChecklistState.remap`) and settle at once, since the
    /// list is being redrawn anyway.
    mutating func remap(from oldIngredients: [Ingredient], to newIngredients: [Ingredient]) {
        ticked = ChecklistState.remap(ticked, from: oldIngredients, to: newIngredients)
        inGotIt = ticked
        settleDeadline = nil
    }
}
