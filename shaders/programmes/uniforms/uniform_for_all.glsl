#if !defined UNIFORM_FOR_ALL_GLSL_INCLUDED
#define UNIFORM_FOR_ALL_GLSL_INCLUDED

uniform int heldItemId;
uniform int heldBlockLightValue;
uniform int heldItemId2;
uniform int heldBlockLightValue2;
uniform int fogMode;
uniform float fogStart;
uniform float fogEnd;
uniform int fogShape;
uniform float fogDensity;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform int worldTime;
uniform int worldDay;
uniform int moonPhase;
uniform int frameCounter;
uniform float frameTime;
uniform float frameTimeCounter;
uniform float sunAngle;
uniform float shadowAngle;
uniform float rainStrength;
uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;
uniform float near;
uniform float far;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 shadowLightPosition;
uniform vec3 upPosition;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform float wetness;
uniform float eyeAltitude;
uniform ivec2 eyeBrightness;
uniform ivec2 eyeBrightnessSmooth;
uniform ivec2 terrainTextureSize;
uniform int terrainIconSize;
uniform int isEyeInWater;
uniform float nightVision;
uniform float blindness;
uniform float screenBrightness;
uniform int hideGUI;
uniform float centerDepthSmooth;
uniform ivec2 atlasSize;
uniform vec4 spriteBounds;
uniform vec4 entityColor;
uniform int entityId;
uniform int blockEntityId;
uniform ivec4 blendFunc;
uniform int instanceId;
uniform float playerMood;
uniform int renderStage;
uniform int bossBattle;

#if MC_VERSION >= 11700
    uniform mat4 modelViewMatrix;
    uniform mat4 modelViewMatrixInverse;
    uniform mat4 projectionMatrix;
    uniform mat4 projectionMatrixInverse;
    uniform mat4 textureMatrix = mat4(1.0); // Set a default value when the uniform is not bound.
    uniform mat3 normalMatrix;
    uniform vec3 chunkOffset;
    uniform float alphaTestRef;
#   if MC_VERSION >= 11900
        uniform float darknessFactor;
        uniform float darknessLightFactor;
#   endif
#endif

#endif /* !defined UNIFORM_FOR_ALL_GLSL_INCLUDED */