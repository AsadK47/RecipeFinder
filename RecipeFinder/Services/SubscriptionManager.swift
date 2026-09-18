import Foundation
import StoreKit

private let logger = AppLogger.logger(category: "Subscription")

/// Owns subscription state and orchestrates StoreKit 2 purchase / restore /
/// entitlement flows for RecipeFinder+. Wire `isSubscribed` into any gate that
/// requires a paid entitlement.
@MainActor
final class SubscriptionManager: ObservableObject {

    static let shared = SubscriptionManager()

    // MARK: - Product identifiers (must match App Store Connect + .storekit config)

    static let annualProductID  = "com.recipefinder.plus.annual"
    static let monthlyProductID = "com.recipefinder.plus.monthly"

    // MARK: - Published state

    /// `true` when the user has an active RecipeFinder+ subscription.
    @Published private(set) var isSubscribed: Bool = false
    /// Products loaded from StoreKit, sorted annual-first.
    @Published private(set) var products: [Product] = []
    /// `true` while a purchase or restore is in flight.
    @Published private(set) var purchaseInProgress: Bool = false
    /// Non-nil when the most recent purchase attempt failed.
    @Published var purchaseError: String?

    // MARK: - Private

    private var transactionListener: Task<Void, Error>?

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
        do {
            let fetched = try await Product.products(for: [
                Self.annualProductID,
                Self.monthlyProductID
            ])
            // Annual first so the paywall can lead with best value.
            products = fetched.sorted { $0.id == Self.annualProductID && $1.id != Self.annualProductID }
            logger.info("Loaded \(fetched.count) subscription product(s)")
        } catch {
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

    /// Re-evaluates current entitlements and updates `isSubscribed`. Call on
    /// launch and whenever a transaction update arrives.
    func checkEntitlement() async {
        var entitled = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == Self.annualProductID ||
               transaction.productID == Self.monthlyProductID {
                entitled = true
            }
        }
        isSubscribed = entitled
    }

    // MARK: - Private helpers

    /// Listens for background transaction updates (renewals, refunds, revocations)
    /// so `isSubscribed` stays current without requiring a relaunch.
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
