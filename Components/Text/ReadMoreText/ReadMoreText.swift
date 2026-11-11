// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A paragraph truncated with a fade that expands in place when tapped.
///
/// The button only appears when the text does not fit. With Reduce Motion on, the
/// paragraph changes height at once. VoiceOver always reads the whole paragraph.
struct ReadMoreText: View {
    let text: String
    var collapsedLines = 3
    var moreLabel = "Read more"
    var lessLabel = "Show less"

    @State private var isExpanded = false
    @State private var fullHeight: CGFloat = 0
    @State private var collapsedHeight: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let touchPadding: CGFloat = 13

    private var isTruncated: Bool { fullHeight > collapsedHeight + 1 && collapsedHeight > 0 }
    private var isFaded: Bool { isTruncated && !isExpanded }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { fullHeight = $0 }
                .background { collapsedMeasure }
                .frame(height: isTruncated ? (isExpanded ? fullHeight : collapsedHeight) : nil, alignment: .top)
                .clipped()
                .mask { fade }

            if isTruncated {
                Button {
                    isExpanded.toggle()
                } label: {
                    // A line of text is too short to hit. The padding widens what answers to a
                    // touch, and the same padding taken back keeps the layout as it was.
                    Text(isExpanded ? lessLabel : moreLabel)
                        .padding(.vertical, touchPadding)
                        .contentShape(.rect)
                        .padding(.vertical, -touchPadding)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tint)
            }
        }
        .animation(reduceMotion ? nil : .smooth(duration: 0.4), value: isExpanded)
    }

    // A hidden copy, limited to the collapsed lines, tells how tall the collapsed text is.
    private var collapsedMeasure: some View {
        Text(text)
            .lineLimit(max(collapsedLines, 1))
            .fixedSize(horizontal: false, vertical: true)
            .hidden()
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { collapsedHeight = $0 }
            .accessibilityRepresentation { EmptyView() }
    }

    private var fade: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .black, location: 0),
                .init(color: .black, location: isFaded ? 0.55 : 1),
                .init(color: isFaded ? .clear : .black, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Demo

struct ReadMoreTextDemo: View {
    private let story = "The sea looks blue because water absorbs the red end of the spectrum and scatters the blue back towards your eyes. The deeper the water, the more red is lost, which is why the open ocean looks so much darker than a shallow bay. Near the coast, sand and algae add greens and browns, and a bright sky adds its own reflection to the surface."

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RoundedRectangle(cornerRadius: 24)
                    .fill(LinearGradient(colors: [.cyan, .blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(height: 220)
                    .overlay {
                        Image(systemName: "water.waves")
                            .font(.largeTitle)
                            .imageScale(.large)
                            .foregroundStyle(.white)
                    }
                    .accessibilityHidden(true)

                Text("Why the sea is blue")
                    .font(.title.bold())

                ReadMoreText(text: story)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
        }
    }
}

#Preview {
    ReadMoreTextDemo()
}
