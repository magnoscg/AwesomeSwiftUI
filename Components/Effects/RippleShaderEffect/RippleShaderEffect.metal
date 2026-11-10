// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Oscar Canton and AwesomeSwiftUI contributors

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

// For SwiftUI's `layerEffect`. Bends the layer where a ring of `radius` points
// around `origin` passes, and lights the crest of that wave. `strength` fades
// the whole wave from 1 to 0, and `bounds` is the frame of the layer.
[[ stitchable ]] half4 RippleShaderEffectDistortion(
    float2 position,
    SwiftUI::Layer layer,
    float4 bounds,
    float2 origin,
    float radius,
    float strength,
    float amplitude,
    float wavelength
) {
    float2 offset = position - origin;
    float fromOrigin = length(offset);
    float2 outward = fromOrigin > 0.0 ? offset / fromOrigin : float2(0.0);

    // How far this pixel is from the crest, in wavelengths. The wave is one
    // crest between two shallow troughs, and the layer is flat everywhere else.
    float phase = (fromOrigin - radius) / wavelength;
    float window = exp(-4.0 * phase * phase) * strength;
    float height = cos(6.2831853 * phase) * window;
    float slope = sin(6.2831853 * phase) * window;

    // Water refracts along its slope. Sampling a little toward the crest
    // magnifies what lies under it, as a ridge of water does. Staying a point
    // inside the layer keeps the wave from pulling in the emptiness around it.
    float2 source = position - outward * slope * amplitude;
    half4 color = layer.sample(clamp(source, bounds.xy + 1.0, bounds.xy + bounds.zw - 1.0));

    // Light the crest and shade the troughs. Colors come premultiplied by their alpha.
    color.rgb = max(color.rgb + half3(0.12 * height) * color.a, half3(0.0));
    return color;
}
