import SwiftUI
import StoreKit

private let logger = AppLogger.logger(category: "Subscription")

/// Behavioural seam so views depend on this protocol, not the `SubscriptionManager` singleton, and tests can inject a fake without touching StoreKit.
@MainActor
protocol SubscriptionProviding: AnyObject, Observable {
    var isSubscribed: Bool { get }
    var products: [Product] { get }
    var productLoadState: ProductLoadState { get }
    var purchaseInProgress: Bool { get }
    var purchaseError: String? { get set }
    func loadProducts() async
    func purchase(_ product: Product) async
    func restorePurchases() async
}

/// Product-fetch state so the paywall shows a spinner, error+retry, or plans — never an indefinite spinner when the fetch returns empty or throws.
enum ProductLoadState: Equatable {
    case loading
    case loaded
    case failed
}

private struct SubscriptionProvidingKey: EnvironmentKey {
    // SwiftUI reads environment defaults on the main actor, so assuming main-actor isolation is safe.
    static var defaultValue: any SubscriptionProviding {
        MainActor.assumeIsolated { SubscriptionManager.shared }
    }
}

extension EnvironmentValues {
    /// Injected subscription state; defaults to the shared singleton, override with `.environment(\.subscription, fake)` in tests/previews.
    var subscription: any SubscriptionProviding {
        get { self[SubscriptionProvidingKey.self] }
        set { self[SubscriptionProvidingKey.self] = newValue }
    }
}

/// Owns subscription state and orchestrates StoreKit 2 purchase/restore/entitlement for RecipeFinder+; wire `isSubscribed` into any paid gate.
@MainActor
@Observable
final class SubscriptionManager: SubscriptionProviding {

    static let shared = SubscriptionManager()

    // MARK: - Product identifiers (must match App Store Connect + .storekit config)

    static let annualProductID  = "com.recipefinder.plus.annual"
    static let monthlyProductID = "com.recipefinder.plus.monthly"

    // MARK: - Observable state

    /// `true` when the user has an active RecipeFinder+ subscription.
    private(set) var isSubscribed: Bool = false
    /// Products loaded from StoreKit, sorted annual-first.
    private(set) var products: [Product] = []
    /// Progress of the product fetch; drives the paywall's loading/error UI.
    private(set) var productLoadState: ProductLoadState = .loading
    /// `true` while a purchase or restore is in flight.
    private(set) var purchaseInProgress: Bool = false
    /// Non-nil when the most recent purchase attempt failed.
    var purchaseError: String?

    // MARK: - Private

    @ObservationIgnored private var transactionListener: Task<Void, Error>?

    private init() {
        transactionListener = startTransactionListener()
        Task {
            await loadProducts()
            await checkEntitlement()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Public API

    func loadProducts() async {
        productLoadState = .loading
        do {
            let fetched = try await Product.products(for: [
                Self.annualProductID,
                Self.monthlyProductID
            ])
            // Annual first so the paywall can lead with best value.
            products = fetched.sorted { $0.id == Self.annualProductID && $1.id != Self.annualProductID }
            productLoadState = .loaded
            logger.info("Loaded \(fetched.count) subscription product(s)")
        } catch {
            productLoadState = .failed
            logger.error("Product load failed: \(error)")
        }
    }

    func purchase(_ product: Product) async {
        purchaseInProgress = true
        purchaseError = nil
        defer { purchaseInProgress = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await checkEntitlement()
                logger.info("Purchase succeeded: \(product.id)")
            case .userCancelled:
                logger.debug("User cancelled purchase")
            case .pending:
                logger.info("Purchase pending approval")
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
            logger.error("Purchase failed: \(error)")
        }
    }

    func restorePurchases() async {
        purchaseInProgress = true
        purchaseError = nil
        defer { purchaseInProgress = false }

        do {
            try await AppStore.sync()
            await checkEntitlement()
            logger.info("Purchases restored")
        } catch {
            purchaseError = error.localizedDescription
            logger.error("Restore failed: \(error)")
        }
    }

    /// Re-evaluates entitlements and updates `isSubscribed`; call on launch and on each transaction update.
    func checkEntitlement() async {
        var entitled = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result, transaction.revocationDate == nil else { continue }
            if transaction.productID == Self.annualProductID ||
               transaction.productID == Self.monthlyProductID {
                entitled = true
            }
        }
        isSubscribed = entitled
    }

    // MARK: - Private helpers

    /// Listens for background transaction updates (renewals, refunds, revocations) so `isSubscribed` stays current without a relaunch.
    private func startTransactionListener() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await transaction.finish()
                await self?.checkEntitlement()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
