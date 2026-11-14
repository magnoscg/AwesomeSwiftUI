// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import SwiftUI

nonisolated enum TabsPickerPagesLogic {
    /// Whether going from one option to another moves forward through the options, which decides
    /// the side the new page comes in from. An option that is not listed counts as the first.
    static func movesForward<Option: Equatable>(from old: Option, to new: Option, in options: [Option]) -> Bool {
        (options.firstIndex(of: new) ?? 0) >= (options.firstIndex(of: old) ?? 0)
    }
}

/// A row of tabs over a page that changes with them, using the tabs picker style that iOS 27
/// added to `Picker`. On an iPhone the system draws it much like a segmented control, with
/// the text of each label.
///
/// The new page slides in from the side its tab is on. It is a system `Picker`, so VoiceOver
/// and the keyboard are the system's. With Reduce Motion on, the pages cross-fade.
@available(iOS 27, *)
struct TabsPickerPages<Option: Hashable, Label: View, Page: View>: View {
    let options: [Option]
    @Binding var selection: Option
    var title = "Section"
    @ViewBuilder var label: (Option) -> Label
    @ViewBuilder var page: (Option) -> Page

    @State private var movesForward = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 16) {
            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    label(option)
                        .tag(option)
                }
            }
            .pickerStyle(.tabs)

            page(selection)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .id(selection)
                .transition(transition)
        }
        .onChange(of: selection) { old, new in
            movesForward = TabsPickerPagesLogic.movesForward(from: old, to: new, in: options)
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .snappy(duration: 0.35), value: selection)
    }

    private var transition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        return .asymmetric(
            insertion: .move(edge: movesForward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: movesForward ? .leading : .trailing).combined(with: .opacity)
        )
    }
}

// MARK: - Demo

@available(iOS 27, *)
struct TabsPickerPagesDemo: View {
    private enum Section: String, CaseIterable {
        case overview = "Overview"
        case activity = "Activity"
        case files = "Files"

        var symbol: String {
            switch self {
            case .overview: "square.grid.2x2"
            case .activity: "chart.line.uptrend.xyaxis"
            case .files: "folder"
            }
        }

        var rows: [String] {
            switch self {
            case .overview: ["Launch plan", "Budget", "Team"]
            case .activity: ["Ana updated the budget", "Leo added two files", "Mia closed a task"]
            case .files: ["Brief.pdf", "Timeline.numbers", "Logo.svg", "Notes.txt"]
            }
        }
    }

    @State private var section = Section.overview

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spring Launch")
                .font(.largeTitle.bold())

            TabsPickerPages(options: Section.allCases, selection: $section) { section in
                SwiftUI.Label(section.rawValue, systemImage: section.symbol)
            } page: { section in
                VStack(spacing: 10) {
                    ForEach(section.rows, id: \.self) { row in
                        Text(row)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(.background, in: .rect(cornerRadius: 14))
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemGroupedBackground))
    }
}

@available(iOS 27, *)
#Preview {
    TabsPickerPagesDemo()
}
