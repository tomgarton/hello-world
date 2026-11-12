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

// The sheet at a point, if there is paper there.
static bool onSheet(float2 q, float2 size, SwiftUI::Layer layer) {
    if (q.x < 0.0 || q.y < 0.0 || q.x > size.x || q.y > size.y) { return false; }
    return layer.sample(q).a > 0.5;
}

// A corner curling over, the way paper does: it rolls round a cylinder lying on
// the card, comes back over the top, and lies on the sheet face down.
// `pull` is how far, and which way, the corner has been dragged in.
//
// For each point on screen, d is its distance past the roll's axis towards the
// corner. Unrolling the paper tells us which part of the sheet is seen there:
//   0 <= d <= R: the roll itself; the back of the paper on top, else the front underneath.
//   d < 0:       the flap lying face down on the sheet, if it reaches; else the sheet,
//                with a soft shadow near the roll.
//   d > R:       nothing; that paper has rolled away.
[[ stitchable ]] half4 paperCurl(float2 position, SwiftUI::Layer layer, float2 size, float2 corner, float2 pull, half4 back) {
    float len = length(pull);
    if (len < 0.5) { return layer.sample(position); }
    float2 n = -pull / len;                       // towards the corner
    float2 axis = corner + pull;                  // a point on the roll's axis
    float d = dot(position - axis, n);
    float R = clamp(len * 0.3, 6.0, 26.0);        // the roll grows as it is pulled
    float2 foot = position - n * d;               // straight down onto the axis
    float pi = 3.14159265;

    if (d > R) { return half4(0.0); }

    if (d >= 0.0) {
        float a = asin(clamp(d / R, 0.0, 1.0));   // 0 at the axis, pi/2 at the top of the roll
        float2 backPoint = foot + n * (pi * R - a * R);
        if (onSheet(backPoint, size, layer)) {
            // The back of the paper on the roll: lit along its top, darker as it turns away.
            float light = 0.74 + 0.2 * sin(a) + 0.14 * pow(sin(a), 10.0);
            return half4(back.rgb * half(light), 1.0);
        }
        float2 frontPoint = foot + n * (a * R);
        if (onSheet(frontPoint, size, layer)) {
            // The front, curving up and away from the light.
            half4 colour = layer.sample(frontPoint);
            colour.rgb *= half(1.0 - 0.4 * (a / (pi * 0.5)));
            return colour;
        }
        return half4(0.0);
    }

    float2 flapPoint = foot + n * (pi * R - d);
    if (onSheet(flapPoint, size, layer)) {
        // The flap lying face down: plain paper, a little darker close to the roll.
        float shade = 0.95 - 0.2 * exp(d / (R * 0.7));
        return half4(back.rgb * half(shade), 1.0);
    }
    // The sheet, with the roll's shadow falling across it.
    half4 colour = layer.sample(position);
    colour.rgb *= half(1.0 - 0.34 * exp(d / (R * 0.9)));
    return colour;
}
