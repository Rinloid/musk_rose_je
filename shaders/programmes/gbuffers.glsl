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
	uniform float viewWidth, viewHeight;
	uniform float frameTimeCounter;
	uniform float rainStrength;
	uniform float far, near;

#	if defined USE_TEXTURES
		in vec2 uv0;
#	endif
#	if defined USE_LIGHTMAP
		in vec2 uv1;
#	endif
	in vec4 col;
	in vec4 worldPos;
	in vec4 viewPos;
	in vec3 vNormal;
	in mat3 tbnMatrix;
	in vec3 sunPos;
	in vec3 moonPos;
	in vec3 shadowLightPos;
	in float mcEntity;

	float bayerX2(vec2 a) {
		return fract(dot(floor(a), vec2(0.5, floor(a).y * 0.75)));
	}

	#define bayerX4(a)  (bayerX2 (0.5 * (a)) * 0.25 + bayerX2(a))
	#define bayerX8(a)  (bayerX4 (0.5 * (a)) * 0.25 + bayerX2(a))
	#define bayerX16(a) (bayerX8 (0.5 * (a)) * 0.25 + bayerX2(a))
	#define bayerX32(a) (bayerX16(0.5 * (a)) * 0.25 + bayerX2(a))
	#define bayerX64(a) (bayerX32(0.5 * (a)) * 0.25 + bayerX2(a))

	vec4 getViewPos(const mat4 projInv, const vec2 uv, const float depth) {
		vec4 viewPos = projInv * vec4(vec3(uv, depth) * 2.0 - 1.0, 1.0);

		return viewPos / viewPos.w;
	}

	vec4 getRelPos(const mat4 modelViewInv, const mat4 projInv, const vec2 uv, const float depth) {
		vec4 relPos = modelViewInv * getViewPos(projInv, uv, depth);
		
		return relPos / relPos.w;
	}

	#include "/utils/musk_rose_shadow.glsl"

	vec4 getShadowPos(const mat4 shadowModelView, const mat4 shadowProj, const vec3 relPos, const float diffuse) {
		const float shadowBias = 0.03;

		vec4 shadowPos = vec4(relPos, 1.0);
		shadowPos = shadowProj * (shadowModelView * shadowPos);

		float distortFactor = getDistortFactor(shadowPos.xy);
		shadowPos.xyz = distort(shadowPos.xyz, distortFactor);
		shadowPos.xyz = shadowPos.xyz * 0.5 + 0.5;
		
		shadowPos.z -= shadowBias * (distortFactor * distortFactor) / abs(diffuse);

		return shadowPos;
	}

	const int shadowMapResolution = 2048; // [512 1024 2048 4096]
	const float shadowDistance = 512.0;
	const float sunPathRotation = -40.0;

	#include "/utils/musk_rose_sky.glsl"
	#include "/utils/musk_rose_water.glsl"
	#include "/utils/musk_rose_light.glsl"

	/* 
	** Uncharted 2 tonemapping
	** See: http://filmicworlds.com/blog/filmic-tonemapping-operators/
	*/
	vec3 uncharted2TonemapFilter(const vec3 col) {
		const float A = 0.015; // Shoulder strength
		const float B = 0.500; // Linear strength
		const float C = 0.100; // Linear angle
		const float D = 0.010; // Toe strength
		const float E = 0.020; // Toe numerator
		const float F = 0.300; // Toe denominator

		return ((col * (A * col + C * B) + D * E) / (col * (A * col + B) + D * F)) - E / F;
	}
	vec3 uncharted2Tonemap(const vec3 col, const float whiteLevel, const float exposure) {
		vec3 curr = uncharted2TonemapFilter(col * exposure);
		vec3 whiteScale = 1.0 / uncharted2TonemapFilter(vec3(whiteLevel, whiteLevel, whiteLevel));
		vec3 color = curr * whiteScale;

		return color;
	}

	vec3 hdrExposure(const vec3 col, const float over, const float under) {
		return mix(col / over, col * under, col);
	}

	/* DRAWBUFFERS:0235678 */
	layout(location = 0) out vec4 fragData0;
	layout(location = 1) out vec4 fragData1;
	layout(location = 2) out vec4 fragData2;
	layout(location = 3) out vec4 fragData3;
	layout(location = 4) out vec4 fragData4;
	layout(location = 5) out vec4 fragData5;
	layout(location = 6) out vec4 fragData6;

	void main() {
	float vanillaAO = 0.0;
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

#	if defined USE_ALPHA_TEST
		if (albedo.a < alphaTestRef) discard;
#	endif

#	if defined GBUFFERS_ENTITIES
		albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);
#	endif

	vec4 translucent = vec4(0.0, 0.0, 0.0, 0.0);
	vec2 uv = gl_FragCoord.xy / vec2(viewWidth, viewHeight);

	float depth0 = texture(depthtex0, uv).r;
	float depth1 = texture(depthtex1, uv).r;

	vec4 relPos = getRelPos(gbufferModelViewInverse, gbufferProjectionInverse, uv, depth0);
	vec3 fragPos = worldPos.xyz + cameraPosition;
	vec3 pos = normalize(relPos.xyz);
	vec3 viewDir = -pos;

	vec3 fNormal = vNormal;
	#	if defined USE_TEXTURES && defined MC_NORMAL_MAP
			fNormal = vec3(texture(normals, uv0).rg * 2.0 - 1.0, sqrt(1.0 - dot(texture(normals, uv0).rg * 2.0 - 1.0, texture(normals, uv0).rg * 2.0 - 1.0)));
			fNormal = normalize(fNormal * tbnMatrix);
	#	endif
	if (int(mcEntity) == 1) {
		fNormal = normalize(getWaterWaveNormal(getWaterParallax(viewPos.xyz, fragPos.xz, frameTimeCounter), frameTimeCounter) * tbnMatrix);
	}
	fNormal = mat3(gbufferModelViewInverse) * fNormal;


	float perceptualSmoothness = 0.0;
	float roughness = 0.0;
	float emissive = 0.0;
	float F0 = 0.0;

#	if defined USE_TEXTURES && defined MC_SPECULAR_MAP
		perceptualSmoothness = texture(specular, uv0).r;
		emissive = (texture(specular, uv0).a * 255.0) < 254.5 ? texture(specular, uv0).a : 0.0;
		F0 = texture(specular, uv0).g;
#	endif

	vec3 reflectance = mix(vec3(0.04, 0.04, 0.04), albedo.rgb, F0);

#	if defined USE_LIGHTMAP
		if (int(mcEntity) == 1) {
			albedo.rgb = vec3(0.02, 0.15, 0.2);
			albedo.a = 0.1;
			perceptualSmoothness = 0.897;
			F0 = 0.2;
			reflectance = vec3(F0, F0, F0);
		}
#	endif

	roughness = (1.0 - perceptualSmoothness) * (1.0 - perceptualSmoothness);

	vec3 bloom = vec3(0.0, 0.0, 0.0);
	float lensFlareFactor = 0.0;
	if (emissive > 0.0) {
		bloom = albedo.rgb * emissive;
	}
#	if defined GBUFFERS_SPIDEREYES || defined GBUFFERS_BEACONBEAM
		bloom = albedo.rgb;
#	endif

	vec2 atmoUV = (vec2(shadowLightPos.y, viewDir.y) * mix(0.85, 1.0, bayerX64(gl_FragCoord.xy)) * 0.5 + 0.5);

	vec3 reflectedLight = vec3(0.0, 0.0, 0.0);
#	if defined USE_LIGHTMAP && defined USE_TEXTURES
		if (depth0 != 0.0) {
			float diffuse = max(0.0, dot(shadowLightPos, fNormal));
			vec4 shadowPos = getShadowPos(shadowModelView, shadowProjection, worldPos.xyz, diffuse);
			vec4 directionalShadowCol = vec4(0.0);
			float outdoor = uv1.y;
			float pointLightLevel = uv1.x * uv1.x * uv1.x * uv1.x * uv1.x;

			if (shadowPos.w > 0.0) {
				for (int i = 0; i < int(shadowSamples.length()); i++) {
					vec2 offset = shadowSamples[i] / float(shadowMapResolution);
					offset += bayerX64(gl_FragCoord.xy) / float(shadowMapResolution);
					
					if (texture(shadowtex1, shadowPos.xy + offset).r < shadowPos.z) {
						directionalShadowCol += vec4(0.0, 0.0, 0.0, 1.0);
					} else if (texture(shadowtex0, shadowPos.xy + offset).r < shadowPos.z){
						directionalShadowCol += vec4(texture(shadowcolor0, shadowPos.xy + offset).rgb, 1.0);
					}
				} directionalShadowCol /= shadowSamples.length();
			}
			directionalShadowCol.a = mix(1.0, directionalShadowCol.a, diffuse);

			vec3 directionalLight = vec3(0.0, 0.0, 0.0);
			vec3 undirectionalLight = vec3(0.0, 0.0, 0.0);

			undirectionalLight += getAmbientLight(colortex13, colortex12, pos, sunPos, atmoUV, gl_FragCoord.xy, frameTimeCounter, rainStrength, 0.75, outdoor, pointLightLevel) * (1.0 - vanillaAO);
			directionalLight   += getSunlight(smoothstep(0.0, 0.4, max(0.0, sin(sunPos.y))), directionalShadowCol, rainStrength);
			directionalLight   += getMoonlight(max(0.0, sin(moonPos.y)), directionalShadowCol, rainStrength);
			undirectionalLight += getSkylight(colortex13, colortex12, pos, sunPos, atmoUV, gl_FragCoord.xy, frameTimeCounter, rainStrength, 0.75, outdoor) * (1.0 - vanillaAO);
			undirectionalLight += getPointLight(pointLightLevel, 1.0 - directionalShadowCol.a, smoothstep(0.0, 0.4, max(0.0, sin(sunPos.y))), rainStrength) * (1.0 - vanillaAO);

			vec3 totalLight = undirectionalLight + directionalLight;
			totalLight *= mix(0.65, 1.0, bayerX64(gl_FragCoord.xy) * 0.5 + 0.5);

			albedo.rgb *= totalLight;

			albedo.rgb = uncharted2Tonemap(albedo.rgb, 128.0, 1.25);
			albedo.rgb = hdrExposure(albedo.rgb, 128.0, 1.25);
			
			reflectedLight.rgb = directionalLight / max(vec3(0.001, 0.001, 0.001), totalLight);
		}
#	endif

#	if defined GBUFFERS_SKYBASIC
		albedo.rgb = getSky(colortex13, colortex12, pos, sunPos, atmoUV, gl_FragCoord.xy, frameTimeCounter, rainStrength, 0.75);
		bloom = mix(bloom, vec3(1.0, 1.0, 1.0), getSun(pos, sunPos) * (1.0 - rainStrength));
		lensFlareFactor = getSun(pos, sunPos) * (1.0 - rainStrength);
#	endif

#	if defined GBUFFERS_TRANSLUCENT
		translucent = albedo;
//		albedo.a = 0.0;
#	endif

#	if defined GBUFFERS_CLOUDS || defined GBUFFERS_SKYTEXTURED
		discard;
#	endif

		/* colortex0 (gcolor) */
		fragData0 = albedo;

		/* colortex2 (gnormal) */
		fragData1 = vec4((fNormal + 1.0) * 0.5, 1.0);

		/* colortex3 (composite) */
		fragData2 = translucent;

		/* colortex5 (gaux2) */
		fragData3 = vec4(reflectedLight, 1.0);

		/* colortex6 (gaux3) */
		fragData4 = vec4(roughness, emissive, F0, 1.0);

		/* colortex7 (gaux4) */
#		if defined USE_LIGHTMAP
			fragData5 = vec4(int(mcEntity) * 0.1, uv1, 1.0);
#		else
			fragData5 = vec4(int(mcEntity) * 0.1, 0.0, 0.0, 1.0);
#		endif

		/* colortex8 */
		fragData6 = vec4(bloom, lensFlareFactor);

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
	out vec4 worldPos;
	out vec4 viewPos;
	out vec3 vNormal;
	out mat3 tbnMatrix;
	out vec3 sunPos;
	out vec3 moonPos;
	out vec3 shadowLightPos;
	out float mcEntity;

	void main() {
#	if defined USE_TEXTURES
		uv0 = (textureMatrix * vec4(vaUV0, 0.0, 1.0)).xy;
#	endif
#	if defined USE_LIGHTMAP
		uv1 = vaUV2 * 0.00390625 /* (1.0 / 256.0) */ + 0.03125 /* (1.0 / 32.0) */ ;
#	endif
	col = vaColor;

	worldPos = vec4(vaPosition, 1.0);
#	if defined USE_CHUNK_OFFSET
		worldPos.xyz += chunkOffset;
#	endif

	viewPos = modelViewMatrix * worldPos;

	vec3 tangent  = normalize(normalMatrix * at_tangent.xyz);
	vec3 binormal = normalize(normalMatrix * cross(at_tangent.xyz, vaNormal) * at_tangent.w);
	
	vNormal    = normalize(normalMatrix * vaNormal);
	tbnMatrix  = transpose(mat3(tangent, binormal, vNormal));

	sunPos         = normalize(mat3(gbufferModelViewInverse) * sunPosition);
	moonPos        = normalize(mat3(gbufferModelViewInverse) * moonPosition);
	shadowLightPos = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);

	mcEntity = 0.1;
#	if defined GBUFFERS_TRANSLUCENT
		if (int(mc_Entity.x) == 10001) mcEntity = 1.1; // Water
#	endif

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