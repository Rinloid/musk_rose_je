#if !defined LIGHTING_INCLUDED
#define LIGHTING_INCLUDED 1

vec4 shadowPos = getShadowPos(gbufferModelViewInverse, gbufferProjectionInverse, shadowModelView, shadowProjection, relPos, uv, depth, diffuse);
if (diffuse > 0.0) {
    if (texture2D(shadowtex0, shadowPos.xy).r < shadowPos.z) {
        if (texture2D(shadowtex1, shadowPos.xy).r < shadowPos.z) {
            shadows = vec4(vec3(0.0), 0.0);
        } else {
            shadows = vec4(texture2D(shadowcolor0, shadowPos.xy).rgb, 0.0);
        }
    }
}

amnientLightFactor = mix(0.0, mix(0.9, 1.4, daylight), uv1.y);
dirLightFactor = mix(0.0, diffuse, shadows.a);
emissiveLightFactor = uv1.x * uv1.x * uv1.x * uv1.x * uv1.x;
ambientLightCol = mix(mix(vec3(0.0), TORCHLIGHT_COL, emissiveLightFactor), mix(MOONLIGHT_COL, daylightCol, daylight), dirLightFactor);
ambientLightCol += 1.0 - max(max(ambientLightCol.r, ambientLightCol.g), ambientLightCol.b);

light += ambientLightCol * AMBIENT_LIGHT_INTENSITY * amnientLightFactor;
light += sunlightCol * SUNLIGHT_INTENSITY * dirLightFactor * daylight * clearWeather;
light += MOONLIGHT_COL * MOONLIGHT_INTENSITY * dirLightFactor * (1.0 - daylight) * clearWeather;
light += SKYLIGHT_COL * SKYLIGHT_INTENSITY * dirLightFactor * daylight * clearWeather;
light += TORCHLIGHT_COL * TORCHLIGHT_INTENSITY * emissiveLightFactor;

/*
** Apply coloured shadows.
*/
light += ((normalize(light) + 1.0) * 0.5 - (1.0 - shadows.rgb)) * light;

albedo *= light;
albedo = hdrExposure(albedo, EXPOSURE_BIAS, 0.2);
albedo = uncharted2ToneMap(albedo, EXPOSURE_BIAS);
albedo = contrastFilter(albedo, 1.2);

float fogFactor = clamp((length(relPos) - near) / (far - near), 0.0, 1.0);
float fogBrightness = skyBrightness;
vec3 fogCol = toneMapReinhard(getAtmosphere(skyPos, shadowLightPos, SKY_COL, fogBrightness));
albedo = mix(albedo, fogCol, fogFactor);

#endif /* !defined LIGHTING_INCLUDED */