import Foundation

/// A recipe wizard step with a stable identity.
///
/// Steps were previously plain strings rendered with `ForEach(id: \.offset)`.
/// Offset-based identity crashes ("Swift/ContiguousArrayBuffer.swift: Index
/// out of range") when rows are added or removed while their TextField
/// bindings are live: rows keyed by offset outlive the array slot their
/// binding points at. A UUID identity keeps row and binding in sync.
struct EditableStep: Identifiable, Equatable {
    let id: UUID
    var text: String

    init(id: UUID = UUID(), text: String = "") {
        self.id = id
        self.text = text
    }
}

extension Array where Element == EditableStep {
    /// Wraps raw strings as steps; guarantees at least one editable row so
    /// the wizard always has a field to type into.
    static func steps(from texts: [String]) -> [EditableStep] {
        texts.isEmpty ? [EditableStep()] : texts.map { EditableStep(text: $0) }
    }

    /// The step texts with whitespace trimmed and blank rows dropped, in order.
    var nonEmptyTexts: [String] {
        map { $0.text.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
}
