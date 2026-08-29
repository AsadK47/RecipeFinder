import Testing
import Foundation
import os
@testable import RecipeFinder

@Suite("MemoCache")
struct MemoCacheTests {

    @Test("Computes once per key, then serves from cache")
    func computesOncePerKey() {
        let cache = MemoCache<String, Int>()
        let computeCount = OSAllocatedUnfairLock(initialState: 0)

        func lookup(_ key: String) -> Int {
            cache.value(for: key) { k in
                computeCount.withLock { $0 += 1 }
                return k.count
            }
        }

        #expect(lookup("apple") == 5)
        #expect(lookup("apple") == 5)
        #expect(lookup("apple") == 5)

        #expect(computeCount.withLock { $0 } == 1)
    }

    @Test("Distinct keys each compute and return their own value")
    func distinctKeys() {
        let cache = MemoCache<String, Int>()

        #expect(cache.value(for: "a") { $0.count } == 1)
        #expect(cache.value(for: "bb") { $0.count } == 2)
        #expect(cache.value(for: "ccc") { $0.count } == 3)
    }

    @Test("Recomputes a key after an overflow clear")
    func overflowClears() {
        let cache = MemoCache<Int, Int>(maxSize: 2)
        let computeCount = OSAllocatedUnfairLock(initialState: 0)

        func lookup(_ key: Int) -> Int {
            cache.value(for: key) { k in
                computeCount.withLock { $0 += 1 }
                return k * 10
            }
        }

        _ = lookup(1)                       // compute #1, size 1
        _ = lookup(2)                       // compute #2, size 2 (== maxSize)
        _ = lookup(3)                       // compute #3: count >= maxSize -> clear, then store (size 1)
        #expect(lookup(1) == 10)            // key 1 was dropped by the clear -> recompute #4
        #expect(computeCount.withLock { $0 } == 4)
    }
}
