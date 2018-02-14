
vec4 effect(vec4 color, Image txt, vec2 tc, vec2 sc) {
    vec4 val = Texel(txt, tc);

    float density = val.r;
    if (density < 0.1) discard;

    vec2 nrm_xy = val.gb;
    vec3 nrm = normalize(vec3(nrm_xy, sqrt(1.0 - dot(nrm_xy, nrm_xy))));

    return color*vec4(nrm*0.5 + vec3(0.5, 0.5, 0.5), 1.0);
}