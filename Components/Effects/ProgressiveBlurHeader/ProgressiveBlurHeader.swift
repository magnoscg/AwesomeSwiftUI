// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

nonisolated enum ProgressiveBlurHeaderMath {
    /// How much of the blur a point gets at a distance from the top edge: all of it at the edge
    /// and none from `height` down, along the same smooth curve the shader uses.
    static func strength(at distance: Double, height: Double) -> Double {
        guard height > 0, distance.isFinite else { return 0 }
        let share = min(max(distance / height, 0), 1)
        return 1 - share * share * (3 - 2 * share)
    }

    /// The function in `ProgressiveBlurHeader.metal`, with its arguments in the order it declares them.
    static func shader(top: Double, height: Double, radius: Double, isHorizontal: Bool) -> Shader {
        ShaderLibrary.ProgressiveBlurHeaderPass(
            .float(top),
            .float(max(height, 0)),
            .float(max(radius, 0)),
            .float2(isHorizontal ? 1 : 0, isHorizontal ? 0 : 1)
        )
    }
}

extension View {
    /// Blurs this view more and more toward the top edge of the scroll view it is in, drawn by a
    /// Metal shader, so what scrolls under a header melts away instead of meeting a hard bar.
    /// Put it on the content of a `ScrollView`, not on the scroll view.
    ///
    /// Copy two files into the same target: `ProgressiveBlurHeader.swift` and `ProgressiveBlurHeader.metal`.
    /// A shader draws what SwiftUI draws itself: a view backed by UIKit, such as a map or the
    /// scroll view itself, comes out empty.
    ///
    /// With Reduce Transparency on, the content is left sharp.
    func progressiveBlurHeader(height: CGFloat = 130, radius: CGFloat = 14) -> some View {
        modifier(ProgressiveBlurHeaderModifier(height: height, radius: radius))
    }
}

private struct ProgressiveBlurHeaderModifier: ViewModifier {
    let height: CGFloat
    let radius: CGFloat

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content
            // `visualEffect` knows where the content is in the scroll view on every frame, with no state to update.
            .visualEffect { [height, radius, reduceTransparency] view, proxy in
                // The line of the content that sits at the top edge of the scroll view.
                let top = -proxy.frame(in: .scrollView(axis: .vertical)).minY

                return view
                    .layerEffect(
                        ProgressiveBlurHeaderMath.shader(top: top, height: height, radius: radius, isHorizontal: true),
                        maxSampleOffset: CGSize(width: radius, height: 0),
                        isEnabled: !reduceTransparency
                    )
                    .layerEffect(
                        ProgressiveBlurHeaderMath.shader(top: top, height: height, radius: radius, isHorizontal: false),
                        maxSampleOffset: CGSize(width: 0, height: radius),
                        isEnabled: !reduceTransparency
                    )
            }
            // The first use of a shader waits for it to compile. Doing that now keeps the first frames smooth.
            .task {
                try? await ProgressiveBlurHeaderMath.shader(top: 0, height: height, radius: radius, isHorizontal: true).compile(as: .layerEffect)
            }
    }
}

// MARK: - Demo

struct ProgressiveBlurHeaderDemo: View {
    private let entries: [(title: String, text: String, colors: [Color])] = [
        ("Morning Light", "The harbor before the boats go out.", [.orange, .pink]),
        ("Slow Roads", "Three days with no highway in sight.", [.teal, .blue]),
        ("Market Day", "Peaches, noise and a very loud rooster.", [.yellow, .orange]),
        ("High Tide", "A beach that is only there at noon.", [.cyan, .indigo]),
        ("Old Stones", "A wall that outlived the town it kept.", [.gray, .brown]),
        ("Night Train", "Twelve hours, one window, no hurry.", [.indigo, .purple]),
    ]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(entries, id: \.title) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        Spacer()
                        Text(entry.title)
                            .font(.title2.bold())
                        Text(entry.text)
                            .font(.subheadline)
                    }
                    .foregroundStyle(.white)
                    .padding(18)
                    .frame(maxWidth: .infinity, minHeight: 170, alignment: .leading)
                    .background(LinearGradient(colors: entry.colors, startPoint: .topLeading, endPoint: .bottomTrailing), in: .rect(cornerRadius: 22))
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 130)
            .progressiveBlurHeader()
        }
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .top) {
            HStack {
                Text("Journal")
                    .font(.largeTitle.bold())
                Spacer()
                Image(systemName: "square.and.pencil")
                    .font(.title2)
                    .accessibilityLabel("New entry")
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 44)
            .background {
                // A veil over the blur keeps the title readable whatever scrolls under it.
                LinearGradient(colors: [Color(.systemBackground).opacity(0.9), Color(.systemBackground).opacity(0)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea(edges: .top)
                    .allowsHitTesting(false)
            }
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    ProgressiveBlurHeaderDemo()
}
