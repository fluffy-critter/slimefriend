vec4 effect(vec4 color, Image txt, vec2 tc, vec2 sc) {
    vec2 pos = (tc - vec2(0.5,0.5))*2.0;
    float mag = length(pos);
    float density = smoothstep(0.0, 1.0, max(0.0, 1.0 - mag));

    return vec4(density, density, density, density);
}
