// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import SwiftUI

enum SelectAllChecklistState: Equatable {
    case none, some, all

    /// Counts only the items in the list, so a selection kept from elsewhere does not make it look full.
    init<ID: Hashable>(selection: Set<ID>, among ids: [ID]) {
        let selected = ids.filter(selection.contains).count
        if ids.isEmpty || selected == 0 {
            self = .none
        } else {
            self = selected == ids.count ? .all : .some
        }
    }

    /// Selects every item unless all are selected, then deselects them, and leaves any other ID alone.
    static func toggledAll<ID: Hashable>(_ selection: Set<ID>, among ids: [ID]) -> Set<ID> {
        if SelectAllChecklistState(selection: selection, among: ids) == .all {
            return selection.subtracting(ids)
        }
        return selection.union(ids)
    }
}

/// A list of checkable rows under a "select all" box that is checked when every
/// row is, shows a dash when only some are, and counts them.
///
/// The selection is a `Set` of IDs, like a `List` with selection. With Reduce
/// Motion on, the checkmarks appear without being drawn.
struct SelectAllChecklist<Item: Identifiable, Row: View>: View {
    let title: LocalizedStringResource
    let items: [Item]
    @Binding var selection: Set<Item.ID>
    var color: Color = .accentColor
    @ViewBuilder let row: (Item) -> Row

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// At accessibility sizes the count goes under the title, so the title is not broken mid-word.
    private var headerLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(spacing: 8))
    }

    private var ids: [Item.ID] { items.map(\.id) }
    private var state: SelectAllChecklistState { SelectAllChecklistState(selection: selection, among: ids) }
    private var selectedCount: Int { ids.filter(selection.contains).count }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                selection = SelectAllChecklistState.toggledAll(selection, among: ids)
            } label: {
                HStack(spacing: 12) {
                    SelectAllChecklistBox(state: state, color: color)
                    headerLayout {
                        Text(title)
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(selectedCount) of \(items.count)")
                            .font(.subheadline)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText(value: Double(selectedCount)))
                    }
                }
                .padding(.vertical, 8)
                .frame(minHeight: 44)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityValue(Text("\(selectedCount) of \(items.count) selected"))
            .accessibilityAddTraits(state == .all ? .isSelected : [])

            Divider()

            ForEach(items) { item in
                let isSelected = selection.contains(item.id)

                Button {
                    if isSelected { selection.remove(item.id) } else { selection.insert(item.id) }
                } label: {
                    HStack(spacing: 12) {
                        SelectAllChecklistBox(state: isSelected ? .all : .none, color: color)
                        row(item)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 6)
                    .frame(minHeight: 44)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
        .animation(.snappy(duration: 0.2), value: selectedCount)
    }
}

private struct SelectAllChecklistBox: View {
    let state: SelectAllChecklistState
    let color: Color

    @ScaledMetric(relativeTo: .body) private var size = 22.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
        let mark = SelectAllChecklistContrastingForeground(background: color)
        let lineWidth = size * 0.12
        let isFilled = state != .none

        ZStack {
            shape.fill(isFilled ? color : .clear)
            shape.strokeBorder(isFilled ? color : Color.secondary.opacity(0.6), lineWidth: lineWidth)

            if state == .some {
                Capsule()
                    .fill(mark)
                    .frame(width: size * 0.5, height: lineWidth)
                    .transition(.opacity)
            } else {
                SelectAllChecklistCheck()
                    .trim(from: 0, to: state == .all ? 1 : 0)
                    .stroke(mark, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(width: size, height: size)
        // A checkmark is not mirrored right-to-left, like the system symbol.
        .environment(\.layoutDirection, .leftToRight)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.22), value: state)
        .accessibilityHidden(true)
    }
}

nonisolated struct SelectAllChecklistCheck: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.26, y: rect.height * 0.52))
        path.addLine(to: CGPoint(x: rect.width * 0.43, y: rect.height * 0.69))
        path.addLine(to: CGPoint(x: rect.width * 0.75, y: rect.height * 0.33))
        return path
    }
}

nonisolated struct SelectAllChecklistContrastingForeground: ShapeStyle {
    let background: Color

    func resolve(in environment: EnvironmentValues) -> Color {
        let color = background.resolve(in: environment)
        let luminance = 0.2126 * color.linearRed + 0.7152 * color.linearGreen + 0.0722 * color.linearBlue
        return luminance > 0.5 ? .black : .white
    }
}

// MARK: - Demo

private struct SelectAllChecklistDemoEpisode: Identifiable {
    let id: Int
    let title: String
    let size: String
}

struct SelectAllChecklistDemo: View {
    @State private var selection: Set<Int> = [2]

    private let episodes = [
        SelectAllChecklistDemoEpisode(id: 1, title: "The Shape of Light", size: "48 MB"),
        SelectAllChecklistDemoEpisode(id: 2, title: "Islands in the Stream", size: "62 MB"),
        SelectAllChecklistDemoEpisode(id: 3, title: "A Year Without Winter", size: "55 MB"),
        SelectAllChecklistDemoEpisode(id: 4, title: "Night Trains", size: "39 MB"),
        SelectAllChecklistDemoEpisode(id: 5, title: "The Last Lighthouse", size: "71 MB"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Downloads")
                    .font(.largeTitle.bold())

                SelectAllChecklist(title: "All Episodes", items: episodes, selection: $selection, color: .teal) { episode in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(episode.title)
                        Text(episode.size)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 20, style: .continuous))
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
    }
}

#Preview {
    SelectAllChecklistDemo()
}
