// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import SwiftUI

struct NestedCommentThreadComment: Identifiable, Hashable {
    let id: String
    let author: String
    let text: String
    var age: String = ""
    var replies: [NestedCommentThreadComment] = []
}

/// Threaded comments with indentation, connector lines and collapsible replies.
///
/// Put it in a `ScrollView`. Indentation stops growing past a few levels, sooner with
/// accessibility text sizes, so deep threads keep room for their text.
struct NestedCommentThread: View {
    let comments: [NestedCommentThreadComment]
    var tint: Color = .indigo

    @State private var collapsed: Set<String> = []
    @ScaledMetric(relativeTo: .subheadline) private var avatarSize = 34.0
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let verticalPadding = 8.0
    private var maximumLevels: Int { dynamicTypeSize.isAccessibilitySize ? 2 : 5 }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(NestedCommentThreadLogic.rows(for: comments, collapsed: collapsed)) { row in
                rowView(row).transition(.opacity)
            }
        }
    }

    private func rowView(_ row: NestedCommentThreadLogic.Row) -> some View {
        let guides = Array(row.guides.suffix(maximumLevels))
        let leading = CGFloat(guides.count) * avatarSize
        let showsStem = !row.comment.replies.isEmpty && !collapsed.contains(row.comment.id)

        return HStack(alignment: .top, spacing: 10) {
            avatar(for: row.comment)
            content(for: row.comment)
        }
        .padding(.vertical, verticalPadding)
        .padding(.leading, leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .leading) {
            HStack(spacing: 0) {
                ForEach(Array(guides.enumerated()), id: \.offset) { index, continues in
                    NestedCommentThreadGuide(
                        continues: continues,
                        elbowY: index == guides.count - 1 ? verticalPadding + avatarSize / 2 : nil
                    )
                    .stroke(.quaternary, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    .frame(width: avatarSize)
                }
            }
        }
        .background(alignment: .topLeading) {
            if showsStem {
                Rectangle()
                    .fill(.quaternary)
                    .frame(width: 1.5)
                    .padding(.top, verticalPadding + avatarSize)
                    .frame(maxHeight: .infinity)
                    .offset(x: leading + avatarSize / 2 - 0.75)
            }
        }
    }

    private func avatar(for comment: NestedCommentThreadComment) -> some View {
        Circle()
            .fill(tint.gradient)
            .frame(width: avatarSize, height: avatarSize)
            .overlay {
                Text(comment.author.prefix(1))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)
    }

    private func content(for comment: NestedCommentThreadComment) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(comment.author).font(.subheadline.weight(.semibold))
                    Text(comment.age).font(.caption).foregroundStyle(.secondary)
                }
                Text(comment.text).font(.subheadline)
            }
            .accessibilityElement(children: .combine)

            if !comment.replies.isEmpty {
                toggle(for: comment)
            }
        }
    }

    private func toggle(for comment: NestedCommentThreadComment) -> some View {
        let isCollapsed = collapsed.contains(comment.id)
        let count = NestedCommentThreadLogic.replyCount(of: comment)
        let title = "\(isCollapsed ? "Show" : "Hide") \(count) \(count == 1 ? "reply" : "replies")"

        return Button {
            withAnimation(reduceMotion ? nil : .snappy) {
                if isCollapsed {
                    collapsed.remove(comment.id)
                } else {
                    collapsed.insert(comment.id)
                }
            }
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
                .frame(minHeight: 28)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) to \(comment.author)")
    }
}

/// One indentation column: a straight line, and for a comment's own level an elbow into it.
private struct NestedCommentThreadGuide: Shape {
    let continues: Bool
    let elbowY: CGFloat?

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if let elbowY {
            let radius = min(10, rect.width / 2)
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: max(rect.minY, elbowY - radius)))
            path.addQuadCurve(to: CGPoint(x: rect.midX + radius, y: elbowY), control: CGPoint(x: rect.midX, y: elbowY))
            path.addLine(to: CGPoint(x: rect.maxX, y: elbowY))
        }
        if continues {
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        }
        return path
    }
}

/// Turns the tree into the flat list of visible rows, apart from the view so it can be tested.
enum NestedCommentThreadLogic {
    struct Row: Identifiable, Equatable {
        let comment: NestedCommentThreadComment
        /// One entry per indentation level: whether its line continues below this row.
        let guides: [Bool]

        var id: String { comment.id }
    }

    static func rows(for comments: [NestedCommentThreadComment], collapsed: Set<String>) -> [Row] {
        var result: [Row] = []

        func visit(_ list: [NestedCommentThreadComment], guides: [Bool], isTopLevel: Bool) {
            for (index, comment) in list.enumerated() {
                let rowGuides = isTopLevel ? [] : guides + [index < list.count - 1]
                result.append(Row(comment: comment, guides: rowGuides))
                if !collapsed.contains(comment.id) {
                    visit(comment.replies, guides: rowGuides, isTopLevel: false)
                }
            }
        }

        visit(comments, guides: [], isTopLevel: true)
        return result
    }

    /// Every reply below a comment, however deep.
    static func replyCount(of comment: NestedCommentThreadComment) -> Int {
        comment.replies.reduce(comment.replies.count) { $0 + replyCount(of: $1) }
    }
}

// MARK: - Demo

struct NestedCommentThreadDemo: View {
    private let comments = [
        NestedCommentThreadComment(id: "1", author: "Marta", text: "Should we ship this behind a flag first?", age: "2h", replies: [
            NestedCommentThreadComment(id: "2", author: "Luis", text: "Yes, at least for the first week.", age: "1h", replies: [
                NestedCommentThreadComment(id: "3", author: "Ana", text: "Agreed. I can watch the metrics.", age: "40m"),
            ]),
            NestedCommentThreadComment(id: "4", author: "Noa", text: "I will set up the flag today.", age: "32m"),
        ]),
        NestedCommentThreadComment(id: "5", author: "Diego", text: "The new empty state looks great.", age: "25m", replies: [
            NestedCommentThreadComment(id: "6", author: "Iris", text: "Thanks! It took a few tries.", age: "12m"),
        ]),
        NestedCommentThreadComment(id: "7", author: "Sara", text: "Can someone review the copy before Friday?", age: "5m"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Discussion")
                    .font(.largeTitle.bold())

                NestedCommentThread(comments: comments)
            }
            .padding(20)
        }
    }
}

#Preview {
    NestedCommentThreadDemo()
}
