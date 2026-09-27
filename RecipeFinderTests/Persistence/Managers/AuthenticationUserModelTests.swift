import Testing
import Foundation
@testable import RecipeFinder

/// `AuthenticationManager.User` presentation fallbacks: display name prefers full name → given name → email → "User"; initials prefer given+family → first two words of full name → "U".
@Suite struct AuthenticationUserModelTests {

    private func user(
        email: String? = nil,
        fullName: String? = nil,
        givenName: String? = nil,
        familyName: String? = nil
    ) -> AuthenticationManager.User {
        AuthenticationManager.User(
            id: "id",
            email: email,
            fullName: fullName,
            givenName: givenName,
            familyName: familyName,
            appleUserID: nil,
            createdAt: Date(),
            lastLoginAt: Date()
        )
    }

    // MARK: - displayName

    @Test func displayName_prefersFullName() {
        #expect(user(fullName: "Jane Doe", givenName: "Jane").displayName == "Jane Doe")
    }

    @Test func displayName_skipsEmptyFullName_fallsToGivenName() {
        #expect(user(fullName: "", givenName: "Jane").displayName == "Jane")
    }

    @Test func displayName_fallsToEmail_whenNoNames() {
        #expect(user(email: "a@b.com").displayName == "a@b.com")
    }

    @Test func displayName_defaultsToUser_whenNothingSet() {
        #expect(user().displayName == "User")
    }

    // MARK: - initials

    @Test func initials_useGivenAndFamilyInitials_uppercased() {
        #expect(user(givenName: "jane", familyName: "doe").initials == "JD")
    }

    @Test func initials_fallBackToFirstTwoWordsOfFullName() {
        #expect(user(fullName: "jane doe").initials == "JD")
    }

    @Test func initials_singleWordFullName_defaultsToU() {
        #expect(user(fullName: "Madonna").initials == "U")
    }

    @Test func initials_givenNameOnly_defaultsToU() {
        // The given+family branch needs both; given-name-only with no full name
        // falls through to the default.
        #expect(user(givenName: "Jane").initials == "U")
    }

    @Test func initials_defaultToU_whenNothingSet() {
        #expect(user().initials == "U")
    }
}
