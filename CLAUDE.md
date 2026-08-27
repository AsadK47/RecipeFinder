# RecipeFinder — Project Notes

## Repo
- GitHub: https://github.com/RecipeFinderLimited/RecipeFinder

## Business / Apple Developer account
- Business: RecipeFinder Limited (UK limited company)
- An Apple Account has been created using the business email, but has not yet been signed into Xcode.
- Plan: keep developing under the personal Apple ID (free personal team) for now. Only switch Xcode's signing over to the RecipeFinder Limited Apple Developer account when the app is ready for TestFlight/App Store distribution.
- Enrolling the business account as an Organization on the Apple Developer Program requires a D-U-N-S number.
  - Check first whether RecipeFinder Limited already has one: https://www.dnb.co.uk/duns-number/lookup.html
  - If not, request one for free via Apple's own D-U-N-S tool (avoid D&B's direct signup, which can upsell paid tiers): https://developer.apple.com/enroll/duns-lookup/
  - Company name, address, and registration number used in the application must match Companies House exactly.
  - Lookup is usually instant if a D-U-N-S already exists; a fresh application can take up to ~5 business days (sometimes longer for UK applicants if details don't match Companies House).

## Coding standards
- **Architecture:** Follow Clean Architecture principles — clear separation between layers (e.g. Presentation / Domain / Data), with dependencies pointing inward. Avoid tangling UI, business logic, and networking/persistence together.
- **Code quality:** Favor clear, readable, idiomatic Swift/SwiftUI over clever or terse code. Keep types and functions focused on a single responsibility.
- **Helper functions:** Only introduce helper functions/utilities when there's real duplication or a genuine complexity win — avoid speculative abstractions or helpers used in just one place.
- **Testing:** All new code should be accompanied by tests. Aim for high coverage, including both:
  - Unit tests (business logic, view models, use cases, data mappers)
  - Integration tests (interactions across layers, e.g. repository + network/persistence)
- When implementing a feature, write/update tests alongside the implementation rather than as an afterthought.

## Git / auth setup
- SSH key (ed25519) has been generated and added to GitHub as both an Authentication Key and a Signing Key.
- Commit signing is configured via:
  ```
  git config --global gpg.format ssh
  git config --global user.signingkey ~/.ssh/id_ed25519.pub
  git config --global commit.gpgsign true
  ```
