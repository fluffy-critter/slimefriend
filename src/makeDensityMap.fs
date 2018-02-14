vec4 effect(vec4 color, Image txt, vec2 tc, vec2 sc) {
    vec2 pos = (tc - vec2(0.5,0.5))*2.0;
    float mag = length(pos);

    vec4 map;
    // density
    map.r = smoothstep(0.0, 1.0, max(0.0, 1.0 - mag));
    // shape
    map.g = sqrt(max(0.0, 1.0 - mag*mag));

    map.b = 0;
    map.a = 1;

    return map;
}