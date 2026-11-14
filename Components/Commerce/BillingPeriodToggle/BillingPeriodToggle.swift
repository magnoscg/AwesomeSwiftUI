// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

enum BillingPeriodToggleOption: String, CaseIterable, Hashable {
    case monthly = "Monthly"
    case yearly = "Yearly"
}

enum BillingPeriodTogglePricing {
    /// The whole percent saved by paying yearly, or nil when there is no saving to show.
    static func savingsPercent(monthly: Double, yearly: Double) -> Int? {
        let fullYear = monthly * 12
        guard fullYear.isFinite, yearly.isFinite, fullYear > 0, yearly >= 0, yearly < fullYear else { return nil }

        let percent = Int(((1 - yearly / fullYear) * 100).rounded())
        return percent > 0 ? percent : nil
    }
}

/// A monthly and yearly switch: the price rolls to its new value and a savings badge appears.
///
/// With Reduce Motion on, everything changes at once.
struct BillingPeriodToggle: View {
    @Binding var period: BillingPeriodToggleOption
    var monthlyPrice: Double = 12
    var yearlyPrice: Double = 99
    var currencyCode: String = "USD"
    var tint: Color = .indigo

    @Namespace private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var pricePerMonth: Double {
        period == .monthly ? monthlyPrice : yearlyPrice / 12
    }

    private var savings: Int? {
        BillingPeriodTogglePricing.savingsPercent(monthly: monthlyPrice, yearly: yearlyPrice)
    }

    private var rowLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 6))
            : AnyLayout(HStackLayout(spacing: 6))
    }

    var body: some View {
        VStack(spacing: 18) {
            segments
            price
            footnote
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.45, bounce: 0.2), value: period)
        .sensoryFeedback(.selection, trigger: period)
    }

    private var segments: some View {
        rowLayout {
            ForEach(BillingPeriodToggleOption.allCases, id: \.self) { option in
                let isSelected = option == period

                Button {
                    period = option
                } label: {
                    Text(option.rawValue)
                        .font(.headline)
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(tint.gradient)
                                    .matchedGeometryEffect(id: "selection", in: namespace)
                            }
                        }
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(4)
        .background(.quaternary, in: .capsule)
    }

    private var price: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(pricePerMonth, format: .currency(code: currencyCode))
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .monospacedDigit()
                .contentTransition(.numericText(value: pricePerMonth))

            Text("per month")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var footnote: some View {
        rowLayout {
            Text(period == .monthly ? "Billed every month" : "Billed once a year")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if period == .yearly, let savings {
                Text("Save \(savings)%")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.green.gradient, in: .capsule)
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
            }
        }
        .multilineTextAlignment(.center)
    }
}

// MARK: - Demo

struct BillingPeriodToggleDemo: View {
    @State private var period = BillingPeriodToggleOption.monthly

    private let features = ["Unlimited projects", "Sync across devices", "Priority support"]

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.largeTitle)
                        .foregroundStyle(.indigo)
                        .accessibilityHidden(true)

                    Text("Go Pro")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))

                    Text("Everything you need, billed your way.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                BillingPeriodToggle(period: $period)
                    .padding(20)
                    .background(.regularMaterial, in: .rect(cornerRadius: 28))

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(features, id: \.self) { feature in
                        Label(feature, systemImage: "checkmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.indigo)
                    }
                }
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
            }
            .padding(24)
        }
        .defaultScrollAnchor(.center, for: .alignment)
        .background(
            LinearGradient(colors: [.indigo.opacity(0.18), .pink.opacity(0.12)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }
}

#Preview {
    BillingPeriodToggleDemo()
}
