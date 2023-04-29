#if !defined SHADOW_GLSL_INCLUDED
#define SHADOW_GLSL_INCLUDED

#if defined SHADOW_FSH
#	extension GL_ARB_explicit_attrib_location : enable

	uniform sampler2D gtexture;
	uniform float frameTimeCounter;
	uniform float alphaTestRef;

	in vec2 uv0;
	in vec4 col;
	in vec3 fragPos;
	in float mcEntity;

	/* DRAWBUFFERS:0 */
	layout(location = 0) out vec4 fragData0;

	#include "/utils/musk_rose_water.glsl"

	void main() {
	vec4 albedo = texture(gtexture, uv0) * col;
	if (albedo.a < alphaTestRef) discard;

	if (int(mcEntity) == 1) {
		float causticFactor = getWaterWavesCaustic(fragPos.xz, frameTimeCounter) * 1.4;

		albedo = mix(vec4(0.0, 0.02, 0.03, 1.0), vec4(1.0), 1.0 - clamp(causticFactor, 0.0, 1.0));
	}

		/* colortex0 (gcolor) */
		fragData0 = albedo;
	}
#endif /* defined SHADOW_FSH */

#if defined SHADOW_VSH
	uniform mat4 modelViewMatrix;
	uniform mat4 projectionMatrix;
	uniform mat4 shadowProjection, shadowProjectionInverse;
	uniform mat4 shadowModelView, shadowModelViewInverse;
	uniform mat4 gbufferModelViewInverse;
	// Set a default value when the uniform is not bound.
	uniform mat4 textureMatrix = mat4(1.0);
	uniform vec3 chunkOffset;
	uniform vec3 cameraPosition;

	in vec2 vaUV0;
	in vec4 vaColor;
	in vec3 vaPosition;
	in vec3 mc_Entity;

	out vec2 uv0;
	out vec4 col;
	out vec3 fragPos;
	out float mcEntity;

	#include "/utils/musk_rose_shadow.glsl"

	void main() {
	uv0 = (textureMatrix * vec4(vaUV0, 0.0, 1.0)).xy;
	col = vaColor;
	mcEntity = 0.1;
	if (int(mc_Entity.x) == 10001) mcEntity = 1.1; // Water

	vec4 worldPos = vec4(vaPosition, 1.0);
	worldPos.xyz += chunkOffset;

	fragPos = (shadowModelViewInverse * (shadowProjectionInverse * projectionMatrix * (modelViewMatrix * vec4(vaPosition + chunkOffset, 1.0)))).xyz + cameraPosition + gbufferModelViewInverse[3].xyz;

		gl_Position = projectionMatrix * (modelViewMatrix * vec4(vaPosition + chunkOffset, 1.0));
		gl_Position.xyz = distort(gl_Position.xyz);
	}
#endif /* defined SHADOW_VSH */

#endif /* !defined SHADOW_GLSL_INCLUDED */