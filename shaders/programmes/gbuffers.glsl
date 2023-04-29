#if !defined GBUFFERS_GLSL_INCLUDED
#define GBUFFERS_GLSL_INCLUDED 1

#if defined GBUFFERS_WATER || defined GBUFFERS_HAND_WATER
#	define GBUFFERS_TRANSLUCENT 1
#endif

#if defined GBUFFERS_ARMOR_GLINT || defined GBUFFERS_BEACONBEAM || defined GBUFFERS_BLOCK || defined GBUFFERS_CLOUDS || defined GBUFFERS_ENTITIES || defined GBUFFERS_HAND_WATER || defined GBUFFERS_HAND || defined GBUFFERS_SKYTEXTURED || defined GBUFFERS_SPIDEREYES || defined GBUFFERS_TERRAIN || defined GBUFFERS_TEXTURED_LIT || defined GBUFFERS_TEXTURED || defined GBUFFERS_WATER || defined GBUFFERS_WEATHER
#	define USE_TEXTURES 1
#endif

#if defined GBUFFERS_BASIC || defined GBUFFERS_BLOCK || defined GBUFFERS_ENTITIES || GBUFFERS_HAND_WATER || defined GBUFFERS_HAND || defined GBUFFERS_TERRAIN || defined GBUFFERS_TEXTURED_LIT || defined GBUFFERS_TEXTURED || defined GBUFFERS_WATER || defined GBUFFERS_WEATHER
#   define USE_LIGHTMAP 1
#endif

#if defined GBUFFERS_TERRAIN || defined GBUFFERS_WATER
#	define USE_CHUNK_OFFSET 1
#endif

#if defined GBUFFERS_BASIC || defined GBUFFERS_BEACONBEAM || defined GBUFFERS_BLOCK || defined GBUFFERS_CLOUDS || defined GBUFFERS_ENTITIES || defined GBUFFERS_HAND_WATER || defined GBUFFERS_HAND || defined GBUFFERS_LINE || defined GBUFFERS_SPIDEREYES || defined GBUFFERS_TERRAIN || defined GBUFFERS_TEXTURED_LIT || defined GBUFFERS_TEXTURED || defined GBUFFERS_WATER || defined GBUFFERS_WEATHER
#	define USE_ALPHA_TEST 1
#endif

#if defined GBUFFERS_FSH
#	extension GL_ARB_explicit_attrib_location : enable

#	if defined USE_TEXTURES
		uniform sampler2D gtexture;
		uniform sampler2D normals;
		uniform sampler2D specular;
#	endif
#	if defined USE_ALPHA_TEST
		uniform float alphaTestRef;
#	endif
#	if defined GBUFFERS_ENTITIES
		uniform vec4 entityColor;
#	endif
	uniform sampler2D depthtex0;
	uniform sampler2D depthtex1;
	uniform sampler2D shadowtex0;
	uniform sampler2D shadowtex1;
	uniform sampler2D shadowcolor0;
	uniform mat4 gbufferProjection, gbufferProjectionInverse;
	uniform mat4 gbufferModelView, gbufferModelViewInverse;
	uniform mat4 shadowProjection, shadowModelView;
	uniform vec3 cameraPosition;
	uniform vec3 skyColor, fogColor;
	uniform float frameTimeCounter;
	uniform float rainStrength;
	uniform float viewWidth, viewHeight;
	uniform float far, near;
	uniform float fogStart, fogEnd;
	uniform float aspectRatio;

#	if defined USE_TEXTURES
		in vec2 uv0;
#	endif
#	if defined USE_LIGHTMAP
		in vec2 uv1;
#	endif
	in vec4 col;
	in float mcEntity;
	in vec3 viewPos;
	in vec3 relPos;
	in vec3 fragPos;
	in vec3 vNormal;
	in mat3 tbnMatrix;
	in vec3 sunPos;
	in vec3 moonPos;
	in vec3 shadowLightPos;

	/* DRAWBUFFERS:023456 */
	layout(location = 0) out vec4 fragData0;
	layout(location = 1) out vec4 fragData1;
	layout(location = 2) out vec4 fragData2;
	layout(location = 3) out vec4 fragData3;
	layout(location = 4) out vec4 fragData4;
	layout(location = 5) out vec4 fragData5;

	#include "/utils/musk_rose_config.glsl"
	#include "/utils/musk_rose_water.glsl"
	#include "/utils/musk_rose_light.glsl"
	#include "/utils/musk_rose_fog.glsl"

	vec4 getViewPos(const mat4 projInv, const vec2 uv, const float depth) {
		vec4 viewPos = projInv * vec4(vec3(uv, depth) * 2.0 - 1.0, 1.0);

		return viewPos / viewPos.w;
	}

	vec4 getRelPos(const mat4 modelViewInv, const mat4 projInv, const vec2 uv, const float depth) {
		vec4 relPos = modelViewInv * getViewPos(projInv, uv, depth);
		
		return relPos / relPos.w;
	}

	const int shadowMapResolution = 2048; // [512 1024 2048 4096]
	const float shadowDistance = 512.0;
	const float sunPathRotation = -40.0;

	#include "/utils/musk_rose_shadow.glsl"

	vec4 getShadowPos(const mat4 shadowModelView, const mat4 shadowProj, const vec3 relPos, const float diffuse) {
		const float shadowBias = 0.02;

		vec4 shadowPos = vec4(relPos, 1.0);
		shadowPos = shadowProj * (shadowModelView * shadowPos);

		float distortFactor = getDistortFactor(shadowPos.xy);
		shadowPos.xyz = distort(shadowPos.xyz, distortFactor);
		shadowPos.xyz = shadowPos.xyz * 0.5 + 0.5;
		
		shadowPos.z -= shadowBias * (distortFactor * distortFactor) / abs(diffuse);

		return shadowPos;
	}

	/* 
	** ACES filmic tone mapping
	** https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
	*/
	vec3 acesFilmicToneMap(const vec3 col) {
		const float a = 2.51;
		const float b = 0.03;
		const float c = 2.43;
		const float d = 0.59;
		const float e = 0.14;

		return clamp((col * (a * col + b)) / (col * (c * col + d) + e), 0.0, 1.0);
	}

	vec3 contrastFilter(const vec3 col, const float contrast) {
		return (col - 0.5) * max(contrast, 0.0) + 0.5;
	}

	/* 
	** Uncharted 2 tone mapping
	** See: http://filmicworlds.com/blog/filmic-tonemapping-operators/
	*/
	vec3 uncharted2ToneMapFilter(const vec3 col) {
		const float A = 0.015; // Shoulder strength
		const float B = 0.500; // Linear strength
		const float C = 0.100; // Linear angle
		const float D = 0.010; // Toe strength
		const float E = 0.020; // Toe numerator
		const float F = 0.300; // Toe denominator

		return ((col * (A * col + C * B) + D * E) / (col * (A * col + B) + D * F)) - E / F;
	}
	vec3 uncharted2ToneMap(const vec3 col) {
		const float W = 112.0;

		vec3 curr = uncharted2ToneMapFilter(col);
		vec3 whiteScale = 1.0 / uncharted2ToneMapFilter(vec3(W));
		vec3 color = curr * whiteScale;

		return color;
	}

#	define GAMMA 2.2 // [1.8 2.0 2.1 2.2 2.4 2.6 2.8]

	void main() {
	float vanillaAO = 0.0;
	vec3 bloom = vec3(0.0);
#	if defined USE_TEXTURES
		vec4 albedo = texture(gtexture, uv0);
#		if defined GBUFFERS_TERRAIN || defined GBUFFERS_WATER
			if (abs(col.r - col.g) > 0.001 || abs(col.g - col.b) > 0.001) albedo *= vec4(normalize(col.rgb), col.a);
			vanillaAO = 1.0 - (col.g * 2.0 - (col.r < col.b ? col.r : col.b));
#		else
			albedo *= col;
#		endif
#	else
		vec4 albedo = col;
#	endif

	vec4 translucent = vec4(0.0);
	vec2 uv = gl_FragCoord.xy / vec2(viewWidth, viewHeight);

#	if defined USE_ALPHA_TEST
		if (albedo.a < alphaTestRef) discard;
#	endif
#	if defined GBUFFERS_ENTITIES
		albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);
#	endif

	float depth0 = texture(depthtex0, uv).r;
	float depth1 = texture(depthtex1, uv).r;
	vec3 fNormal = vNormal;
#	if defined USE_TEXTURES && defined MC_NORMAL_MAP
		fNormal = vec3(texture2D(normals, uv0).rg * 2.0 - 1.0, sqrt(1.0 - dot(texture2D(normals, uv0).rg * 2.0 - 1.0, texture2D(normals, uv0).rg * 2.0 - 1.0)));
		fNormal = normalize(fNormal * tbnMatrix);
#	endif
	if (int(mcEntity) == 1) fNormal = normalize(getWaterWaveNormal(getWaterParallax(viewPos, fragPos.xz, frameTimeCounter), frameTimeCounter) * tbnMatrix);
	fNormal = mat3(gbufferModelViewInverse) * fNormal;

	float perceptualSmoothness = 1.0;
	float roughness = 0.0;
	float reflectance = 0.0;

#	if defined USE_TEXTURES && defined MC_SPECULAR_MAP
		perceptualSmoothness = texture(specular, uv0).r;
		roughness = (1.0 - perceptualSmoothness) * (1.0 - perceptualSmoothness);
		reflectance = texture(specular, uv0).g;
#	endif

	if (int(mcEntity) == 1) {
		albedo = vec4(0.0, 0.02, 0.03, 0.1);
		perceptualSmoothness = 0.9;
		roughness = 0.01;
		reflectance = 0.9;
	}

#	if defined GBUFFERS_TRANSLUCENT
		translucent = albedo;
		albedo.a = 0.0;
#	endif

	float daylight = max(0.0, sin(sunPos.y));
	float rainLevel = rainStrength;
	vec3 vanillaSky = mix(skyColor, fogColor, smoothstep(0.8, 1.0, 1.0 - normalize(relPos.y)));

#	if defined USE_LIGHTMAP
		if (depth0 != 0.0) {
			float diffuse = max(0.0, dot(shadowLightPos, fNormal));
			vec4 shadowPos = getShadowPos(shadowModelView, shadowProjection, relPos, diffuse);
			vec4 shadows = vec4(0.0);

			if (shadowPos.w > 0.0) {
				for (int i = 0; i < int(shadowSamples.length()); i++) {
					vec2 offset = shadowSamples[i] / float(shadowMapResolution) + hash12(floor(gl_FragCoord.xy * 2048.0)) * 0.0002;
					
					if (texture2D(shadowtex1, shadowPos.xy + offset).r < shadowPos.z) {
						shadows += vec4(vec3(0.0), 1.0);
					} else if (texture2D(shadowtex0, shadowPos.xy + offset).r < shadowPos.z){
						shadows += vec4(texture2D(shadowcolor0, shadowPos.xy + offset).rgb, 1.0);
					}
				} shadows /= shadowSamples.length();
			}
			
			float indoor = mix(0.0, 1.0, uv1.y);
			float torchLevel = uv1.x * uv1.x * uv1.x * uv1.x * uv1.x;
			float shadowLightLevel = mix(0.0, mix(0.0, 1.0 - shadows.a, diffuse), uv1.y);
			shadows.a = mix(1.0, shadows.a, diffuse);
			vanillaAO *= vanillaAO * vanillaAO;

			albedo.rgb = pow(albedo.rgb, vec3(GAMMA));

			vec3 totalLight = getTotalLight(albedo, shadows, vec3(0.4, 0.65, 1.0), skyColor, fogColor,
							  relPos, shadowLightPos, fNormal,
							  torchLevel, indoor, shadowLightLevel, daylight, rainLevel,
							  0.0, vanillaAO, roughness, reflectance,
							  bloom);

			albedo.rgb = totalLight;
			albedo.rgb = uncharted2ToneMap(albedo.rgb);
			albedo.rgb = pow(albedo.rgb, vec3(1.0 / GAMMA));
			albedo.rgb = contrastFilter(albedo.rgb, 1.85);

#			if defined GBUFFERS_TRANSLUCENT
				translucent.a = clamp(translucent.a + getLuma(bloom.rgb), 0.0, 1.0);
#			endif
		}
#	endif

#	if defined GBUFFERS_CLOUDS || defined GBUFFERS_SKYTEXTURED
		#ifdef ENABLE_SHADER_SKY
			discard;
		#endif
#	endif

#	if defined GBUFFERS_SKYBASIC
		#ifndef ENABLE_SHADER_SKY
			albedo.rgb = mix(albedo.rgb, fogColor, clamp((length(relPos.xyz) - fogStart) / (fogEnd - fogStart), 0.0, 1.0));
		#endif
#	endif

//#	define ENABLE_RAINBOW_SELECTION_OUTLINE
#	if defined GBUFFERS_LINE && defined ENABLE_RAINBOW_SELECTION_OUTLINE
		if (albedo.a < 0.9) albedo = vec4(vec3(0.5 + cos(fragPos * 2.0 + frameTimeCounter * 2.0 + vec3(0.0, 2.0, 4.0)) * 0.5), 1.0);
#	endif

#	if defined GBUFFERS_TRANSLUCENT
		translucent.rgb = albedo.rgb;
#	endif

		/* colortex0 (gcolor) */
		fragData0 = albedo;

		/* colortex2 (gnormal) */
		fragData1 = vec4((fNormal + 1.0) * 0.5, 1.0);

		/* colortex3 (composite) */
		fragData2 = translucent;

		/* colortex4 (gaux1) */
#		if defined USE_LIGHTMAP
#			if defined USE_TEXTURES
				fragData3 = vec4(uv1.y, reflectance, roughness, 1.0);
#			else
				fragData3 = vec4(uv1.y, vec2(0.0), 1.0);
#			endif
#		else
#			if defined USE_TEXTURES
				fragData3 = vec4(0.0, reflectance, roughness, 1.0);
#			else
				fragData3 = vec4(0.0, vec2(0.0), 1.0);
#			endif
#		endif

		/* colortex5 (gaux2) */
		fragData4 = vec4(bloom, 1.0);

		/* colortex6 (gaux3) */
		fragData5 = vec4(int(mcEntity) * 0.1, 0.0, 0.0, 1.0);
	}
#endif /* defined GBUFFERS_FSH */

#if defined GBUFFERS_VSH
#	if defined GBUFFERS_LINE
		const float LINE_WIDTH  = 2.0;
		const float VIEW_SHRINK = 0.9609375 /* 1.0 - (1.0 / 256.0) */ ;
		const mat4 VIEW_SCALE   = mat4(
			VIEW_SHRINK, 0.0, 0.0, 0.0,
			0.0, VIEW_SHRINK, 0.0, 0.0,
			0.0, 0.0, VIEW_SHRINK, 0.0,
			0.0, 0.0, 0.0, 1.0
		);
		
		uniform float viewHeight, viewWidth;
#	endif
	uniform mat4 modelViewMatrix;
	uniform mat4 projectionMatrix;
	uniform mat3 normalMatrix;
#	if defined USE_TEXTURES
		// Set a default value when the uniform is not bound.
		uniform mat4 textureMatrix = mat4(1.0);
#	endif
#	if defined USE_CHUNK_OFFSET
		uniform vec3 chunkOffset;
#	endif
	uniform mat4 gbufferModelView, gbufferModelViewInverse;
	uniform vec3 cameraPosition;
	uniform vec3 sunPosition, moonPosition, shadowLightPosition;

#	if defined USE_TEXTURES
		in vec2 vaUV0;
#	endif
#	if defined USE_LIGHTMAP
		in ivec2 vaUV2;
#	endif
	in vec3 vaNormal;
	in vec3 vaPosition;
	in vec4 vaColor;
	in vec3 mc_Entity;
	in vec4 at_tangent;

#	if defined USE_TEXTURES
		out vec2 uv0;
#	endif
#	if defined USE_LIGHTMAP
		out vec2 uv1;
#	endif
	out vec4 col;
	out float mcEntity;
	out vec3 viewPos;
	out vec3 relPos;
	out vec3 fragPos;
	out vec3 vNormal;
	out mat3 tbnMatrix;
	out vec3 sunPos;
	out vec3 moonPos;
	out vec3 shadowLightPos;

	void main() {
#	if defined USE_TEXTURES
		uv0 = (textureMatrix * vec4(vaUV0, 0.0, 1.0)).xy;
#	endif
#	if defined USE_LIGHTMAP
		uv1 = vaUV2 * 0.00390625 /* (1.0 / 256.0) */ + 0.03125 /* (1.0 / 32.0) */ ;
#	endif
	col = vaColor;
	mcEntity = 0.1;
	if (int(mc_Entity.x) == 10001) mcEntity = 1.1; // Water

	vec4 worldPos = vec4(vaPosition, 1.0);
#	if defined USE_CHUNK_OFFSET
		worldPos.xyz += chunkOffset;
#	endif

	viewPos = viewPos = (modelViewMatrix * worldPos).xyz;
	relPos  = worldPos.xyz;
	fragPos = relPos + cameraPosition;

	vec3 tangent  = normalize(normalMatrix * at_tangent.xyz);
	vec3 binormal = normalize(normalMatrix * cross(at_tangent.xyz, vaNormal) * at_tangent.w);
	
	vNormal    = normalize(normalMatrix * vaNormal);
	tbnMatrix  = transpose(mat3(tangent, binormal, vNormal));

	sunPos         = normalize(mat3(gbufferModelViewInverse) * sunPosition);
	moonPos        = normalize(mat3(gbufferModelViewInverse) * moonPosition);
	shadowLightPos = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);

#		if defined GBUFFERS_LINE
			vec2 resolution   = vec2(viewWidth, viewHeight);
			vec4 linePosStart = projectionMatrix * (VIEW_SCALE * (modelViewMatrix * vec4(vaPosition, 1.0)));
			vec4 linePosEnd   = projectionMatrix * (VIEW_SCALE * (modelViewMatrix * vec4(vaPosition + vaNormal, 1.0)));

			vec3 ndc1 = linePosStart.xyz / linePosStart.w;
			vec3 ndc2 = linePosEnd.xyz   / linePosEnd.w;

			vec2 lineScreenDirection = normalize((ndc2.xy - ndc1.xy) * resolution);
			vec2 lineOffset = vec2(-lineScreenDirection.y, lineScreenDirection.x) * LINE_WIDTH / resolution;

			if (lineOffset.x < 0.0) lineOffset = -lineOffset;
			if (gl_VertexID % 2 != 0) lineOffset = -lineOffset;
			
				gl_Position = vec4((ndc1 + vec3(lineOffset, 0.0)) * linePosStart.w, linePosStart.w);
#		else
			gl_Position = projectionMatrix * (modelViewMatrix * worldPos);
#		endif
	}
#endif /* defined GBUFFERS_VSH */

#endif /* !defined GBUFFERS_GLSL_INCLUDED */