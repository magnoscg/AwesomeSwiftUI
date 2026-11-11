// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

extension View {
    /// Shows this view as a shimmering placeholder while `active` is true.
    ///
    /// Apply it to the content inside a card, not to the card: the shimmer masks the
    /// view, so a shadow drawn outside its bounds would be cut off.
    func skeletonShimmer(active: Bool) -> some View {
        modifier(SkeletonShimmerModifier(active: active))
    }
}

/// Redacts its content and sweeps a band of light across the placeholders.
///
/// With Reduce Motion on, the placeholders stay still and slightly dimmed.
struct SkeletonShimmerModifier: ViewModifier {
    var active: Bool
    var duration: TimeInterval = 1.4

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .redacted(reason: active ? .placeholder : [])
            .mask {
                TimelineView(.animation(paused: !active || reduceMotion)) { context in
                    mask(at: context.date)
                }
            }
            .allowsHitTesting(!active)
            .accessibilityElement(children: active ? .ignore : .contain)
            .accessibilityLabel("Loading", isEnabled: active)
    }

    private func mask(at date: Date) -> LinearGradient {
        guard active else {
            return LinearGradient(colors: [.black, .black], startPoint: .leading, endPoint: .trailing)
        }
        guard !reduceMotion else {
            let dimmed = Color.black.opacity(0.6)
            return LinearGradient(colors: [dimmed, dimmed], startPoint: .leading, endPoint: .trailing)
        }

        let progress = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: duration) / duration
        let center = -0.5 + 2 * progress
        return LinearGradient(
            colors: [.black.opacity(0.35), .black, .black.opacity(0.35)],
            startPoint: UnitPoint(x: center - 0.5, y: 0.2),
            endPoint: UnitPoint(x: center + 0.5, y: 0.8)
        )
    }
}

// MARK: - Demo

private struct SkeletonShimmerModifierDemoRow: Identifiable {
    let id = UUID()
    let name: String
    let message: String
    let time: String
    let color: Color
}

struct SkeletonShimmerModifierDemo: View {
    @State private var isLoading = true
    @ScaledMetric(relativeTo: .headline) private var avatarSize = 46
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let rows = [
        SkeletonShimmerModifierDemoRow(name: "Lucia Martin", message: "The photos from Sunday are up", time: "9:41", color: .pink),
        SkeletonShimmerModifierDemoRow(name: "Marco Rossi", message: "Can we move the call to four?", time: "9:12", color: .orange),
        SkeletonShimmerModifierDemoRow(name: "Aiko Tanaka", message: "Sent you the final invoice", time: "8:55", color: .teal),
        SkeletonShimmerModifierDemoRow(name: "Sam Porter", message: "Boarding now, see you tonight", time: "8:20", color: .indigo),
        SkeletonShimmerModifierDemoRow(name: "Nadia Haddad", message: "Loved the new onboarding", time: "Mon", color: .purple),
        SkeletonShimmerModifierDemoRow(name: "Tom Becker", message: "Tickets are booked for Friday", time: "Mon", color: .blue),
        SkeletonShimmerModifierDemoRow(name: "Elena Costa", message: "Recipe attached, enjoy it", time: "Sun", color: .green),
        SkeletonShimmerModifierDemoRow(name: "Ravi Patel", message: "The build is green again", time: "Sun", color: .mint),
    ]

    var body: some View {
        List {
            Section {
                ForEach(rows) { row in
                    rowContent(row)
                        .skeletonShimmer(active: isLoading)
                }
            } header: {
                Text("Messages")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.primary)
                    .textCase(nil)
                    .padding(.bottom, 8)
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.2))
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.35)) {
                    isLoading.toggle()
                }
            }
        }
    }

    private func rowContent(_ row: SkeletonShimmerModifierDemoRow) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isLoading ? Color(.systemGray4) : row.color)
                .frame(width: avatarSize, height: avatarSize)
                .overlay {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.white)
                        .opacity(isLoading ? 0 : 1)
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(row.name)
                    .font(.headline)

                Text(row.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(row.time)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SkeletonShimmerModifierDemo()
}
