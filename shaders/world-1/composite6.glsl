#include "../programmes/musk_rose_config.glsl"

#if !defined COMPOSITE6_GLSL_INCLUDED
#define COMPOSITE6_GLSL_INCLUDED

#include "../programmes/uniforms/uniform_for_all.glsl"
#include "../programmes/uniforms/uniform_composite.glsl"

#if defined COMPOSITE6_FSH
#extension GL_ARB_explicit_attrib_location : enable
const bool colortex0MipmapEnabled = true;

in vec2 uv;
in vec3 nomal_;

#include "../programmes/musk_rose_position.glsl"

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 fragData0;

void main() {
vec4 translucent = texture(colortex3, uv);
vec3 vNormal = texture(colortex1, uv).rgb * 2.0 - 1.0;
vec3 fNormal = texture(colortex2, uv).rgb * 2.0 - 1.0;
vec3 albedo = texture(colortex0, uv).rgb;

vec3 viewPos0 = getViewPos(depthtex0, uv).xyz;
vec3 viewPos1 = getViewPos(depthtex1, uv).xyz;
vec3 viewPos2 = getViewPos(depthtex2, uv).xyz;

vec3 refraction = albedo;
if (translucent.a > 0.0) {
	vec3 refNormal = mat3(gbufferModelView) * fNormal - vNormal;
	vec2 refUV = getScreenPos(refract(normalize(viewPos0), refNormal, 0.0) + viewPos0).xy;
	refraction = texture(colortex0, refUV, TRANSLUCENT_BLUR_INTENSITY * translucent.a).rgb;
}

albedo = mix(refraction, translucent.rgb, translucent.a);

	/* colortex0 (gcolor) */
	fragData0 = vec4(albedo, 1.0);
} /* main */
#endif /* defined COMPOSITE6_FSH */

#if defined COMPOSITE6_VSH
#include "../programmes/attributes/attribute_for_all.glsl"

out vec2 uv;
out vec3 normal_;

void main() {
uv = vaUV0;
normal_ = normalize(normalMatrix * vaNormal);

	gl_Position = projectionMatrix * (modelViewMatrix * vec4(vaPosition, 1.0));
} /* main */
#endif /* defined COMPOSITE6_VSH */

#endif /* !defined COMPOSITE6_GLSL_INCLUDED */