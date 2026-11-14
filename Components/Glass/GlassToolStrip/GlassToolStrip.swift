// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

@available(iOS 26, *)
struct GlassToolStripTool: Identifiable {
    let id: String
    let title: LocalizedStringResource
    let systemImage: String
    /// Tools with the same group share one piece of glass. Nil keeps the tool on its own.
    var group: String?
}

/// A row of Liquid Glass tool buttons, with related tools fused into one shape.
///
/// With Reduce Motion on, tools change without animating.
@available(iOS 26, *)
struct GlassToolStrip: View {
    let tools: [GlassToolStripTool]
    @Binding var selection: String?
    var isGrouped = true
    var tint: Color = .accentColor

    @Namespace private var namespace
    @ScaledMetric(relativeTo: .title3) private var buttonSize = 52.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // Scrolls only when Dynamic Type makes the row wider than the space it has.
        ViewThatFits(in: .horizontal) {
            strip

            ScrollView(.horizontal, showsIndicators: false) {
                strip
            }
            .scrollClipDisabled()
        }
    }

    private var strip: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 14) {
                ForEach(tools) { tool in
                    toolButton(tool)
                }
            }
        }
    }

    private func toolButton(_ tool: GlassToolStripTool) -> some View {
        let isSelected = tool.id == selection

        return Button {
            withAnimation(reduceMotion ? nil : .snappy) {
                selection = isSelected ? nil : tool.id
            }
        } label: {
            Image(systemName: tool.systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(isSelected ? tint : .primary)
                .frame(width: buttonSize, height: buttonSize)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tool.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        // A union shares one shape across its members, so it has to be a capsule, and
        // selection only tints the symbol. A square capsule draws as a circle on its own.
        .glassEffect(.regular.interactive(), in: .capsule)
        .glassEffectUnion(id: isGrouped ? tool.group : nil, namespace: namespace)
    }
}

// MARK: - Demo

@available(iOS 26, *)
struct GlassToolStripDemo: View {
    @State private var selection: String? = "pen"
    @State private var isGrouped = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let tools = [
        GlassToolStripTool(id: "pen", title: "Pen", systemImage: "pencil.tip", group: "draw"),
        GlassToolStripTool(id: "marker", title: "Marker", systemImage: "highlighter", group: "draw"),
        GlassToolStripTool(id: "eraser", title: "Eraser", systemImage: "eraser", group: "draw"),
        GlassToolStripTool(id: "lasso", title: "Lasso", systemImage: "lasso", group: "edit"),
        GlassToolStripTool(id: "ruler", title: "Ruler", systemImage: "ruler", group: "edit"),
    ]

    var body: some View {
        ZStack {
            MeshGradient(
                width: 2,
                height: 2,
                points: [[0, 0], [1, 0], [0, 1], [1, 1]],
                colors: [.pink, .orange, .purple, .blue]
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                GlassToolStrip(tools: tools, selection: $selection, isGrouped: isGrouped, tint: .indigo)

                Button("Group tools", systemImage: isGrouped ? "square.split.2x1" : "square.on.square") {
                    withAnimation(reduceMotion ? nil : .bouncy(duration: 0.5)) { isGrouped.toggle() }
                }
                .buttonStyle(.glass)
                .accessibilityValue(isGrouped ? "On" : "Off")
            }
        }
    }
}

@available(iOS 26, *)
#Preview {
    GlassToolStripDemo()
}
