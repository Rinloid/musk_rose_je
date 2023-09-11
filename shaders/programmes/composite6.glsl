#if !defined COMPOSITE6_GLSL_INCLUDED
#define COMPOSITE6_GLSL_INCLUDED

#if defined COMPOSITE6_FSH
#	extension GL_ARB_explicit_attrib_location : enable
	const bool colortex8MipmapEnabled = true;

	uniform sampler2D colortex0, colortex8, colortex11;
	uniform float viewHeight, viewWidth;
	uniform float aspectRatio;

	in vec2 uv;
	in vec3 sunPos;
	in vec3 moonPos;
	in vec3 shadowLightPos;

	/* DRAWBUFFERS:0 */
	layout(location = 0) out vec4 fragData0;

	#define ENABLE_LENS_FLARE
	#define ENABLE_LENS_DIRT

	vec3 getTextureDistorted(const sampler2D tex, const vec2 uv, const vec3 distortion, const vec2 direction, const float lod) {
	return mix(vec3(0.0, 0.0, 0.0), vec3(
		texture(tex, uv + direction * distortion.r, lod).r,
		texture(tex, uv + direction * distortion.g, lod).g,
		texture(tex, uv + direction * distortion.b, lod).b), 1.0);
	}

	vec3 getLensFlare(const sampler2D tex, const vec2 coord, const float viewWidth, const float viewHeight) {
		const int ghosts = 5;
		const float ghostDispersal = 0.4;
		const float lensDistortion = 10.0;

		vec3 result = vec3(0.0, 0.0, 0.0);
		
		vec2 texcoord = -coord + 1.0;
		vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);
	
		vec2 ghostPos = (0.5 - texcoord) * ghostDispersal;
	
		for (int i = 0; i < ghosts; ++i) { 
			vec2 offset = fract(texcoord + ghostPos * float(i));
	
			float weight = length(0.5 - offset) / length(vec2(0.5));
			weight = pow(1.0 - weight, 10.0);

			vec3 distortion = vec3(-texelSize.x * lensDistortion, 0.0, texelSize.x * lensDistortion);
			vec2 direction = normalize(ghostPos);
			
			result += getTextureDistorted(tex, offset, distortion, direction, 3.0) * weight;
		}
		
		return result;
	}

	void main() {
	vec3 albedo = texture(colortex0, uv).rgb;

	#ifdef ENABLE_LENS_FLARE
		vec3 lensFlare = getLensFlare(colortex8, uv, viewWidth, viewHeight)
		#ifdef ENABLE_LENS_DIRT
			 * 0.5 * texture(colortex11, uv).rgb
		#else
			 * 0.15;
		#endif
		;

		albedo *= 1.0 - lensFlare;
		albedo += lensFlare;
	#endif

		/* colortex0 (gcolor) */
		fragData0 = vec4(albedo, 1.0);
	}
#endif /* defined COMPOSITE6_FSH */

#if defined COMPOSITE6_VSH
	uniform mat4 modelViewMatrix, projectionMatrix;
	uniform mat4 gbufferModelView, gbufferModelViewInverse;
	uniform vec3 sunPosition, moonPosition, shadowLightPosition;

	in mat3 normalMatrix;
	in vec2 vaUV0;
	in vec3 vaPosition;
	in vec3 vaNormal;

	out vec2 uv;
	out vec3 sunPos;
	out vec3 moonPos;
	out vec3 shadowLightPos;

	void main() {
	uv = vaUV0;
	sunPos         = normalize(mat3(gbufferModelViewInverse) * sunPosition);
	moonPos        = normalize(mat3(gbufferModelViewInverse) * moonPosition);
	shadowLightPos = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);

		gl_Position = projectionMatrix * (modelViewMatrix * vec4(vaPosition, 1.0));
	}
#endif /* defined COMPOSITE6_VSH */

#endif /* !defined COMPOSITE6_GLSL_INCLUDED */