// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

/// A scroll view whose content dissolves under a custom header.
///
/// The header sits in a safe area bar, which is what lets the scroll edge effect reach it.
@available(iOS 26, *)
struct ScrollEdgeHeader<Header: View, Content: View>: View {
    var style: ScrollEdgeEffectStyle = .soft
    @ViewBuilder let header: () -> Header
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView(content: content)
            .scrollEdgeEffectStyle(style, for: .top)
            .safeAreaBar(edge: .top, content: header)
    }
}

// MARK: - Demo

@available(iOS 26, *)
struct ScrollEdgeHeaderDemo: View {
    @State private var isHard = false

    private let colors: [Color] = [.pink, .orange, .yellow, .green, .teal, .blue, .indigo, .purple]

    var body: some View {
        ScrollEdgeHeader(style: isHard ? .hard : .soft) {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Today")
                        .font(.largeTitle.bold())

                    Text(isHard ? "Hard edge" : "Soft edge")
                        .font(.subheadline.weight(.medium))
                }

                Spacer()

                Button("Change edge style", systemImage: "circle.lefthalf.filled") {
                    isHard.toggle()
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                // The regular size of an icon in a circle is too small to hit.
                .controlSize(.large)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
        } content: {
            LazyVStack(spacing: 14) {
                ForEach(0..<30, id: \.self) { index in
                    Label("Story \(index + 1)", systemImage: "sparkles")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 120, alignment: .bottomLeading)
                        .padding(18)
                        .background(colors[index % colors.count].gradient, in: .rect(cornerRadius: 24))
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

@available(iOS 26, *)
#Preview {
    ScrollEdgeHeaderDemo()
}
