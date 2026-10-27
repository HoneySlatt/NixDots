// hyprquickshot's dimming: the selection stays clear, a white outline around it, the rest dimmed
// values[0] = selection (x, y, width, height), values[1] = (dim opacity, corner radius, outline thickness, 0)

float sdRoundedBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + vec2(r);
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
    vec4 selection = values[0];
    vec2 halfSize = selection.zw / 2.0;
    vec2 center = selection.xy + halfSize;
    float dist = sdRoundedBox(uv * size - center, halfSize, values[1].y);

    if (dist <= 0.0) {
        color = vec4(0.0);
    } else if (dist <= values[1].z) {
        color = vec4(1.0);
    } else {
        color = vec4(0.0, 0.0, 0.0, values[1].x);
    }
}
