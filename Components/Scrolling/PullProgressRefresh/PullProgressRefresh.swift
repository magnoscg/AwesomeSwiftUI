// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

enum PullProgressRefreshMath {
    /// How far the content has been pulled past its resting position.
    static func pullDistance(contentOffsetY: CGFloat, topInset: CGFloat) -> CGFloat {
        max(0, -(contentOffsetY + topInset))
    }

    /// The fraction of the ring to fill, from 0 to 1.
    static func progress(pull: CGFloat, threshold: CGFloat) -> CGFloat {
        guard threshold > 0 else { return pull > 0 ? 1 : 0 }
        return min(max(pull / threshold, 0), 1)
    }
}

/// A scroll view whose ring fills as it is pulled, and refreshes when released past a threshold.
///
/// With Reduce Motion on, the content moves into place without a spring.
struct PullProgressRefresh<Content: View>: View {
    var threshold: CGFloat = 90
    var tint: Color = .accentColor
    let action: @MainActor () async -> Void
    @ViewBuilder var content: () -> Content

    @State private var pull: CGFloat = 0
    @State private var isRefreshing = false
    @State private var refreshToken: Int?
    @ScaledMetric(relativeTo: .title3) private var ringSize = 34.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var progress: CGFloat {
        isRefreshing ? 1 : PullProgressRefreshMath.progress(pull: pull, threshold: threshold)
    }

    private var slotHeight: CGFloat { ringSize + 28 }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: isRefreshing ? slotHeight : 0)
                    .accessibilityHidden(true)

                content()
            }
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            PullProgressRefreshMath.pullDistance(
                contentOffsetY: geometry.contentOffset.y,
                topInset: geometry.contentInsets.top
            )
        } action: { _, newValue in
            pull = newValue
        }
        .onScrollPhaseChange { oldPhase, newPhase in
            if oldPhase == .interacting, newPhase != .interacting, progress >= 1 {
                beginRefreshing()
            }
        }
        .overlay(alignment: .top) { indicator }
        .animation(reduceMotion ? nil : .snappy(duration: 0.35), value: isRefreshing)
        .task(id: refreshToken) {
            guard refreshToken != nil else { return }
            await action()
            isRefreshing = false
            refreshToken = nil
        }
    }

    private var indicator: some View {
        ZStack {
            Circle().stroke(tint.opacity(0.2), lineWidth: 3)

            if isRefreshing {
                ProgressView().tint(tint)
            } else {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Image(systemName: "arrow.down")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(tint)
                    .rotationEffect(.degrees(progress >= 1 ? 180 : 0))
            }
        }
        .frame(width: ringSize, height: ringSize)
        .padding(.top, isRefreshing ? 14 : max(0, min(pull, slotHeight) - ringSize) / 2)
        // Never fully transparent, so VoiceOver can still find the refresh action.
        .opacity(isRefreshing ? 1 : max(progress, 0.01))
        .allowsHitTesting(false)
        .accessibilityElement()
        .accessibilityLabel(isRefreshing ? "Refreshing" : "Refresh")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { beginRefreshing() }
    }

    private func beginRefreshing() {
        guard !isRefreshing else { return }
        isRefreshing = true
        refreshToken = (refreshToken ?? 0) + 1
    }
}

// MARK: - Demo

struct PullProgressRefreshDemo: View {
    @State private var updates = 0

    var body: some View {
        PullProgressRefresh(tint: .indigo) {
            try? await Task.sleep(for: .seconds(1.4))
            guard !Task.isCancelled else { return }
            updates += 1
        } content: {
            LazyVStack(alignment: .leading, spacing: 12) {
                Text("Inbox")
                    .font(.largeTitle.bold())

                Text(updates == 0 ? "Pull down to refresh" : "Updated \(updates) times")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())

                ForEach(0..<16, id: \.self) { index in
                    row(index)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
    }

    private func row(_ index: Int) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(.indigo.gradient)
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Message \(index + 1 + updates)")
                    .font(.headline)

                Text("A short preview of the message")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 16))
    }
}

#Preview {
    PullProgressRefreshDemo()
}
