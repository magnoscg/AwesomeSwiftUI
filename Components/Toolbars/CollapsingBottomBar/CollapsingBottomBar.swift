// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

struct CollapsingBottomBarItem: Identifiable {
    let id: String
    let title: LocalizedStringResource
    let systemImage: String
    let action: () -> Void
}

/// Decides when the bar collapses. A change of direction must travel past a threshold,
/// so small movements of the finger do not make the bar flicker.
struct CollapsingBottomBarState: Equatable {
    private(set) var isCollapsed = false
    private var anchor: CGFloat = 0

    mutating func update(offset: CGFloat, threshold: CGFloat) {
        guard offset > 0 else {
            isCollapsed = false
            anchor = 0
            return
        }

        let travel = offset - anchor
        let limit = max(threshold, 0)
        if isCollapsed ? travel < -limit : travel > limit {
            isCollapsed.toggle()
            anchor = offset
        } else if isCollapsed ? travel > 0 : travel < 0 {
            anchor = offset
        }
    }

    /// Removes the rubber band at both ends, which would otherwise look like a change of direction.
    static func clampedOffset(offsetY: CGFloat, topInset: CGFloat, bottomInset: CGFloat, contentHeight: CGFloat, containerHeight: CGFloat) -> CGFloat {
        let maxOffset = max(contentHeight + topInset + bottomInset - containerHeight, 0)
        return min(max(offsetY + topInset, 0), maxOffset)
    }
}

/// A bottom bar that shrinks to a pill while scrolling down and expands when scrolling up.
///
/// Apply it to a `ScrollView` with `.collapsingBottomBar(items:)`. With Reduce Motion on,
/// the bar changes size at once.
struct CollapsingBottomBar: ViewModifier {
    let items: [CollapsingBottomBarItem]

    @State private var state = CollapsingBottomBarState()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                CollapsingBottomBarState.clampedOffset(
                    offsetY: geometry.contentOffset.y,
                    topInset: geometry.contentInsets.top,
                    bottomInset: geometry.contentInsets.bottom,
                    contentHeight: geometry.contentSize.height,
                    containerHeight: geometry.containerSize.height
                )
            } action: { _, newValue in
                state.update(offset: newValue, threshold: 24)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                CollapsingBottomBarSlot(items: items, isCollapsed: state.isCollapsed)
                    // The labels are short. The slot reads its height under this cap, which keeps every action on screen.
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            }
            .animation(reduceMotion ? nil : .snappy(duration: 0.35), value: state.isCollapsed)
    }
}

private struct CollapsingBottomBarSlot: View {
    let items: [CollapsingBottomBarItem]
    let isCollapsed: Bool

    @ScaledMetric(relativeTo: .caption2) private var slotHeight = 86.0

    var body: some View {
        // A fixed slot keeps the inset stable, so the bar's own resizing cannot move the scroll offset.
        bar.frame(height: slotHeight, alignment: .bottom)
    }

    private var bar: some View {
        HStack(spacing: isCollapsed ? 6 : 0) {
            ForEach(items) { item in
                Button(action: item.action) {
                    VStack(spacing: 3) {
                        Image(systemName: item.systemImage)
                            .font(.title3)

                        if !isCollapsed {
                            Text(item.title)
                                .font(.caption2)
                        }
                    }
                    .frame(minWidth: 44, maxWidth: isCollapsed ? nil : .infinity, minHeight: 44)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
            }
        }
        .padding(.horizontal, isCollapsed ? 10 : 14)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: .capsule)
        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        .padding(.horizontal, 20)
        .padding(.bottom, 6)
    }
}

extension View {
    func collapsingBottomBar(items: [CollapsingBottomBarItem]) -> some View {
        modifier(CollapsingBottomBar(items: items))
    }
}

// MARK: - Demo

struct CollapsingBottomBarDemo: View {
    @State private var lastAction = "Scroll to collapse the bar"

    private var items: [CollapsingBottomBarItem] {
        [
            CollapsingBottomBarItem(id: "home", title: "Home", systemImage: "house.fill") { lastAction = "Home" },
            CollapsingBottomBarItem(id: "search", title: "Search", systemImage: "magnifyingglass") { lastAction = "Search" },
            CollapsingBottomBarItem(id: "add", title: "Add", systemImage: "plus.circle.fill") { lastAction = "Add" },
            CollapsingBottomBarItem(id: "inbox", title: "Inbox", systemImage: "tray.fill") { lastAction = "Inbox" },
        ]
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                Text(lastAction)
                    .font(.title.bold())

                ForEach(0..<20, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing))
                        .hueRotation(.degrees(Double(index) * 18))
                        .frame(height: 110)
                        .accessibilityHidden(true)
                }
            }
            .padding(20)
        }
        .collapsingBottomBar(items: items)
    }
}

#Preview {
    CollapsingBottomBarDemo()
}
