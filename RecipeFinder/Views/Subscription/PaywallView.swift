import SwiftUI
import StoreKit

/// RecipeFinder+ paywall: subscription products (annual first) with purchase/restore via the injected `\.subscription` seam; dismisses once subscribed.
struct PaywallView: View {
    @Environment(\.subscription) private var subscription
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal

    @State private var legalDoc: LegalDoc?

    private enum LegalDoc: String, Identifiable {
        case terms, privacy
        var id: String { rawValue }
    }

    private let benefits: [(icon: String, text: String)] = [
        ("book.fill", "Unlock the full curated recipe library"),
        ("icloud.fill", "Sync your recipes across all your devices"),
        ("sparkles", "Early access to new features and recipe drops"),
        ("heart.fill", "Support independent, privacy-first development")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.spacing24) {
                        header
                        benefitsList
                        productsSection
                        restoreAndLegal
                    }
                    .padding(AppTheme.spacing20)
                }
            }
            .navigationTitle("RecipeFinder+")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(item: $legalDoc) { doc in
                switch doc {
                case .terms: TermsOfServiceView()
                case .privacy: PrivacyPolicyView()
                }
            }
            .task {
                if subscription.products.isEmpty { await subscription.loadProducts() }
            }
            .onChange(of: subscription.isSubscribed) { _, subscribed in
                if subscribed { dismiss() }
            }
        }
    }

    private var header: some View {
        VStack(spacing: AppTheme.spacing8) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: AppTheme.fontSize60))
                .foregroundStyle(AppTheme.accentColor(for: selectedTheme))
                .accessibilityHidden(true)
            Text("Cook more, unlock more")
                .font(.title2).fontWeight(.bold)
                .adaptiveForegroundColor()
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppTheme.spacing8)
    }

    private var benefitsList: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing16) {
            ForEach(benefits, id: \.icon) { benefit in
                HStack(spacing: AppTheme.spacing12) {
                    Image(systemName: benefit.icon)
                        .font(.title3)
                        .foregroundStyle(AppTheme.accentColor(for: selectedTheme))
                        .frame(width: AppTheme.spacing32)
                        .accessibilityHidden(true)
                    Text(benefit.text)
                        .font(.subheadline)
                        .adaptiveForegroundColor()
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.spacing20)
        .appCard()
    }

    @ViewBuilder
    private var productsSection: some View {
        switch subscription.productLoadState {
        case .loading:
            ProgressView("Loading plans…")
                .frame(maxWidth: .infinity)
                .padding(AppTheme.spacing24)
        case .failed:
            unavailablePlans("We couldn't load plans. Check your connection and try again.")
        case .loaded where subscription.products.isEmpty:
            unavailablePlans("Plans aren't available right now. Please try again later.")
        case .loaded:
            VStack(spacing: AppTheme.spacing12) {
                ForEach(subscription.products, id: \.id) { product in
                    productButton(product)
                }
                if let error = subscription.purchaseError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(AppTheme.error)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    /// Fetch finished with nothing to buy or a load failure — message plus retry, never a hung spinner.
    private func unavailablePlans(_ message: String) -> some View {
        VStack(spacing: AppTheme.spacing12) {
            Text(message)
                .font(.subheadline)
                .adaptiveSecondaryForeground()
                .multilineTextAlignment(.center)
            Button("Try Again") {
                Task { await subscription.loadProducts() }
            }
            .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.spacing24)
    }

    private func productButton(_ product: Product) -> some View {
        Button {
            Task { await subscription.purchase(product) }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                    Text(product.displayName)
                        .font(.headline)
                    if !product.description.isEmpty {
                        Text(product.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .padding(AppTheme.spacing16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                    .fill(AppTheme.accentColor(for: selectedTheme))
            )
        }
        .buttonStyle(.plain)
        .disabled(subscription.purchaseInProgress)
        .overlay {
            if subscription.purchaseInProgress {
                ProgressView().tint(.white)
            }
        }
        .accessibilityLabel("Subscribe: \(product.displayName), \(product.displayPrice)")
    }

    private var restoreAndLegal: some View {
        VStack(spacing: AppTheme.spacing12) {
            Button("Restore Purchases") {
                Task { await subscription.restorePurchases() }
            }
            .font(.subheadline)
            .disabled(subscription.purchaseInProgress)

            Text("Subscriptions renew automatically unless cancelled at least 24 hours before the end of the period. Manage in Settings.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: AppTheme.spacing16) {
                Button("Terms") { legalDoc = .terms }
                Button("Privacy") { legalDoc = .privacy }
            }
            .font(.caption)
        }
        .padding(.top, AppTheme.spacing8)
    }
}
