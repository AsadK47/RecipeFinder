//
//  PersistenceControllerTests.swift
//  RecipeFinderTests
//
//  Simplified unit tests for PersistenceController

import XCTest
import CoreData
@testable import RecipeFinder

final class PersistenceControllerTests: XCTestCase {
    
    func testSharedInstanceExists() {
        // When & Then
        XCTAssertNotNil(PersistenceController.shared)
    }
}
