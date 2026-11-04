import SwiftUI

/// The app's navigation-bar look in one place: inline title over a transparent bar so the themed background shows.
extension View {
    func appNavigationChrome() -> some View {
        navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
    }

    func appNavigationTitle(_ title: LocalizedStringKey) -> some View {
        navigationTitle(title).appNavigationChrome()
    }

    func appNavigationTitle<S: StringProtocol>(_ title: S) -> some View {
        navigationTitle(title).appNavigationChrome()
    }
}
