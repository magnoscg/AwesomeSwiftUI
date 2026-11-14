// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

/// How many columns fit in a width.
enum AdaptiveColumnsGridMath {
    /// Always at least 1, and never more than `maxColumns`.
    static func columnCount(width: CGFloat, minColumnWidth: CGFloat, spacing: CGFloat, maxColumns: Int) -> Int {
        let limit = max(1, min(maxColumns, 1_000))
        guard width.isFinite, width > 0, minColumnWidth.isFinite, minColumnWidth > 0 else { return 1 }
        let gap = spacing.isFinite ? max(0, spacing) : 0
        let fitting = ((width + gap) / (minColumnWidth + gap)).rounded(.down)
        return max(1, min(limit, Int(min(fitting, 1_000))))
    }
}

/// A grid that computes its column count from the width it gets: fewer columns on
/// iPhone, more on iPad, with an upper limit that `.adaptive` grid items do not offer.
struct AdaptiveColumnsGrid<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    var minColumnWidth: CGFloat = 150
    var spacing: CGFloat = 12
    var maxColumns = 6
    @ViewBuilder let content: (Data.Element) -> Content

    @State private var width: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var gap: CGFloat { spacing.isFinite ? max(0, spacing) : 0 }

    private var columnCount: Int {
        AdaptiveColumnsGridMath.columnCount(width: width, minColumnWidth: minColumnWidth, spacing: gap, maxColumns: maxColumns)
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: gap), count: columnCount), spacing: gap) {
            ForEach(data) { element in
                content(element)
            }
        }
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width }, action: { newWidth in
            // The first measurement is not a change the person should see animate.
            var transaction = Transaction()
            transaction.disablesAnimations = width == 0
            withTransaction(transaction) { width = newWidth }
        })
        .animation(reduceMotion ? nil : .smooth(duration: 0.4), value: columnCount)
    }
}

// MARK: - Demo

struct AdaptiveColumnsGridDemo: View {
    private struct Tile: Identifiable {
        let id: Int
        var color: Color { [.indigo, .teal, .pink, .orange, .mint, .purple][id % 6] }
    }

    private enum Size: String, CaseIterable, Identifiable {
        case narrow = "Narrow", medium = "Medium", wide = "Wide"

        var id: Self { self }
        var width: CGFloat {
            switch self {
            case .narrow: 170
            case .medium: 270
            case .wide: 362
            }
        }
    }

    @State private var size = Size.narrow
    /// Only for this demo: it plays by itself until someone touches it.
    @State private var isAutoPlaying = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var selection: Binding<Size> {
        Binding(get: { size }, set: { newValue in
            isAutoPlaying = false
            size = newValue
        })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("Width", selection: selection) {
                    ForEach(Size.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                AdaptiveColumnsGrid(data: (0..<12).map(Tile.init), minColumnWidth: 80, spacing: 10) { tile in
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(tile.color.gradient)
                        .frame(height: 72)
                        .overlay {
                            Text("\(tile.id + 1)")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                }
                .frame(maxWidth: size.width)
            }
            .padding(20)
        }
        .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in isAutoPlaying = false })
        .task(id: isAutoPlaying && !reduceMotion) {
            guard isAutoPlaying, !reduceMotion else { return }
            while isAutoPlaying {
                try? await Task.sleep(for: .seconds(1.1))
                guard !Task.isCancelled, isAutoPlaying else { return }
                let all = Size.allCases
                let next = ((all.firstIndex(of: size) ?? 0) + 1) % all.count
                withAnimation(.smooth(duration: 0.4)) { size = all[next] }
            }
        }
    }
}

#Preview {
    AdaptiveColumnsGridDemo()
}
