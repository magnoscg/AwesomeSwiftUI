// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

struct HamburgerMenuButtonBar: Equatable {
    let start: CGPoint
    let end: CGPoint
}

/// Three bars that become a cross as `progress` goes from 0 to 1.
nonisolated struct HamburgerMenuButtonShape: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    /// The outer bars slide to the middle while turning. The middle bar shrinks away.
    func bars(in rect: CGRect) -> [HamburgerMenuButtonBar] {
        let amount = min(max(progress, 0), 1)
        let halfWidth = rect.width / 2
        let gap = rect.height * 0.32

        func outerBar(side: Double) -> HamburgerMenuButtonBar {
            let y = rect.midY + side * gap * (1 - amount)
            let angle = -side * .pi / 4 * amount
            let dx = cos(angle) * halfWidth
            let dy = sin(angle) * halfWidth
            return HamburgerMenuButtonBar(
                start: CGPoint(x: rect.midX - dx, y: y - dy),
                end: CGPoint(x: rect.midX + dx, y: y + dy)
            )
        }

        var result = [outerBar(side: -1), outerBar(side: 1)]
        if amount < 1 {
            let dx = halfWidth * (1 - amount)
            result.append(HamburgerMenuButtonBar(
                start: CGPoint(x: rect.midX - dx, y: rect.midY),
                end: CGPoint(x: rect.midX + dx, y: rect.midY)
            ))
        }
        return result
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for bar in bars(in: rect) {
            path.move(to: bar.start)
            path.addLine(to: bar.end)
        }
        return path
    }
}

/// A three-line menu button whose bars animate into a close cross.
///
/// With Reduce Motion on, the icon changes without morphing.
struct HamburgerMenuButton: View {
    @Binding var isOpen: Bool
    var color: Color = .primary
    var openLabel = "Open menu"
    var closeLabel = "Close menu"

    @ScaledMetric(relativeTo: .title2) private var size = 24.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            withAnimation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.25)) { isOpen.toggle() }
        } label: {
            HamburgerMenuButtonShape(progress: isOpen ? 1 : 0)
                .stroke(color, style: StrokeStyle(lineWidth: max(size * 0.12, 2), lineCap: .round))
                .frame(width: size, height: size)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOpen ? closeLabel : openLabel)
    }
}

// MARK: - Demo

struct HamburgerMenuButtonDemo: View {
    @State private var isOpen = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HamburgerMenuButton(isOpen: $isOpen)
                Text("Inbox")
                    .font(.system(.title2, design: .rounded, weight: .bold))
            }
            .padding(.horizontal, 12)

            if isOpen {
                VStack(alignment: .leading, spacing: 22) {
                    // One width for every symbol, so the names line up.
                    ForEach([("Inbox", "tray.fill"), ("Starred", "star.fill"), ("Sent", "paperplane.fill"), ("Trash", "trash.fill")], id: \.0) { title, symbol in
                        Label {
                            Text(title)
                        } icon: {
                            Image(systemName: symbol).frame(width: 30)
                        }
                    }
                }
                .font(.title3.weight(.medium))
                .padding(28)
                .transition(reduceMotion ? .opacity : .move(edge: .leading).combined(with: .opacity))
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
    HamburgerMenuButtonDemo()
}
