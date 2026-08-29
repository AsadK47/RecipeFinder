import Foundation
import os

/// Thread-safe memoization cache for pure functions.
///
/// Backed by an `OSAllocatedUnfairLock`, so it is safe under Swift 6 strict
/// concurrency. This exists to be the *easy, safe* replacement for the
/// `nonisolated(unsafe) static var` dictionaries that used to memoize hot
/// functions like ingredient normalization and category classification — those
/// were genuine data races, and deleting them (rather than making them safe)
/// caused a severe rendering-path performance regression.
///
/// Use it for deterministic, referentially-transparent work that is called often
/// with a small set of repeated inputs. It is **not** a general-purpose cache:
/// on overflow it simply clears itself, which keeps it allocation-cheap and
/// contention-free for the memoization use case.
final class MemoCache<Key: Hashable & Sendable, Value: Sendable>: Sendable {
    private let storage = OSAllocatedUnfairLock(initialState: [Key: Value]())
    private let maxSize: Int

    init(maxSize: Int = 200) {
        self.maxSize = maxSize
    }

    /// Returns the cached value for `key`, computing and storing it on a miss.
    ///
    /// `compute` runs outside the lock, so a slow computation never blocks other
    /// readers. Two threads racing on the same missing key may both compute it;
    /// that is harmless for pure functions and cheaper than holding the lock
    /// across the computation.
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
