// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

struct NotchedTabBarItem: Identifiable {
    let id: String
    let title: String
    let systemImage: String
}

enum NotchedTabBarMath {
    /// The middle of a tab, with the tabs spread evenly inside the horizontal inset.
    static func centerX(index: Int, count: Int, width: CGFloat, inset: CGFloat) -> CGFloat {
        let usable = max(width - 2 * max(inset, 0), 0)
        guard count > 0, usable > 0 else { return max(width, 0) / 2 }
        let clamped = min(max(index, 0), count - 1)
        return max(inset, 0) + usable * (CGFloat(clamped) + 0.5) / CGFloat(count)
    }

    /// Half the width of the notch, narrowed so it never runs into a rounded corner.
    static func halfSpan(centerX: CGFloat, width: CGFloat, corner: CGFloat, desired: CGFloat) -> CGFloat {
        max(min(desired, centerX - corner, width - centerX - corner), 0)
    }
}

/// A rounded bar with a smooth notch that can slide along its top edge.
struct NotchedTabBarShape: Shape {
    var centerX: CGFloat
    var desiredHalfSpan: CGFloat
    var depth: CGFloat
    var corner: CGFloat

    var animatableData: CGFloat {
        get { centerX }
        set { centerX = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard rect.width > 0, rect.height > 0 else { return Path() }

        let radius = min(corner, rect.width / 2, rect.height / 2)
        let span = NotchedTabBarMath.halfSpan(centerX: centerX, width: rect.width, corner: radius, desired: desiredHalfSpan)
        let dip = min(depth, rect.height)
        let (w, h) = (rect.width, rect.height)

        var path = Path()
        path.move(to: CGPoint(x: 0, y: radius))
        path.addArc(tangent1End: .zero, tangent2End: CGPoint(x: radius, y: 0), radius: radius)
        path.addLine(to: CGPoint(x: centerX - span, y: 0))
        // Each side is two curves that share a tangent, so the notch has no visible seam.
        path.addQuadCurve(to: CGPoint(x: centerX - span * 0.5, y: dip * 0.5), control: CGPoint(x: centerX - span * 0.62, y: 0))
        path.addQuadCurve(to: CGPoint(x: centerX, y: dip), control: CGPoint(x: centerX - span * 0.38, y: dip))
        path.addQuadCurve(to: CGPoint(x: centerX + span * 0.5, y: dip * 0.5), control: CGPoint(x: centerX + span * 0.38, y: dip))
        path.addQuadCurve(to: CGPoint(x: centerX + span, y: 0), control: CGPoint(x: centerX + span * 0.62, y: 0))
        path.addLine(to: CGPoint(x: w - radius, y: 0))
        path.addArc(tangent1End: CGPoint(x: w, y: 0), tangent2End: CGPoint(x: w, y: radius), radius: radius)
        path.addLine(to: CGPoint(x: w, y: h - radius))
        path.addArc(tangent1End: CGPoint(x: w, y: h), tangent2End: CGPoint(x: w - radius, y: h), radius: radius)
        path.addLine(to: CGPoint(x: radius, y: h))
        path.addArc(tangent1End: CGPoint(x: 0, y: h), tangent2End: CGPoint(x: 0, y: h - radius), radius: radius)
        path.closeSubpath()
        return path
    }
}

/// A tab bar whose background carves a smooth notch under the selected tab.
///
/// With Reduce Motion on, the notch moves to the new tab without sliding.
struct NotchedTabBar: View {
    let items: [NotchedTabBarItem]
    @Binding var selection: String
    var tint: Color = .indigo

    var body: some View {
        NotchedTabBarStage(items: items, selection: $selection, tint: tint)
            // The bar only holds short labels. The stage reads its sizes under this cap, which keeps every tab on screen.
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

private struct NotchedTabBarStage: View {
    let items: [NotchedTabBarItem]
    @Binding var selection: String
    let tint: Color

    @ScaledMetric(relativeTo: .caption) private var barHeight = 72.0
    @ScaledMetric(relativeTo: .title3) private var bubbleSize = 52.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let inset: CGFloat = 14

    private var selectedIndex: Int {
        items.firstIndex { $0.id == selection } ?? 0
    }

    var body: some View {
        let depth = bubbleSize * 0.7
        let bubbleY = depth - bubbleSize / 2 - 6

        GeometryReader { proxy in
            let center = NotchedTabBarMath.centerX(index: selectedIndex, count: items.count, width: proxy.size.width, inset: inset)

            ZStack(alignment: .topLeading) {
                NotchedTabBarShape(centerX: center, desiredHalfSpan: bubbleSize * 0.95, depth: depth, corner: 26)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.15), radius: 14, y: 6)

                if !items.isEmpty {
                    Circle()
                        .fill(tint.gradient)
                        .frame(width: bubbleSize, height: bubbleSize)
                        .position(x: center, y: bubbleY)
                        .accessibilityHidden(true)
                }

                HStack(spacing: 0) {
                    ForEach(items) { item in
                        tabButton(item, iconLift: barHeight / 2 - 10 - bubbleY)
                    }
                }
                .padding(.horizontal, inset)
            }
        }
        .frame(height: barHeight)
        .padding(.top, bubbleSize / 2)
        .animation(reduceMotion ? nil : .snappy(duration: 0.4), value: selection)
    }

    private func tabButton(_ item: NotchedTabBarItem, iconLift: CGFloat) -> some View {
        let isSelected = item.id == selection

        return Button {
            selection = item.id
        } label: {
            VStack(spacing: 4) {
                Image(systemName: item.systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : .secondary)
                    .offset(y: isSelected ? -iconLift : 0)

                Text(item.title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? tint : .secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Demo

struct NotchedTabBarDemo: View {
    private let items = [
        NotchedTabBarItem(id: "home", title: "Home", systemImage: "house.fill"),
        NotchedTabBarItem(id: "search", title: "Search", systemImage: "magnifyingglass"),
        NotchedTabBarItem(id: "saved", title: "Saved", systemImage: "bookmark.fill"),
        NotchedTabBarItem(id: "profile", title: "Profile", systemImage: "person.fill"),
    ]

    @State private var selection = "home"

    private var heading: String {
        items.first { $0.id == selection }.map { "\($0.title) page" } ?? ""
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [.indigo.opacity(0.35), .pink.opacity(0.25)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            Text(heading)
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            NotchedTabBar(items: items, selection: $selection)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
        }
    }
}

#Preview {
    NotchedTabBarDemo()
}
