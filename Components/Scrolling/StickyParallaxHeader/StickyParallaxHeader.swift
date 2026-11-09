// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

/// A header that stretches on overscroll, drifts at half speed and collapses into a pinned bar.
///
/// `title` receives how collapsed the header is, from 0 to 1.
/// With Reduce Motion on, the backdrop does not drift.
struct StickyParallaxHeader<Backdrop: View, Title: View, Content: View>: View {
    var expandedHeight: CGFloat = 260
    var collapsedHeight: CGFloat = 60
    @ViewBuilder var backdrop: () -> Backdrop
    @ViewBuilder var title: (_ collapse: CGFloat) -> Title
    @ViewBuilder var content: () -> Content

    @State private var offset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let fullHeight = expandedHeight + proxy.safeAreaInsets.top
            let pinnedHeight = collapsedHeight + proxy.safeAreaInsets.top
            let height = max(pinnedHeight, fullHeight - offset)
            let collapse = min(max(offset / max(fullHeight - pinnedHeight, 1), 0), 1)

            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: fullHeight)
                        content()
                    }
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y + geometry.contentInsets.top
                } action: { _, newOffset in
                    offset = newOffset
                }

                header(height: height, fullHeight: fullHeight, collapse: collapse)
            }
            .ignoresSafeArea(edges: .top)
        }
    }

    private func header(height: CGFloat, fullHeight: CGFloat, collapse: CGFloat) -> some View {
        backdrop()
            .frame(maxWidth: .infinity)
            .frame(height: max(fullHeight, height))
            .offset(y: reduceMotion ? 0 : -max(offset, 0) * 0.5)
            .frame(height: height, alignment: .top)
            .clipped()
            .accessibilityHidden(true)
            .overlay(alignment: .bottomLeading) {
                title(collapse)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
            }
            .allowsHitTesting(false)
    }
}

// MARK: - Demo

struct StickyParallaxHeaderDemo: View {
    @ScaledMetric(relativeTo: .largeTitle) private var collapsedHeight = 60.0

    private let trails = ["Tre Cime", "Seceda Ridge", "Lago di Braies", "Alpe di Siusi", "Sass Pordoi", "Cinque Torri", "Val di Funes", "Marmolada", "Passo Giau", "Lagazuoi"]

    var body: some View {
        StickyParallaxHeader(collapsedHeight: collapsedHeight) {
            ZStack(alignment: .bottom) {
                LinearGradient(colors: [.indigo, .purple, .orange], startPoint: .top, endPoint: .bottom)
                Image(systemName: "mountain.2.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.black.opacity(0.35))
                    .padding(.horizontal, 24)
                    .offset(y: 30)
            }
        } title: { collapse in
            VStack(alignment: .leading, spacing: 0) {
                Text("Dolomites")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .scaleEffect(1 - 0.3 * collapse, anchor: .bottomLeading)
                Text("10 trails nearby")
                    .font(.subheadline)
                    .opacity(1 - collapse * 2)
                    .frame(height: collapse > 0.5 ? 0 : nil, alignment: .top)
            }
            .foregroundStyle(.white)
        } content: {
            LazyVStack(spacing: 12) {
                ForEach(trails, id: \.self) { trail in
                    HStack(spacing: 14) {
                        Image(systemName: "figure.hiking")
                            .font(.title3)
                            .foregroundStyle(.indigo)
                            .accessibilityHidden(true)
                        Text(trail)
                            .font(.headline)
                        Spacer()
                    }
                    .padding(18)
                    .background(.indigo.opacity(0.1), in: .rect(cornerRadius: 18))
                }
            }
            .padding(16)
        }
    }
}

#Preview {
    StickyParallaxHeaderDemo()
}
