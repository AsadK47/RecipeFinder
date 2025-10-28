//
//  PersistenceControllerTests.swift
//  RecipeFinderTests
//
//  Simplified unit tests for PersistenceController

import XCTest
import CoreData
@testable import RecipeFinder

final class PersistenceControllerTests: XCTestCase {
    
    // MARK: - Basic Initialization Tests
    
    func testSharedInstanceExists() throws {
        XCTAssertNotNil(PersistenceController.shared)
    }
    
    func testViewContextExists() throws {
        let controller = PersistenceController.shared
        XCTAssertNotNil(controller.container.viewContext)
    }
    
    func testContainerNameIsCorrect() throws {
        let controller = PersistenceController.shared
        XCTAssertEqual(controller.container.name, "RecipeModel")
    }
}
