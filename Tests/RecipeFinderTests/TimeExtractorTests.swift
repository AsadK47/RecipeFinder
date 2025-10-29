//
//  TimeExtractorTests.swift
//  RecipeFinderTests
//
//  Small, focused tests for TimeExtractor utility

import XCTest
@testable import RecipeFinder

final class TimeExtractorTests: XCTestCase {
    
    // MARK: - Minutes Only Tests
    
    func testExtractSimpleMinutes() {
        // Given
        let timeString = "30 minutes"
        
        // When
        let result = TimeExtractor.extractMinutes(from: timeString)
        
        // Then
        XCTAssertEqual(result, 30)
    }
    
    func testExtractMinutesWithDifferentFormat() {
        // Given
        let timeString = "45 min"
        
        // When
        let result = TimeExtractor.extractMinutes(from: timeString)
        
        // Then
        XCTAssertEqual(result, 45)
    }
    
    func testExtractSingleMinute() {
        // Given
        let timeString = "1 minute"
        
        // When
        let result = TimeExtractor.extractMinutes(from: timeString)
        
        // Then
        XCTAssertEqual(result, 1)
    }
    
    // MARK: - Hours Only Tests
    
    func testExtractSimpleHour() {
        // Given
        let timeString = "1 hour"
        
        // When
        let result = TimeExtractor.extractMinutes(from: timeString)
        
        // Then
        XCTAssertEqual(result, 60)
    }
    
    func testExtractMultipleHours() {
        // Given
        let timeString = "2 hours"
        
        // When
        let result = TimeExtractor.extractMinutes(from: timeString)
        
        // Then
        XCTAssertEqual(result, 120)
    }
    
    // MARK: - Combined Hours and Minutes Tests
    
    func testExtractHourAndMinutes() {
        // Given
        let timeString = "1 hour 30 minutes"
        
        // When
        let result = TimeExtractor.extractMinutes(from: timeString)
        
        // Then
        XCTAssertEqual(result, 90)
    }
    
    func testExtractMultipleHoursAndMinutes() {
        // Given
        let timeString = "2 hours 15 minutes"
        
        // When
        let result = TimeExtractor.extractMinutes(from: timeString)
        
        // Then
        XCTAssertEqual(result, 135)
    }
    
    // MARK: - Invalid Input Tests
    
    func testExtractFromEmptyString() {
        // Given
        let timeString = ""
        
        // When
        let result = TimeExtractor.extractMinutes(from: timeString)
        
        // Then
        XCTAssertEqual(result, 0)
    }
    
    func testExtractFromInvalidString() {
        // Given
        let timeString = "invalid"
        
        // When
        let result = TimeExtractor.extractMinutes(from: timeString)
        
        // Then
        XCTAssertEqual(result, 0)
    }
    
    func testExtractFromStringWithNoNumbers() {
        // Given
        let timeString = "quick and easy"
        
        // When
        let result = TimeExtractor.extractMinutes(from: timeString)
        
        // Then
        XCTAssertEqual(result, 0)
    }
    
    // MARK: - Edge Case Tests
    
    func testExtractZeroMinutes() {
        // Given
        let timeString = "0 minutes"
        
        // When
        let result = TimeExtractor.extractMinutes(from: timeString)
        
        // Then
        XCTAssertEqual(result, 0)
    }
    
    func testExtractLargeNumber() {
        // Given
        let timeString = "300 minutes"
        
        // When
        let result = TimeExtractor.extractMinutes(from: timeString)
        
        // Then
        XCTAssertEqual(result, 300)
    }
}
