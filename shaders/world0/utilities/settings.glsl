#if !defined SETTINGS_INCLUDED
#define SETTINGS_INCLUDED

#define INFO 1

#define RAY_COL  vec3(0.63, 0.62, 0.45)
#define SKY_COL  vec3(0.4, 0.65, 1.0)
#define MOON_COL vec3(1.0, 0.95, 0.81)

#define AMBIENT_LIGHT_INTENSITY 40.0
#define SKYLIGHT_INTENSITY 15.0
#define SUNLIGHT_INTENSITY 85.0
#define RAY_INTENSITY 2.0
#define MOONLIGHT_INTENSITY 35.0
#define TORCHLIGHT_INTENSITY 10.0

#define SKYLIT_COL vec3(0.9, 0.98, 1.0)
#define SUNLIT_COL vec3(1.0, 0.9, 0.85)
#define SUNLIT_COL_SET vec3(1.0, 0.60, 0.1)
#define TORCHLIT_COL vec3(1.0, 0.65, 0.3)
#define MOONLIT_COL vec3(0.5, 0.65, 1.0)

#define ENABLE_FOG
#define ENABLE_LIGHT_RAYS
#define ENABLE_SSAO
#define ENABLE_CLOUDS
#define ENABLE_CLOUD_SHADING
// #define ENABLE_BEDROCK_SHADOWS
#define ENABLE_SKY_REFLECTION
#define ENABLE_SPECULAR
#define ENABLE_WATER_WAVES
#define ENABLE_SSR
#define ENABLE_REFRACTION
#define ENABLE_UNDERWATER_CAUSTICS
#define ENABLE_UNDERWATER_FOG
#define FRESNEL_RATIO 0.8 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define GAMMA 2.2 // [1.8 2.2 2.4]


#endif /* !defined SETTINGS_INCLUDED */