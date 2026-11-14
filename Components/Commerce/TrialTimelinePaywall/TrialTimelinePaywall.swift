// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

nonisolated enum TrialTimelinePaywallLogic {
    /// The days of a trial worth showing, counted from today: today, the day of the reminder and
    /// the day the trial ends. A trial too short for a reminder has none, and no trial is just today.
    static func days(trialDays: Int, reminderLead: Int = 2) -> [Int] {
        guard trialDays > 0 else { return [0] }
        let reminder = trialDays - reminderLead
        return reminderLead > 0 && reminder > 0 ? [0, reminder, trialDays] : [0, trialDays]
    }

    static func date(afterDays days: Int, from start: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: days, to: start) ?? start
    }
}

struct TrialTimelinePaywallPlan: Identifiable, Equatable {
    var id: String
    var title: LocalizedStringResource
    /// The price as it should be read, such as StoreKit's `displayPrice` and its period.
    var price: String
    var badge: LocalizedStringResource?
    /// How long its free trial lasts. Zero when it has none.
    var trialDays = 0
}

/// A paywall that shows what happens on each day of the free trial before asking to start it.
///
/// It draws the plans and the timeline and reports the taps: buying and restoring are up to you,
/// with StoreKit or whatever you use. The reminder step is a promise, so schedule that
/// notification, or set `reminderLead` to 0 to leave the step out.
struct TrialTimelinePaywall: View {
    var title: LocalizedStringResource = "How your free trial works"
    let plans: [TrialTimelinePaywallPlan]
    @Binding var selection: TrialTimelinePaywallPlan.ID
    /// How many days before the trial ends the reminder is sent.
    var reminderLead = 2
    var startDate = Date.now
    var isPurchasing = false
    var onContinue: (TrialTimelinePaywallPlan) -> Void
    var onRestore: () -> Void

    private let margin: CGFloat = 24
    private let cornerRadius: CGFloat = 16
    private let lineWidth: CGFloat = 6

    @State private var hasAppeared = false
    @ScaledMetric(relativeTo: .headline) private var markSize = 34.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var plan: TrialTimelinePaywallPlan? {
        plans.first { $0.id == selection } ?? plans.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text(title)
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)

                if let plan {
                    timeline(for: plan)
                }

                VStack(spacing: 10) {
                    ForEach(plans) { plan in
                        card(for: plan)
                    }
                }
            }
            .padding(.horizontal, margin)
            .padding(.top, 32)
            .padding(.bottom, margin)
            .frame(maxWidth: 520, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            if let plan {
                footer(for: plan)
            }
        }
        .animation(reduceMotion ? nil : .snappy, value: selection)
        .onAppear { hasAppeared = true }
    }

    // MARK: Timeline

    private func timeline(for plan: TrialTimelinePaywallPlan) -> some View {
        let days = TrialTimelinePaywallLogic.days(trialDays: plan.trialDays, reminderLead: reminderLead)

        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.element) { index, day in
                step(day: day, plan: plan, isLast: index == days.count - 1)
                    .opacity(hasAppeared ? 1 : 0)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.4).delay(Double(index) * 0.15), value: hasAppeared)
                    .transition(.opacity)
            }
        }
    }

    private func step(day: Int, plan: TrialTimelinePaywallPlan, isLast: Bool) -> some View {
        let isCharge = day == plan.trialDays

        return HStack(alignment: .top, spacing: 16) {
            Image(systemName: day == 0 && !isCharge ? "lock.open.fill" : isCharge ? "star.fill" : "bell.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: markSize, height: markSize)
                .background(.tint, in: .circle)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(day == 0 ? "Today" : "Day \(day)")
                        .font(.headline)
                    if day > 0 {
                        Text(TrialTimelinePaywallLogic.date(afterDays: day, from: startDate), format: .dateTime.month(.abbreviated).day())
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(text(day: day, plan: plan))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 6)
            .padding(.bottom, isLast ? 0 : 22)
        }
        .background(alignment: .topLeading) {
            // The line that joins this step to the next one. After the last step it fades away.
            Capsule()
                .fill(isLast ? AnyShapeStyle(LinearGradient(colors: [.accentColor.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom)) : AnyShapeStyle(.tint.opacity(0.3)))
                .frame(width: lineWidth)
                .frame(maxHeight: isLast ? markSize * 2 : .infinity, alignment: .top)
                .padding(.leading, (markSize - lineWidth) / 2)
                .padding(.top, markSize / 2)
                .accessibilityHidden(true)
        }
        .padding(.bottom, isLast ? markSize : 0)
        .accessibilityElement(children: .combine)
    }

    private func text(day: Int, plan: TrialTimelinePaywallPlan) -> String {
        if day == plan.trialDays {
            return plan.trialDays > 0
                ? "Your subscription starts and you are charged \(plan.price). Cancel any time before."
                : "Your subscription starts and you are charged \(plan.price)."
        }
        return day == 0
            ? "You get full access to everything, free."
            : "We remind you that your trial is about to end."
    }

    // MARK: Plans

    private func card(for plan: TrialTimelinePaywallPlan) -> some View {
        let isSelected = plan.id == self.plan?.id

        return Button {
            selection = plan.id
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.tertiary))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(plan.title)
                            .font(.headline)
                        if let badge = plan.badge {
                            Text(badge)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tint)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(.tint.opacity(0.15), in: .capsule)
                        }
                    }
                    Text(plan.trialDays > 0 ? "\(plan.trialDays) days free, then \(plan.price)" : plan.price)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.fill.quaternary, in: .rect(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(.tint, lineWidth: isSelected ? 2 : 0)
            }
            .contentShape(.rect(cornerRadius: cornerRadius))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func footer(for plan: TrialTimelinePaywallPlan) -> some View {
        VStack(spacing: 10) {
            Button {
                onContinue(plan)
            } label: {
                Text(plan.trialDays > 0 ? "Start \(plan.trialDays)-Day Free Trial" : "Subscribe")
                    .font(.headline)
                    .opacity(isPurchasing ? 0 : 1)
                    .frame(maxWidth: .infinity)
                    .overlay {
                        if isPurchasing {
                            ProgressView()
                                .controlSize(.regular)
                                .tint(.white)
                        }
                    }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            // Not `disabled`, which would take the color away from under the spinner.
            .allowsHitTesting(!isPurchasing)
            .accessibilityValue(isPurchasing ? "In progress" : "")

            Button(action: onRestore) {
                // A line of text is too short to hit. The padding widens what answers to a
                // touch, and the same padding taken back keeps the layout as it was.
                Text("Restore Purchases")
                    .padding(.vertical, 14)
                    .contentShape(.rect)
                    .padding(.vertical, -14)
            }
            .font(.footnote)
            .disabled(isPurchasing)
        }
        .padding(.horizontal, margin)
        .padding(.vertical, 12)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }
}

// MARK: - Demo

struct TrialTimelinePaywallDemo: View {
    private let plans = [
        TrialTimelinePaywallPlan(id: "yearly", title: "Yearly", price: "$39.99 a year", badge: "Save 44%", trialDays: 7),
        TrialTimelinePaywallPlan(id: "monthly", title: "Monthly", price: "$5.99 a month"),
    ]

    @State private var selection = "yearly"
    @State private var isPurchasing = false

    var body: some View {
        TrialTimelinePaywall(plans: plans, selection: $selection, isPurchasing: isPurchasing) { _ in
            Task {
                isPurchasing = true
                try? await Task.sleep(for: .seconds(1.5))
                isPurchasing = false
            }
        } onRestore: {
        }
        .tint(.indigo)
    }
}

#Preview {
    TrialTimelinePaywallDemo()
}
