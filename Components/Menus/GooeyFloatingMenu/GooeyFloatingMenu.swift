// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

struct GooeyFloatingMenuItem: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    let action: () -> Void
}

/// A floating button whose options melt out of it like liquid.
///
/// A `Canvas` blurs the circles and then cuts their alpha at a threshold, so shapes that
/// come close merge into one blob. It fits up to about five options.
/// With Reduce Motion on, the options appear without moving.
struct GooeyFloatingMenu: View {
    let items: [GooeyFloatingMenuItem]
    var tint: Color = .indigo

    @State private var isOpen = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var animation: Animation? {
        reduceMotion ? nil : .spring(duration: 0.7, bounce: 0.25)
    }

    var body: some View {
        GooeyFloatingMenuStage(
            progress: isOpen ? 1 : 0,
            items: items,
            tint: tint,
            isOpen: isOpen,
            toggle: { withAnimation(animation) { isOpen.toggle() } },
            select: { item in
                withAnimation(animation) { isOpen = false }
                item.action()
            }
        )
        // The buttons only hold icons. The stage reads its size under this cap, which keeps the fan on screen.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

/// `Animatable` re-evaluates the body on every frame, so the drawing and the buttons share one progress.
private struct GooeyFloatingMenuStage: View, Animatable {
    var progress: Double
    let items: [GooeyFloatingMenuItem]
    let tint: Color
    let isOpen: Bool
    let toggle: () -> Void
    let select: (GooeyFloatingMenuItem) -> Void

    @ScaledMetric(relativeTo: .title2) private var buttonSize = 64.0

    nonisolated var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    private var radius: Double { buttonSize * 2.1 }
    private var width: Double { (radius + buttonSize) * 2 }
    private var height: Double { radius + buttonSize * 2 }
    private var anchor: CGPoint { CGPoint(x: width / 2, y: height - buttonSize * 0.75) }

    private func center(of index: Int) -> CGPoint {
        let target = GooeyFloatingMenuMath.offset(index: index, count: items.count, radius: radius)
        let travel = GooeyFloatingMenuMath.staggered(progress, index: index, count: items.count)
        return CGPoint(x: anchor.x + target.width * travel, y: anchor.y + target.height * travel)
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(tint.gradient)
                .mask { blobs }
                .shadow(color: tint.opacity(0.45), radius: 14, y: 8)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let travel = GooeyFloatingMenuMath.staggered(progress, index: index, count: items.count)

                Button { select(item) } label: {
                    Image(systemName: item.systemImage)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: buttonSize * 0.8, height: buttonSize * 0.8)
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .opacity(min(max(travel * 2 - 1, 0), 1))
                .position(center(of: index))
                .allowsHitTesting(isOpen)
                .accessibilityLabel(item.title)
                .accessibilityHidden(!isOpen)
            }

            Button(action: toggle) {
                Image(systemName: "plus")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(45 * progress))
                    .frame(width: buttonSize, height: buttonSize)
                    .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .position(anchor)
            .accessibilityLabel("Menu")
            .accessibilityValue(isOpen ? "Open" : "Closed")
        }
        .frame(width: width, height: height)
    }

    private var blobs: some View {
        Canvas { context, _ in
            let blur = buttonSize * 0.2
            context.addFilter(.alphaThreshold(min: 0.5, color: .white))
            context.addFilter(.blur(radius: blur))

            context.drawLayer { layer in
                func circle(at center: CGPoint, diameter: Double) {
                    let rect = CGRect(x: center.x - diameter / 2, y: center.y - diameter / 2, width: diameter, height: diameter)
                    layer.fill(Path(ellipseIn: rect), with: .color(.white))
                }

                circle(at: anchor, diameter: buttonSize + blur * 0.5)
                for index in items.indices {
                    let travel = min(GooeyFloatingMenuMath.staggered(progress, index: index, count: items.count), 1)
                    circle(at: center(of: index), diameter: buttonSize * (0.55 + 0.3 * travel) + blur * 0.5)
                }
            }
        }
    }
}

enum GooeyFloatingMenuMath {
    /// Where an option ends up, fanned across the top of the main button.
    static func offset(index: Int, count: Int, radius: Double) -> CGSize {
        let spread = Double.pi * 0.8
        let step = count > 1 ? spread / Double(count - 1) : 0
        let start = count > 1 ? -Double.pi / 2 - spread / 2 : -Double.pi / 2
        let angle = start + step * Double(index)
        return CGSize(width: cos(angle) * radius, height: sin(angle) * radius)
    }

    /// Each option starts a little after the previous one, and all arrive together at 1.
    static func staggered(_ progress: Double, index: Int, count: Int) -> Double {
        guard count > 1 else { return max(progress, 0) }
        let delay = 0.35 * Double(index) / Double(count - 1)
        return max((progress - delay) / (1 - delay), 0)
    }
}

// MARK: - Demo

struct GooeyFloatingMenuDemo: View {
    @State private var lastAction = "Pick an option"

    private var items: [GooeyFloatingMenuItem] {
        [
            GooeyFloatingMenuItem(id: "camera", title: "Camera", systemImage: "camera.fill") { lastAction = "Camera" },
            GooeyFloatingMenuItem(id: "note", title: "Note", systemImage: "square.and.pencil") { lastAction = "Note" },
            GooeyFloatingMenuItem(id: "voice", title: "Voice", systemImage: "waveform") { lastAction = "Voice" },
            GooeyFloatingMenuItem(id: "favorite", title: "Favorite", systemImage: "heart.fill") { lastAction = "Favorite" },
        ]
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(red: 0.07, green: 0.07, blue: 0.16), Color(red: 0.14, green: 0.1, blue: 0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Text(lastAction)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            GooeyFloatingMenu(items: items, tint: .pink)
                .padding(.bottom, 24)
        }
    }
}

#Preview {
    GooeyFloatingMenuDemo()
}
