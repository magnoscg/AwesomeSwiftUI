// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

// For SwiftUI's `layerEffect`. Draws the view in square blocks of `size`
// points, each one in the color of the point at its center. A block that
// sticks out of the view, which is `bounds` in size, takes the color of the
// last point inside, so the edges are not cut. A size of one point or less
// leaves the view as it is.
[[ stitchable ]] half4 PixelateShaderEffectBlocks(
    float2 position,
    SwiftUI::Layer layer,
    float size,
    float2 bounds
) {
    if (size <= 1.0) {
        return layer.sample(position);
    }
    float2 center = (floor(position / size) + 0.5) * size;
    return layer.sample(min(center, bounds - 0.5));
}
