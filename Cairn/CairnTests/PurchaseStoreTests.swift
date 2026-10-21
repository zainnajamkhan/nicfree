import Foundation
import StoreKit
import StoreKitTest
import Testing

@testable import Cairn

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

        let store = PurchaseStore()
        await store.start()
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
