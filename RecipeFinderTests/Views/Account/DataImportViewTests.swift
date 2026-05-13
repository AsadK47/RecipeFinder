import XCTest
@testable import RecipeFinder

final class DataImportViewTests: XCTestCase {

    // MARK: - MergeMode raw values

    func testMergeMode_rawValues() {
        XCTAssertEqual(DataImportView.MergeMode.replace.rawValue, "Replace All")
        XCTAssertEqual(DataImportView.MergeMode.merge.rawValue,   "Merge (Keep Both)")
    }

    func testMergeMode_allCasesCount() {
        XCTAssertEqual(DataImportView.MergeMode.allCases.count, 2)
    }

    func testMergeMode_descriptions() {
        let replace = DataImportView.MergeMode.replace
        XCTAssertTrue(replace.description.lowercased().contains("replace"),
                      "replace description should mention 'replace'")

        let merge = DataImportView.MergeMode.merge
        XCTAssertTrue(merge.description.lowercased().contains("keep"),
                      "merge description should mention 'keep'")
    }

    func testMergeMode_descriptionsAreDistinct() {
        XCTAssertNotEqual(DataImportView.MergeMode.replace.description,
                          DataImportView.MergeMode.merge.description)
    }

    // MARK: - ImportResult associated values

    func testImportResult_success() {
        let result = DataImportView.ImportResult.success("Imported 3 recipes")
        if case .success(let msg) = result {
            XCTAssertEqual(msg, "Imported 3 recipes")
        } else {
            XCTFail("Expected .success")
        }
    }

    func testImportResult_error() {
        let result = DataImportView.ImportResult.error("File not found")
        if case .error(let msg) = result {
            XCTAssertEqual(msg, "File not found")
        } else {
            XCTFail("Expected .error")
        }
    }

    func testImportResult_successAndErrorAreDistinct() {
        let success = DataImportView.ImportResult.success("ok")
        let error   = DataImportView.ImportResult.error("ok")
        // Verify they pattern-match to different cases
        var successMatched = false
        var errorMatched   = false
        if case .success = success { successMatched = true }
        if case .error   = error   { errorMatched   = true }
        XCTAssertTrue(successMatched)
        XCTAssertTrue(errorMatched)
    }
}
