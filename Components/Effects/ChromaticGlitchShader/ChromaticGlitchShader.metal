// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and SwiftUI Blocks contributors

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

// The color of the view at a point, or nothing outside it. Without this a band
// that moves past an edge would drag the last color of the view along with it.
static half4 ChromaticGlitchShaderSample(SwiftUI::Layer layer, float2 point, float2 bounds) {
    if (point.x < 0.0 || point.y < 0.0 || point.x > bounds.x || point.y > bounds.y) {
        return half4(0.0);
    }
    return layer.sample(point);
}

// For SwiftUI's `layerEffect`. Splits the view into its red, green and blue,
// each a little to one side, shifts some horizontal bands sideways and draws
// faint scan lines over it. `amount` goes from 0, which leaves the view as it
// is, to 1. `time` picks which bands are shifted, and they change `rate` times
// a second. `split` and `shift` are the farthest a channel and a band move, in
// points, and `bounds` is the size of the view.
[[ stitchable ]] half4 ChromaticGlitchShaderSplit(
    float2 position,
    SwiftUI::Layer layer,
    float amount,
    float time,
    float split,
    float shift,
    float2 bounds
) {
    if (amount <= 0.0) {
        return layer.sample(position);
    }

    float rate = 10.0;
    float band = floor(position.y / 22.0);
    float noise = fract(sin(band * 91.7 + floor(time * rate) * 37.3) * 43758.5453);
    float moved = noise > 0.7 ? (noise - 0.7) / 0.3 : 0.0;

    float direction = noise > 0.85 ? -1.0 : 1.0;

    float2 point = float2(position.x + moved * direction * shift * amount, position.y);
    float2 offset = float2(split * amount, 0.0);

    half4 red = ChromaticGlitchShaderSample(layer, point + offset, bounds);
    half4 green = ChromaticGlitchShaderSample(layer, point, bounds);
    half4 blue = ChromaticGlitchShaderSample(layer, point - offset, bounds);
    half4 color = half4(red.r, green.g, blue.b, max(max(red.a, green.a), blue.a));

    float lines = 1.0 - 0.14 * amount * step(0.5, fract(position.y / 3.0));
    color.rgb *= half(lines);
    return color;
}
