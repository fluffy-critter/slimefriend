uniform vec2 size;

vec4 effect(vec4 color, Image txt, vec2 tc, vec2 sc) {
    float density = Texel(txt, tc).r;
    if (density < 0.2) discard;

    vec2 sx = vec2(0.5, 0.0)/size;
    vec2 sy = vec2(0.0, 0.5)/size;
    float gx = Texel(txt, tc - sx).g - Texel(txt, tc + sx).g;
    float gy = Texel(txt, tc - sy).g - Texel(txt, tc + sy).g;

    vec3 nrm = normalize(vec3(gx, gy, 1.0/64.0));

    return color*vec4(nrm*0.5 + vec3(0.5, 0.5, 0.5), 1.0);
}