#if defined GBUFFERS_FRAGMENT
uniform sampler2D lightmap;
uniform sampler2D texture;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform float viewWidth, viewHeight;
uniform vec4 entityColor;
uniform vec3 fogColor;
uniform vec3 skyColor;

varying vec2 uv0;
varying vec2 uv1;
varying vec4 col;

float fogify(const float x, const float w) {
	return w / (x * x + w);
}

void main() {
vec4 albedo =
#if defined GBUFFERS_BASIC
    col;
#elif defined GBUFFERS_SKY
    vec4(vec3(0.0), 1.0);
#else
    texture2D(texture, uv0) * col;
#endif
vec2 uvp = gl_FragCoord.xy / vec2(viewWidth, viewHeight);

#if defined GBUFFERS_ENTITIES
    albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);
#endif

#if defined GBUFFERS_SKY
    if (col.a > 0.5) {
        albedo.rgb = col.rgb;
    } else {
        vec4 pos = vec4(uvp * 2.0 - 1.0, 1.0, 1.0);
        pos = gbufferProjectionInverse * pos;
        float upDot = max(0.0, dot(pos.xyz, gbufferModelView[1].xyz));

        albedo.rgb = mix(skyColor, fogColor, fogify(upDot, 0.01));
    }
#endif

    /* DRAWBUFFERS:0
     * 0 = gcolor
     * 1 = gdepth
     * 2 = gnormal
     * 3 = composite
     * 4 = gaux1
     * 5 = gaux2
     * 6 = gaux3
     * 7 = gaux4
    */
	gl_FragData[0] = albedo; // gcolor
}
#elif defined GBUFFERS_VERTEX /* defined GBUFFERS_FRAGMENT */
varying vec2 uv0;
varying vec2 uv1;
varying vec4 col;

void main() {
uv0 = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
uv1 = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
col =
#if defined GBUFFERS_SKY
    vec4(gl_Color.rgb, float(gl_Color.r == gl_Color.g && gl_Color.g == gl_Color.b && gl_Color.r > 0.0));
#else
    gl_Color;
#endif

	gl_Position = ftransform();
}
#endif /* defined GBUFFERS_FRAGMENT */