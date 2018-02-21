uniform vec2 size;
uniform vec3 lightDir;
uniform Image densityMap;
uniform Image slimeColor;
uniform Image background;
uniform Image foreground;
uniform vec4 specularColor;

vec3 pos(vec2 tc) {
    return vec3(tc, Texel(densityMap, tc).r*0.5);
}

vec4 effect(vec4 color, Image txt, vec2 tc, vec2 sc) {
    vec3 lightDirNrm = normalize(lightDir);

    vec4 slimeVal = Texel(densityMap, tc);
    float density = slimeVal.r;
    if (density < 0.1) discard;
    if (density < 0.11) return vec4(0.,0.,0.,1);

    vec4 localColor = Texel(slimeColor, tc)/slimeVal.g;
    localColor.a = 1.;

    vec2 sx = vec2(0.5/size.x, 0.);
    vec2 sy = vec2(0., 0.5/size.y);

    vec3 nrm = normalize(cross(pos(tc + sx) - pos(tc - sx),
        pos(tc + sy) - pos(tc - sy)));

    vec3 eye = vec3(0., 0., -1.);

    vec3 reflected = reflect(lightDirNrm, nrm);
    float phong = pow(max(0., dot(reflected, eye)), 5.);

    float fresnel = pow(length(nrm.xy), 50.0);

    vec2 aspect = vec2(1.0, size.x/size.y);

    vec4 bgTexel = Texel(background, tc + refract(eye, nrm, 0.99).xy*aspect);
    vec4 bgColor = max(vec4(0.,0.,0.,0.), mix(bgTexel, bgTexel*localColor, density*.5 + .5));

    vec4 reflection = Texel(foreground, tc + reflect(eye, nrm).xy*aspect);

    float lambert = max(0., dot(nrm, lightDirNrm));

    return bgColor + localColor*lambert*(fresnel + 0.1) + specularColor*phong + reflection*fresnel*specularColor*0.3;
}
