// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

import PhotosUI
import SwiftUI

/// A photo picker limited to `maxCount` photos, with a tray of thumbnails that can be removed.
///
/// `thumbnail` draws each photo. `MultiPhotoPickerTrayThumbnail` loads one from the library.
struct MultiPhotoPickerTray<Thumbnail: View>: View {
    @Binding var selection: [PhotosPickerItem]
    var maxCount: Int = 5
    @ViewBuilder var thumbnail: (PhotosPickerItem) -> Thumbnail

    @ScaledMetric(relativeTo: .body) private var tileSize: CGFloat = 92
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var limit: Int { max(1, maxCount) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    counter
                    Spacer()
                    picker
                }
                VStack(alignment: .leading, spacing: 8) {
                    counter
                    picker
                }
            }

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    if selection.isEmpty {
                        emptyTile
                    }
                    ForEach(Array(selection.enumerated()), id: \.element) { index, item in
                        tile(for: item, position: index + 1)
                            .transition(.scale(scale: 0.6).combined(with: .opacity))
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.3), value: selection)
    }

    private var counter: some View {
        Text("\(selection.count) of \(limit) photos")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
            .contentTransition(.numericText())
    }

    private var picker: some View {
        PhotosPicker(
            selection: $selection,
            maxSelectionCount: limit,
            selectionBehavior: .ordered,
            matching: .images
        ) {
            Label("Choose Photos", systemImage: "photo.badge.plus")
                .font(.subheadline.weight(.semibold))
        }
    }

    private var emptyTile: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(.tertiary, style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
            .frame(width: tileSize, height: tileSize)
            .overlay {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
            }
            .accessibilityElement()
            .accessibilityLabel("No photos selected")
    }

    private func tile(for item: PhotosPickerItem, position: Int) -> some View {
        thumbnail(item)
            .frame(width: tileSize, height: tileSize)
            .clipShape(.rect(cornerRadius: 16, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Photo \(position)")
            .overlay(alignment: .topTrailing) {
                Button {
                    selection.removeAll { $0 == item }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.55))
                        .frame(minWidth: 44, minHeight: 44, alignment: .topTrailing)
                        .padding(4)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove photo \(position)")
            }
    }
}

/// Loads a picked photo as a small thumbnail.
struct MultiPhotoPickerTrayThumbnail: View {
    let item: PhotosPickerItem

    @State private var image: Image?
    @State private var didFail = false

    var body: some View {
        ZStack {
            Rectangle().fill(.quaternary)
            if let image {
                image
                    .resizable()
                    .scaledToFill()
            } else if didFail {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Photo could not be loaded")
            } else {
                ProgressView()
            }
        }
        .task(id: item) {
            image = nil
            didFail = false
            let data = try? await item.loadTransferable(type: Data.self)
            let thumbnail = await data.flatMap { UIImage(data: $0) }?.byPreparingThumbnail(ofSize: CGSize(width: 300, height: 300))
            guard !Task.isCancelled else { return }
            guard let thumbnail else {
                didFail = true
                return
            }
            image = Image(uiImage: thumbnail)
        }
    }
}

// MARK: - Demo

struct MultiPhotoPickerTrayDemo: View {
    @State private var selection: [PhotosPickerItem] = (0..<4).map {
        PhotosPickerItem(itemIdentifier: "demo-\($0)")
    }

    private let placeholders: [(symbol: String, colors: [Color])] = [
        ("mountain.2.fill", [.indigo, .cyan]),
        ("sun.max.fill", [.orange, .pink]),
        ("leaf.fill", [.green, .teal]),
        ("moon.stars.fill", [.purple, .blue]),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("New Album")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("Pick up to five photos to share.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            MultiPhotoPickerTray(selection: $selection, maxCount: 5) { item in
                if let placeholder = placeholder(for: item) {
                    ZStack {
                        LinearGradient(colors: placeholder.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                        Image(systemName: placeholder.symbol)
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                } else {
                    MultiPhotoPickerTrayThumbnail(item: item)
                }
            }
            .padding(18)
            .background(.background, in: .rect(cornerRadius: 24, style: .continuous))

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private func placeholder(for item: PhotosPickerItem) -> (symbol: String, colors: [Color])? {
        guard
            let identifier = item.itemIdentifier,
            identifier.hasPrefix("demo-"),
            let index = Int(identifier.dropFirst(5)),
            placeholders.indices.contains(index)
        else { return nil }
        return placeholders[index]
    }
}

#Preview {
    MultiPhotoPickerTrayDemo()
}
