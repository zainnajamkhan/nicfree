import Foundation
import StoreKit
import StoreKitTest
import Testing

@testable import NicFree

/// The unlock against the local StoreKit configuration: it loads, it buys, and it goes
/// away again when the transaction does, so a refund locks the app as it should.
@MainActor
@Suite("Purchase", .serialized)
struct PurchaseStoreTests {

    private static let configuration = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("NicFree.storekit")

    @Test("Buying unlocks, clearing the transaction locks again")
    func unlockFollowsTheEntitlement() async throws {
        let session = try SKTestSession(contentsOf: Self.configuration)
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()

        // The test session finishes setting up asynchronously, so the first product request
        // can come back empty. Ask again briefly rather than trusting the first answer.
        let store = PurchaseStore()
        store.debugUnlocked = false   // a switch left on in Settings would hide the result
        for _ in 0..<20 where store.product == nil {
            await store.start()
            if store.product == nil { try await Task.sleep(for: .milliseconds(250)) }
        }
        #expect(store.product?.id == PurchaseStore.unlockID)
        #expect(store.product?.type == .nonConsumable)
        #expect(store.isUnlocked == false)

        await store.purchase()
        #expect(store.isUnlocked)

        session.clearTransactions()
        await store.start()
        #expect(store.isUnlocked == false)
    }
}
