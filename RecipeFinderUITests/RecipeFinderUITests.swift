//
//  RecipeFinderUITests.swift
//  RecipeFinderUITests
//
//  Created by asad.e.khan on 10/12/2024.
//

import XCTest

final class RecipeFinderUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAppLaunches() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        
        // Verify the app launched successfully
        XCTAssertTrue(app.exists)
    }
}
