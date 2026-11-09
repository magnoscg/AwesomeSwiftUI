// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// A card that publishes its corners, so `ConcentricCardSurface` views inside stay concentric.
@available(iOS 26, *)
struct ConcentricCard<Background: ShapeStyle, Content: View>: View {
    var cornerRadius: CGFloat = 36
    var padding: CGFloat = 12
    let background: Background
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(background, in: .rect(cornerRadius: cornerRadius))
            .containerShape(.rect(cornerRadius: cornerRadius))
    }
}

/// A surface whose corners follow the nearest container shape, however deep or inset it sits.
///
/// `minimumRadius` stops corners from turning square far from the container's edge.
@available(iOS 26, *)
struct ConcentricCardSurface<Background: ShapeStyle, Content: View>: View {
    var padding: CGFloat = 12
    var minimumRadius: CGFloat = 8
    let background: Background
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(background, in: ConcentricRectangle(corners: .concentric(minimum: .fixed(minimumRadius))))
    }
}

// MARK: - Demo

@available(iOS 26, *)
struct ConcentricCardDemo: View {
    @State private var inset: CGFloat = 8
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, .indigo], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ConcentricCard(cornerRadius: 56, padding: inset, background: Color.white.opacity(0.16)) {
                ConcentricCardSurface(padding: inset, background: Color.orange.gradient) {
                    VStack(alignment: .leading, spacing: inset) {
                        Label("Concentric", systemImage: "circle.circle")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .padding(16)
                            .frame(maxWidth: .infinity, minHeight: 170, alignment: .bottomLeading)

                        ConcentricCardSurface(background: Color.white) {
                            Text("One shared center")
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(24)
        }
        .task {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1.3))
                withAnimation(.smooth(duration: 0.9)) { inset = inset == 8 ? 20 : 8 }
            }
        }
    }
}

@available(iOS 26, *)
#Preview {
    ConcentricCardDemo()
}
