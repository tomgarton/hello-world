#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// A ring running out through the paper from where a stamp landed.
[[ stitchable ]] float2 paperRipple(float2 position, float2 origin, float time) {
    float2 d = position - origin;
    float dist = length(d);
    if (dist < 0.001 || time <= 0.0) { return position; }
    float front = time * 380.0;
    float delta = dist - front;
    float envelope = exp(-4.5 * time) * smoothstep(70.0, 0.0, abs(delta));
    float wave = sin(delta / 44.0 * 6.2832) * 8.0 * envelope;
    return position + (d / dist) * wave;
}

// A corner folded over: `pull` is how far the corner has been dragged in.
// Beyond the fold the sheet is gone; the flap shows the back of the paper.
[[ stitchable ]] half4 paperCurl(float2 position, SwiftUI::Layer layer, float2 size, float2 corner, float2 pull, half4 back) {
    float len = length(pull);
    if (len < 0.5) { return layer.sample(position); }
    float2 moved = corner + pull;
    float2 mid = (corner + moved) * 0.5;
    float2 n = normalize(corner - moved);
    float d = dot(position - mid, n);
    if (d > 0.0) { return half4(0.0); }
    float2 mirror = position - 2.0 * d * n;
    bool inside = mirror.x >= 0.0 && mirror.y >= 0.0 && mirror.x <= size.x && mirror.y <= size.y;
    if (inside && layer.sample(mirror).a > 0.5) {
        // The flap: lighter towards its free edge, darker in the crease.
        float shade = 0.78 + 0.22 * smoothstep(0.0, len * 0.5, -d);
        return half4(back.rgb * half(shade), 1.0);
    }
    half4 colour = layer.sample(position);
    // A soft shadow the flap casts on the sheet beside it.
    float2 beyond = position - 2.0 * (d + 7.0) * n;
    bool near = beyond.x >= 0.0 && beyond.y >= 0.0 && beyond.x <= size.x && beyond.y <= size.y;
    if (near) { colour.rgb *= half(0.82); }
    return colour;
}
