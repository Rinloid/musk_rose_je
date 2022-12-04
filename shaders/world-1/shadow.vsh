#version 120

/*
 ** Actually, shadow pass is not a part of G-Bufferes
 * but we will consider it is the same as those
 * due to making waving foliage collectively.
*/
#define GBUFFERS_VERTEX 1
#define GBUFFERS_SHADOW 1

#include "gbuffers.glsl"