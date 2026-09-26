import Foundation
import os

// Swift 6-safe replacement for `nonisolated(unsafe) static var` memo dicts (those were data races); clears on overflow rather than evicting. For pure functions called often with few repeated inputs.
final class MemoCache<Key: Hashable & Sendable, Value: Sendable>: Sendable {
    private let storage = OSAllocatedUnfairLock(initialState: [Key: Value]())
    private let maxSize: Int

    init(maxSize: Int = 200) {
        self.maxSize = maxSize
    }

    // `compute` runs outside the lock; racing threads may both compute a missing key — harmless for pure functions, cheaper than locking across the call.
    func value(for key: Key, compute: (Key) -> Value) -> Value {
        if let cached = storage.withLock({ $0[key] }) {
            return cached
        }

        let result = compute(key)

        storage.withLock { dict in
            if dict.count >= maxSize {
                dict.removeAll(keepingCapacity: true)
            }
            dict[key] = result
        }

        return result
    }
}
