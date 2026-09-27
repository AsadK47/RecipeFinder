import Foundation

/// Recipe wizard step with stable UUID identity; offset-based `ForEach` identity crashed when rows were added/removed with live TextField bindings.
struct EditableStep: Identifiable, Equatable {
    let id: UUID
    var text: String

    init(id: UUID = UUID(), text: String = "") {
        self.id = id
        self.text = text
    }
}

extension Array where Element == EditableStep {
    /// Wraps raw strings as steps; guarantees at least one editable row.
    static func steps(from texts: [String]) -> [EditableStep] {
        texts.isEmpty ? [EditableStep()] : texts.map { EditableStep(text: $0) }
    }

    /// The step texts with whitespace trimmed and blank rows dropped, in order.
    var nonEmptyTexts: [String] {
        map { $0.text.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
}
