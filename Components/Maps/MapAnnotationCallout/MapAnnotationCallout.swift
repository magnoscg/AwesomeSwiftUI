// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

import MapKit
import SwiftUI

nonisolated struct MapAnnotationCalloutItem: Identifiable, Hashable, Sendable {
    var id: String
    /// The short text on the pin, such as a price.
    var label: String
    var title: String
    var latitude: Double
    var longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

nonisolated enum MapAnnotationCalloutLogic {
    /// The latitude the camera centers on to show a pin together with its callout: a little north
    /// of the pin, because the callout opens above it. `span` is the latitude the map shows.
    static func centerLatitude(showing latitude: Double, span: Double, shift: Double = 0.2) -> Double {
        guard latitude.isFinite, span.isFinite else { return 0 }
        return min(max(latitude + max(span, 0) * shift, -90), 90)
    }

    /// The region that shows every item with some room around them. Nil when there are none.
    /// `smallest` keeps a single pin, or pins on one spot, from zooming all the way in.
    static func region(fitting items: [MapAnnotationCalloutItem], room: Double = 1.6, smallest: Double = 0.01) -> MKCoordinateRegion? {
        let latitudes = items.map(\.latitude).filter(\.isFinite)
        let longitudes = items.map(\.longitude).filter(\.isFinite)
        guard let south = latitudes.min(), let north = latitudes.max(),
              let west = longitudes.min(), let east = longitudes.max() else { return nil }

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (south + north) / 2, longitude: (west + east) / 2),
            span: MKCoordinateSpan(
                latitudeDelta: min(max((north - south) * room, smallest), 180),
                longitudeDelta: min(max((east - west) * room, smallest), 360)
            )
        )
    }
}

/// A map of pins with a short label each. Tap one and it turns dark and opens a callout above
/// it with whatever you want to show, while the camera moves to fit both. Tap the map to close it.
///
/// VoiceOver reads each pin by its title and label. With Reduce Motion on, the callout fades in
/// and the camera does not fly.
struct MapAnnotationCallout<Callout: View>: View {
    let items: [MapAnnotationCalloutItem]
    @Binding var selection: MapAnnotationCalloutItem.ID?
    var calloutWidth: CGFloat = 220
    @ViewBuilder var callout: (MapAnnotationCalloutItem) -> Callout

    private let shadow = Color.black.opacity(0.2)

    @State private var position = MapCameraPosition.automatic
    @State private var visibleSpan = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Map(position: $position, selection: $selection) {
            ForEach(items) { item in
                Annotation(item.title, coordinate: item.coordinate, anchor: .bottom) {
                    pin(item)
                }
                .annotationTitles(.hidden)
                .tag(item.id)
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .onMapCameraChange { context in
            visibleSpan = context.region.span
        }
        // The map starts on a region of its own, so the span is known from the start. With the
        // automatic camera it is not, and the first pin tapped also zoomed the map.
        .onAppear {
            guard let region = MapAnnotationCalloutLogic.region(fitting: items) else { return }
            position = .region(region)
            visibleSpan = region.span
        }
        .onChange(of: selection) { _, id in
            guard let item = items.first(where: { $0.id == id }) else { return }
            let latitude = MapAnnotationCalloutLogic.centerLatitude(showing: item.latitude, span: visibleSpan.latitudeDelta)
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: item.longitude)
            withAnimation(reduceMotion ? nil : .smooth(duration: 0.6)) {
                position = .region(MKCoordinateRegion(center: center, span: visibleSpan))
            }
        }
    }

    private func pin(_ item: MapAnnotationCalloutItem) -> some View {
        let isSelected = item.id == selection

        return VStack(spacing: 6) {
            if isSelected {
                callout(item)
                    .frame(width: calloutWidth, alignment: .leading)
                    .padding(12)
                    .background(.regularMaterial, in: .rect(cornerRadius: 18))
                    .shadow(color: shadow, radius: 10, y: 4)
                    .transition(reduceMotion ? .opacity : .scale(scale: 0.6, anchor: .bottom).combined(with: .opacity))
            }

            Text(item.label)
                .font(.subheadline.weight(.bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .foregroundStyle(isSelected ? Color(.systemBackground) : Color.primary)
                .background(isSelected ? Color.primary : Color(.systemBackground), in: .capsule)
                .shadow(color: shadow, radius: 3, y: 1)
        }
        // Only opening is animated. The annotation shrinks at once when its callout goes, and a
        // callout still fading out would be drawn out of place.
        .animation(isSelected ? (reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: 0.4, bounce: 0.3)) : nil, value: isSelected)
        .accessibilityElement(children: isSelected ? .combine : .ignore)
        .accessibilityLabel("\(item.title), \(item.label)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Demo

struct MapAnnotationCalloutDemo: View {
    private let stays = [
        MapAnnotationCalloutItem(id: "loft", label: "$120", title: "Rooftop Loft", latitude: 38.7139, longitude: -9.1389),
        MapAnnotationCalloutItem(id: "studio", label: "$86", title: "Tiled Studio", latitude: 38.7109, longitude: -9.1422),
        MapAnnotationCalloutItem(id: "house", label: "$210", title: "Garden House", latitude: 38.7163, longitude: -9.1432),
        MapAnnotationCalloutItem(id: "room", label: "$64", title: "Sunny Room", latitude: 38.7118, longitude: -9.1331),
        MapAnnotationCalloutItem(id: "flat", label: "$145", title: "River View Flat", latitude: 38.7083, longitude: -9.1368),
        MapAnnotationCalloutItem(id: "attic", label: "$98", title: "Quiet Attic", latitude: 38.7157, longitude: -9.1338),
    ]

    @State private var selection: String?

    var body: some View {
        MapAnnotationCallout(items: stays, selection: $selection) { stay in
            VStack(alignment: .leading, spacing: 6) {
                LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 84)
                    .overlay {
                        Image(systemName: "house.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .clipShape(.rect(cornerRadius: 10))
                    .accessibilityHidden(true)

                Text(stay.title)
                    .font(.headline)
                Label("4.8 · 2 guests", systemImage: "star.fill")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("\(stay.label) a night")
                    .font(.subheadline.weight(.semibold))
            }
        }
    }
}

#Preview {
    MapAnnotationCalloutDemo()
}
