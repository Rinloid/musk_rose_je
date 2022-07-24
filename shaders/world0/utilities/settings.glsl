#if !defined SETTINGS_INCLUDED
#define SETTINGS_INCLUDED

#define RAY_COL vec3(1.0, 0.85, 0.63)
#define SKY_COL vec3(0.4, 0.65, 1.0)

#define AMBIENT_LIGHT_INTENSITY 30.0
#define SKYLIGHT_INTENSITY 2.0
#define SUNLIGHT_INTENSITY 35.0
#define RAY_INTENSITY 2.0
#define MOONLIGHT_INTENSITY 5.0
#define TORCHLIGHT_INTENSITY 2.0

#define SKYLIT_COL vec3(0.9, 0.98, 1.0)
#define SUNLIT_COL vec3(1.0, 0.9, 0.75)
#define SUNLIT_COL_SET vec3(1.0, 0.60, 0.2)
#define TORCHLIT_COL vec3(1.0, 0.65, 0.3)
#define MOONLIT_COL vec3(0.65, 0.65, 1.0)

#define ENABLE_FOG
#define ENABLE_CLOUDS
#define ENABLE_CLOUD_SHADING
// #define BEDROCK_SHADOWS
#define ENABLE_SKY_REFLECTION
#define ENABLE_SPECULAR
#define ENABLE_WATER_WAVES
#define ENABLE_SSR
#define ENABLE_REFRACTION
#define ENABLE_UNDERWATER_CAUSTICS
#define ENABLE_UNDERWATER_FOG
#define FRESNEL_RATIO 0.8 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]


#endif /* !defined SETTINGS_INCLUDED */