// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// A dark overlay with a soft hole that follows the finger.
///
/// The hole only moves with the finger, so it needs no change for Reduce Motion.
struct SpotlightOverlay: ViewModifier {
    /// The center of the hole, as a fraction of the view.
    @Binding var center: UnitPoint
    var radius: Double = 130
    /// How much of the radius is the soft edge, from 0 to 1.
    var softness: Double = 0.55
    var dimming: Color = .black.opacity(0.88)

    func body(content: Content) -> some View {
        content.overlay {
            GeometryReader { proxy in
                // Past its end radius the gradient keeps its last color, so one fill is both the hole and the dark.
                Rectangle()
                    .fill(RadialGradient(
                        stops: [
                            .init(color: dimming.opacity(0), location: 1 - softness),
                            .init(color: dimming, location: 1),
                        ],
                        center: center,
                        startRadius: 0,
                        endRadius: radius
                    ))
                    .contentShape(.rect)
                    .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                        center = UnitPoint(
                            x: value.location.x / max(proxy.size.width, 1),
                            y: value.location.y / max(proxy.size.height, 1)
                        )
                    })
            }
            .accessibilityHidden(true)
        }
    }
}

extension View {
    /// Darkens this view except for a soft hole at `center`, which follows the finger.
    func spotlightOverlay(
        center: Binding<UnitPoint>,
        radius: Double = 130,
        softness: Double = 0.55,
        dimming: Color = .black.opacity(0.88)
    ) -> some View {
        modifier(SpotlightOverlay(center: center, radius: radius, softness: softness, dimming: dimming))
    }
}

// MARK: - Demo

struct SpotlightOverlayDemo: View {
    @State private var center = UnitPoint(x: 0.5, y: 0.45)
    @State private var isAutoPlaying = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let symbols = [
        "star.fill", "heart.fill", "bolt.fill", "leaf.fill", "flame.fill", "drop.fill", "moon.fill",
        "sun.max.fill", "cloud.fill", "snowflake", "key.fill", "crown.fill", "gift.fill", "bell.fill",
        "camera.fill", "music.note", "paperplane.fill", "globe.americas.fill", "pawprint.fill", "fish.fill",
        "tortoise.fill", "hare.fill", "ladybug.fill", "ant.fill", "sparkles", "diamond.fill", "gamecontroller.fill",
        "airplane",
    ]
    private let palette: [Color] = [.pink, .orange, .yellow, .mint, .teal, .blue, .purple]

    /// Lets a finger take over from the automatic movement.
    private var touchCenter: Binding<UnitPoint> {
        Binding(
            get: { center },
            set: { newValue in
                isAutoPlaying = false
                center = newValue
            }
        )
    }

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.16)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(symbols.indices, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 18)
                        .fill(palette[index % palette.count].gradient)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            Image(systemName: symbols[index])
                                .font(.title)
                                .foregroundStyle(.white)
                        }
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 16)
        }
        .spotlightOverlay(center: touchCenter)
        .overlay(alignment: .bottom) {
            Text("Drag to explore")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.bottom, 44)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .task { await autoPlay() }
    }

    /// Only the demo moves the hole by itself, until the first touch.
    private func autoPlay() async {
        guard !reduceMotion else { return }

        let start = Date.now
        while isAutoPlaying, !Task.isCancelled {
            let time = Date.now.timeIntervalSince(start)
            center = UnitPoint(x: 0.5 + 0.3 * sin(time * 1.7), y: 0.45 + 0.27 * sin(time * 1.1 + 0.6))
            try? await Task.sleep(for: .milliseconds(16))
        }
    }
}

#Preview {
    SpotlightOverlayDemo()
}
