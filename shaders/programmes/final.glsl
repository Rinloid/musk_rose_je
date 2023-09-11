#if !defined FINAL_GLSL_INCLUDED
#define FINAL_GLSL_INCLUDED

#if defined FINAL_FSH
#	extension GL_ARB_explicit_attrib_location : enable

	uniform sampler2D colortex0, colortex3;

	in vec2 uv;

	/* DRAWBUFFERS:0 */
	layout(location = 0) out vec4 fragData0;

	void main() {
	vec3 albedo = texture(colortex0, uv).rgb;


		/* colortex0 (gcolor) */
		fragData0 = vec4(albedo, 1.0);
	}
#endif /* defined FINAL_FSH */

#if defined FINAL_VSH
	uniform mat4 modelViewMatrix, projectionMatrix;
	in vec2 vaUV0;
	in vec3 vaPosition;

	out vec2 uv;

	void main() {
	uv = vaUV0;

		gl_Position = projectionMatrix * (modelViewMatrix * vec4(vaPosition, 1.0));
	}
#endif /* defined FINAL_VSH */

#endif /* !defined FINAL_GLSL_INCLUDED */