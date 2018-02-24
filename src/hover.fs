vec4 effect(vec4 color, Image txt, vec2 tc, vec2 sc) {
    return vec4(color.rgb, color.a*Texel(txt,tc).a);
}
