// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

extension View {
    /// Marks this view as the place a tooltip points to.
    func tooltipPopoverAnchor(id: String, text: LocalizedStringResource) -> some View {
        anchorPreference(key: TooltipPopoverAnchorKey.self, value: .bounds) { bounds in
            [id: TooltipPopoverAnchor(text: text, bounds: bounds)]
        }
    }
}

/// Shows the tooltip of the anchor named by `activeID`, and closes it on a tap outside.
///
/// Wrap the whole screen, so the tooltip can draw over everything inside it. It
/// pops out of its arrow. With Reduce Motion on, it only fades.
struct TooltipPopoverHost<Content: View>: View {
    @Binding var activeID: String?
    var tint: Color = .indigo
    @ViewBuilder var content: () -> Content

    @ScaledMetric(relativeTo: .subheadline) private var maximumWidth = 260.0
    @AccessibilityFocusState private var isBubbleFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        content()
            .overlayPreferenceValue(TooltipPopoverAnchorKey.self) { anchors in
                GeometryReader { proxy in
                    if let activeID, let tip = anchors[activeID] {
                        tooltip(text: tip.text, anchor: proxy[tip.bounds], container: proxy.size)
                    }
                }
                .animation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.32, bounce: 0.35), value: activeID)
            }
    }

    private func tooltip(text: LocalizedStringResource, anchor: CGRect, container: CGSize) -> some View {
        let opensAbove = TooltipPopoverGeometry.opensAbove(anchor: anchor, container: container)
        let scaleAnchor = TooltipPopoverGeometry.arrowTip(anchor: anchor, container: container, opensAbove: opensAbove)

        return ZStack {
            Color.clear
                .contentShape(.rect)
                .onTapGesture { activeID = nil }
                .accessibilityHidden(true)

            TooltipPopoverPlacement(anchor: anchor, opensAbove: opensAbove, maximumWidth: maximumWidth) {
                ViewThatFits(in: .vertical) {
                    bubbleText(text)
                    ScrollView { bubbleText(text) }
                }
                .background(tint, in: .rect(cornerRadius: 12, style: .continuous))
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isModal)
                .accessibilityAction(named: "Dismiss") { activeID = nil }
                .accessibilityAction(.escape) { activeID = nil }
                .accessibilityFocused($isBubbleFocused)
                .onAppear { isBubbleFocused = true }

                TooltipPopoverArrow(pointsDown: opensAbove)
                    .fill(tint)
                    .accessibilityHidden(true)
            }
        }
        .id(activeID)
        .transition(
            reduceMotion ? .opacity : .scale(scale: 0.2, anchor: scaleAnchor).combined(with: .opacity)
        )
    }

    private func bubbleText(_ text: LocalizedStringResource) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(TooltipPopoverContrastingForeground(background: tint))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
    }
}

struct TooltipPopoverAnchor {
    var text: LocalizedStringResource
    var bounds: Anchor<CGRect>
}

struct TooltipPopoverAnchorKey: PreferenceKey {
    static var defaultValue: [String: TooltipPopoverAnchor] { [:] }

    static func reduce(value: inout [String: TooltipPopoverAnchor], nextValue: () -> [String: TooltipPopoverAnchor]) {
        value.merge(nextValue()) { _, new in new }
    }
}

nonisolated enum TooltipPopoverGeometry {
    static let arrowSize = CGSize(width: 18, height: 9)
    static let margin: CGFloat = 12
    private static let cornerInset: CGFloat = 14

    /// The tooltip opens on the side of the anchor with more room.
    static func opensAbove(anchor: CGRect, container: CGSize) -> Bool {
        anchor.minY > container.height - anchor.maxY
    }

    /// Where the arrow touches the anchor, as a fraction of the container.
    static func arrowTip(anchor: CGRect, container: CGSize, opensAbove: Bool) -> UnitPoint {
        guard container.width > 0, container.height > 0 else { return .center }
        return UnitPoint(
            x: anchor.midX / container.width,
            y: (opensAbove ? anchor.minY : anchor.maxY) / container.height
        )
    }

    /// The most room the bubble can take on its side of the anchor.
    static func available(anchor: CGRect, container: CGSize, opensAbove: Bool, maximumWidth: CGFloat) -> CGSize {
        let room = opensAbove ? anchor.minY : container.height - anchor.maxY
        return CGSize(
            width: max(min(maximumWidth, container.width - margin * 2), 0),
            height: max(room - arrowSize.height - margin, 0)
        )
    }

    static func frames(
        anchor: CGRect,
        bubble: CGSize,
        container: CGSize,
        opensAbove: Bool
    ) -> (bubble: CGRect, arrow: CGRect) {
        let x = clamp(anchor.midX - bubble.width / 2, from: margin, to: container.width - margin - bubble.width)
        let y = opensAbove ? anchor.minY - arrowSize.height - bubble.height : anchor.maxY + arrowSize.height
        let bubbleFrame = CGRect(x: x, y: y, width: bubble.width, height: bubble.height)

        let arrowX = clamp(
            anchor.midX - arrowSize.width / 2,
            from: bubbleFrame.minX + cornerInset,
            to: bubbleFrame.maxX - cornerInset - arrowSize.width
        )
        let arrowY = opensAbove ? bubbleFrame.maxY : bubbleFrame.minY - arrowSize.height
        return (bubbleFrame, CGRect(origin: CGPoint(x: arrowX, y: arrowY), size: arrowSize))
    }

    private static func clamp(_ value: CGFloat, from lower: CGFloat, to upper: CGFloat) -> CGFloat {
        guard lower <= upper else { return lower }
        return min(max(value, lower), upper)
    }
}

/// Places its two subviews, the bubble and then the arrow, next to the anchor.
private struct TooltipPopoverPlacement: Layout {
    var anchor: CGRect
    var opensAbove: Bool
    var maximumWidth: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }

        let bubbleProposal = ProposedViewSize(TooltipPopoverGeometry.available(
            anchor: anchor,
            container: bounds.size,
            opensAbove: opensAbove,
            maximumWidth: maximumWidth
        ))
        let frames = TooltipPopoverGeometry.frames(
            anchor: anchor,
            bubble: subviews[0].sizeThatFits(bubbleProposal),
            container: bounds.size,
            opensAbove: opensAbove
        )

        subviews[0].place(
            at: CGPoint(x: bounds.minX + frames.bubble.minX, y: bounds.minY + frames.bubble.minY),
            proposal: bubbleProposal
        )
        subviews[1].place(
            at: CGPoint(x: bounds.minX + frames.arrow.minX, y: bounds.minY + frames.arrow.minY),
            proposal: ProposedViewSize(frames.arrow.size)
        )
    }
}

nonisolated private struct TooltipPopoverArrow: Shape {
    var pointsDown: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tipY = pointsDown ? rect.maxY : rect.minY
        let baseY = pointsDown ? rect.minY : rect.maxY
        path.move(to: CGPoint(x: rect.minX, y: baseY))
        path.addLine(to: CGPoint(x: rect.midX, y: tipY))
        path.addLine(to: CGPoint(x: rect.maxX, y: baseY))
        path.closeSubpath()
        return path
    }
}

/// White or black, whichever reads better on `background`. Black only on a
/// light color, so the system's own colors keep white.
nonisolated struct TooltipPopoverContrastingForeground: ShapeStyle {
    let background: Color

    func resolve(in environment: EnvironmentValues) -> Color {
        let color = background.resolve(in: environment)
        let luminance = 0.2126 * color.linearRed + 0.7152 * color.linearGreen + 0.0722 * color.linearBlue
        return luminance > 0.5 ? .black : .white
    }
}

// MARK: - Demo

struct TooltipPopoverDemo: View {
    @State private var activeTip: String?

    var body: some View {
        TooltipPopoverHost(activeID: $activeTip) {
            ZStack {
                LinearGradient(colors: [.indigo.opacity(0.2), .pink.opacity(0.15)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 18) {
                    Text("Settings")
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)

                    row("iCloud Backup", id: "backup", tip: "Backups run overnight while the phone is charging on Wi-Fi.")
                    row("Offline Maps", id: "maps", tip: "Keeps recent places on the device, so directions work without a signal.")
                    row("Low Data Mode", id: "data", tip: "Pauses automatic downloads when your connection is limited.")
                }
                .padding(24)
            }
        }
    }

    private func row(_ title: String, id: String, tip: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            Button {
                activeTip = id
            } label: {
                // The icon is too small to hit. The padding widens what answers to a touch,
                // and the same padding taken back keeps the row as it was.
                Image(systemName: "info.circle.fill")
                    .font(.title2)
                    .padding(9)
                    .contentShape(.rect)
                    .padding(-9)
            }
            .accessibilityLabel("About \(title)")
            .tooltipPopoverAnchor(id: id, text: "\(tip)")
        }
        .padding(18)
        .background(.background, in: .rect(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    TooltipPopoverDemo()
}
