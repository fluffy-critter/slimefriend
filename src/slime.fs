uniform vec2 size;
uniform vec3 lightDir;
uniform Image densityMap;
uniform vec4 slimeColor; // TODO: color map
uniform vec4 specularColor;

vec3 pos(vec2 tc) {
    return vec3(tc, Texel(densityMap, tc).r*0.5);
}

vec4 effect(vec4 color, Image txt, vec2 tc, vec2 sc) {
    vec4 val = Texel(densityMap, tc);

    vec3 lightDirNrm = normalize(lightDir);

    float density = val.r;
    if (density < 0.1) discard;
    if (density < 0.12) return vec4(0.,0.,0.,1);

    vec2 sx = vec2(0.5/size.x, 0.);
    vec2 sy = vec2(0., 0.5/size.y);

    vec3 nrm = normalize(cross(pos(tc + sx) - pos(tc - sx),
        pos(tc + sy) - pos(tc - sy)));

    vec3 eye = vec3(0., 0., -1.);

    float phong = pow(max(0., dot(reflect(eye, nrm), lightDirNrm)), 10.);

    // vec3 reflected = reflect(eye, nrm);
    float fresnel = pow(length(nrm.xy), 50.0);

    vec4 bgTexel = Texel(txt, tc + refract(eye, nrm, 0.99).xy);
    vec4 bgColor = max(vec4(0.,0.,0.,0.), mix(bgTexel, bgTexel*slimeColor, density*.5 + .5));

    float lambert = max(0., dot(nrm, lightDirNrm));

// return vec4(nrm*.5 + .5, 1.);

    return bgColor + slimeColor*lambert*fresnel + specularColor*phong;
}