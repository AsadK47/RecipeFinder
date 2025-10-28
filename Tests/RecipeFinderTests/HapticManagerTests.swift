//
//  HapticManagerTests.swift
//  RecipeFinderTests
//
//  Simplified unit tests for HapticManager

import XCTest
@testable import RecipeFinder

final class HapticManagerTests: XCTestCase {
    
    // MARK: - Singleton Tests
    
    func testSharedInstanceExists() throws {
        XCTAssertNotNil(HapticManager.shared)
    }
    
    func testSharedInstanceIsSingleton() throws {
        let instance1 = HapticManager.shared
        let instance2 = HapticManager.shared
        XCTAssertTrue(instance1 === instance2)
    }
}
