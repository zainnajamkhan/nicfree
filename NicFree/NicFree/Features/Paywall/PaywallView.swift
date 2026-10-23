//
//  PaywallView.swift
//  NicFree
//

import SwiftUI
import StoreKit

/// One price, plainly. No countdown, no fake discount, no trial that turns into a
/// subscription. Restore is a visible button, not a buried link.
///
/// Never shown at launch, during onboarding, or after a slip. It opens only when someone
/// taps something that is part of the unlock.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PurchaseStore.self) private var store

    var body: some View {
        Screen {
            ScrollView {
                VStack(spacing: Space.l) {
                    Sprout(freeDays: 30)
                        .frame(height: 140)
                        .padding(.top, Space.xl)

                    VStack(spacing: Space.s) {
                        Text("Unlock NicFree")
                            .font(Typeface.title)
                            .foregroundStyle(Palette.ink)
                        Text("One purchase. No subscription, ever.")
                            .font(Typeface.voiceSmall)
                            .foregroundStyle(Palette.inkSoft)
                    }
                    .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: Space.m) {
                        feature("chart.bar.fill", "Insights", "See what sets off your cravings, when they show up and how long they last.")
                        feature("calendar", "Your full history", "Every day since you stopped, and your total drawn over time.")
                        feature("lock.fill", "Still private", "Everything stays on this iPhone. No account, no tracking.")
                    }
                    .padding(Space.m + 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.card)
                            .strokeBorder(Palette.hairline, lineWidth: 2)
                    )

                    if let message = store.message {
                        Text(message)
                            .font(Typeface.row)
                            .foregroundStyle(Palette.inkSoft)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: Space.xs) {
                    if let product = store.product {
                        PrimaryButton("Unlock for \(product.displayPrice)") {
                            Task { await store.purchase() }
                        }
                        .disabled(store.isWorking)
                    } else {
                        Text("Loading the price…")
                            .font(Typeface.row)
                            .foregroundStyle(Palette.inkSoft)
                            .frame(minHeight: 58)
                    }

                    Button("Restore purchase") {
                        Task { await store.restore() }
                    }
                    .font(Typeface.row)
                    .foregroundStyle(Palette.inkSoft)
                    .frame(minHeight: 44)
                    .disabled(store.isWorking)
                }
                .padding(.top, Space.s)
                .background(Palette.ground)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(Palette.inkSoft)
                    .frame(width: 44, height: 44)
                    .background(Palette.surface, in: Circle())
            }
            .accessibilityLabel("Close")
            .padding(Space.m)
        }
        .task { await store.start() }
        .onChange(of: store.isUnlocked) { _, unlocked in
            if unlocked { dismiss() }
        }
        .onDisappear { store.message = nil }
    }

    private func feature(_ symbol: String, _ title: LocalizedStringKey, _ detail: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: Space.m) {
            Image(systemName: symbol)
                .font(.title3.weight(.bold))
                .foregroundStyle(Palette.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                Text(detail)
                    .font(Typeface.row)
                    .foregroundStyle(Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// A card that stands in for a paid section, with one button to the paywall.
struct LockedCard: View {
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    let unlock: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Space.m) {
            HStack(spacing: Space.s) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(Palette.sun)
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .heavy))
                    .foregroundStyle(Palette.ink)
            }
            Text(detail)
                .font(Typeface.row)
                .foregroundStyle(Palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton("See what unlocks", action: unlock)
        }
        .padding(Space.m + 4)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card))
    }
}

#Preview {
    PaywallView()
        .environment(PurchaseStore())
}
