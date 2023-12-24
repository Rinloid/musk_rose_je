#if !defined ATTRIBUTE_FOR_ALL_GLSL_INCLUDED
#define ATTRIBUTE_FOR_ALL_GLSL_INCLUDED

in vec2 mc_midTexCoord;
in vec3 mc_Entity;
in vec3 at_velocity;
in vec3 at_midBlock;
in vec4 at_tangent;

#if MC_VERSION >= 11700
    in ivec2 vaUV1;
    in vec2 vaUV0;
    in ivec2 vaUV2;
    in vec3 vaPosition;
    in vec3 vaNormal;
    in vec4 vaColor;
#endif

#endif /* !defined ATTRIBUTE_FOR_ALL_GLSL_INCLUDED */