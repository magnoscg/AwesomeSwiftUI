// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and Awesome SwiftUI Components contributors

import Charts
import Spatial
import SwiftUI

@available(iOS 26, *)
enum Surface3DChartPreset: String, CaseIterable, Identifiable {
    case angled = "Angled"
    case front = "Front"
    case top = "Top"
    case side = "Side"

    var id: Self { self }

    var pose: Chart3DPose {
        switch self {
        case .angled: Chart3DPose(azimuth: .degrees(35), inclination: .degrees(25))
        case .front: .front
        case .top: .top
        case .side: .right
        }
    }
}

/// A 3D surface plot that rotates when dragged, with buttons for preset viewing angles.
///
/// With Reduce Motion on, the presets jump to their angle.
@available(iOS 26, *)
struct Surface3DChart: View {
    var domain: ClosedRange<Double> = -3...3
    var gradient = Gradient(colors: [.indigo, .purple, .pink, .orange])
    let function: @Sendable (Double, Double) -> Double

    @State private var pose = Surface3DChartPreset.angled.pose
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var safeDomain: ClosedRange<Double> {
        domain.lowerBound < domain.upperBound ? domain : -1...1
    }

    private var currentPreset: Surface3DChartPreset? {
        Surface3DChartPreset.allCases.first { $0.pose == pose }
    }

    var body: some View {
        let function = self.function

        VStack(spacing: 20) {
            Chart3D {
                SurfacePlot(x: "X", y: "Height", z: "Z") { x, z in
                    let height = function(x, z)
                    return height.isFinite ? height : 0
                }
                .foregroundStyle(.heightBased(gradient))
                .roughness(0.35)
            }
            .chartXScale(domain: safeDomain)
            .chartZScale(domain: safeDomain)
            .chart3DPose($pose)
            // The chart sizes its plot for the longer side of its frame. In a tall frame that
            // is wider than the view, which cuts the corners and the axis labels.
            .aspectRatio(1, contentMode: .fit)
            .accessibilityLabel("3D surface plot")
            .accessibilityValue(currentPreset.map { "\($0.rawValue) view" } ?? "Custom view")
            .accessibilityHint("Use the view buttons to change the angle")

            ViewThatFits(in: .horizontal) {
                presetRow
                ScrollView(.horizontal) { presetRow }.scrollIndicators(.hidden)
            }
        }
    }

    private var presetRow: some View {
        HStack(spacing: 8) {
            ForEach(Surface3DChartPreset.allCases) { preset in
                Button {
                    withAnimation(reduceMotion ? nil : .smooth(duration: 0.6)) { pose = preset.pose }
                } label: {
                    Text(preset.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .frame(minHeight: 44)
                        .foregroundStyle(preset == currentPreset ? Color.white : Color.primary)
                        .background(preset == currentPreset ? AnyShapeStyle(.indigo) : AnyShapeStyle(.thinMaterial), in: .capsule)
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(preset == currentPreset ? .isSelected : [])
            }
        }
    }
}

// MARK: - Demo

@available(iOS 26, *)
struct Surface3DChartDemo: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ripple")
                .font(.largeTitle.bold())
            Text("Drag to rotate, or pick a view")
                .font(.title3)
                .foregroundStyle(.secondary)

            Surface3DChart { x, z in
                let radius = (x * x + z * z).squareRoot()
                return sin(radius * 2.2) * exp(-radius * 0.28)
            }
            .padding(.top, 16)
        }
        .padding(24)
    }
}

@available(iOS 26, *)
#Preview {
    Surface3DChartDemo()
}
