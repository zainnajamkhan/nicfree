//
//  PurchaseStore.swift
//  NicFree
//

import Foundation
import Observation
import StoreKit
import os

/// The single unlock: one non-consumable purchase, no subscription.
///
/// The entitlement is read from `Transaction.currentEntitlements` at launch and kept up to
/// date from `Transaction.updates`, so a purchase made on another device, a restore, or a
/// refund all land here without the user doing anything.
@Observable
final class PurchaseStore {
    static let unlockID = "nicfree.unlock"

    private(set) var product: Product?
    /// What the App Store says this Apple Account owns.
    private(set) var entitled = false

    #if DEBUG
    /// Debug builds only: a switch in Settings to see the paid screens without buying.
    var debugUnlocked = UserDefaults.standard.bool(forKey: "debugUnlocked") {
        didSet { UserDefaults.standard.set(debugUnlocked, forKey: "debugUnlocked") }
    }
    var isUnlocked: Bool { entitled || debugUnlocked }
    #else
    var isUnlocked: Bool { entitled }
    #endif
    private(set) var isWorking = false
    var message: String?

    @ObservationIgnored private var updates: Task<Void, Never>?
    @ObservationIgnored private let logger = Logger(subsystem: "NicFree", category: "store")

    init() {
        #if DEBUG
        // App Store screenshots show the unlocked screens.
        if ProcessInfo.processInfo.arguments.contains("-unlockForScreenshots") {
            entitled = true
            return
        }
        #endif
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.apply(result)
            }
        }
    }

    /// Called once at launch. Safe to call again.
    func start() async {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-unlockForScreenshots") { return }
        #endif
        await refreshEntitlement()
        guard product == nil else { return }
        do {
            product = try await Product.products(for: [Self.unlockID]).first
        } catch {
            logger.error("Could not load the product: \(error.localizedDescription, privacy: .public)")
        }
    }

    func purchase() async {
        guard let product, !isWorking else { return }
        isWorking = true
        defer { isWorking = false }

        do {
            switch try await product.purchase() {
            case .success(let result):
                await apply(result)
            case .pending:
                message = String(localized: "Waiting for approval. It’ll unlock as soon as it goes through.")
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            logger.error("Purchase threw: \(error.localizedDescription, privacy: .public)")
            message = String(localized: "That didn’t go through. Please try again.")
        }
    }

    /// Restore is a visible button, not a buried link. `AppStore.sync` asks the user to
    /// sign in if needed, which is why it only runs when they tap it.
    func restore() async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }

        do {
            try await AppStore.sync()
        } catch {
            logger.error("Restore threw: \(error.localizedDescription, privacy: .public)")
        }
        await refreshEntitlement()
        message = isUnlocked
            ? String(localized: "Restored! Everything’s unlocked.")
            : String(localized: "We couldn’t find an earlier purchase on this Apple Account.")
    }

    // MARK: - Entitlement

    private func refreshEntitlement() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.unlockID,
               transaction.revocationDate == nil {
                unlocked = true
            }
        }
        entitled = unlocked
    }

    private func apply(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else {
            logger.error("Ignored an unverified transaction")
            return
        }
        if transaction.productID == Self.unlockID {
            entitled = transaction.revocationDate == nil
        }
        await transaction.finish()
    }
}
