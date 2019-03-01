#ifndef _MYRP_UNLIT_HLSL_
#define _MYRP_UNLIT_HLSL_

// using simple variables
//float4x4 unity_MatrixVP; // Unity expects this variable, and fills it itself.
//float4x4 unity_ObjectToWorld; // Unity expects this variable, and fills it itself.

// Unity fills this buffer, with many more stuff.
//cbuffer UnityPerFrame {
//    float4x4 unity_MatrixVP;
//};
//
//cbuffer UnityPerDraw {
//    float4x4 unity_ObjectToWorld;
//}

// cbuffers are not supported on all platforms, so we use the provided macro.
// These macros are defined in the render-pipelines.core package
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

CBUFFER_START(UnityPerFrame)
float4x4 unity_MatrixVP;
CBUFFER_END

CBUFFER_START(UnityPerDraw)
float4x4 unity_ObjectToWorld;
CBUFFER_END

struct VertexInput {
    float4 pos : POSITION;
};

struct VertexOutput {
    float4 clipPos : SV_POSITION;
};

VertexOutput UnlitPassVertex(VertexInput input)
{
    VertexOutput output;
    // NOTE: by using float4(input.pos.xyz, 1.0) instead of input.pos, we give the compiler an opportunity to optimize.
    float4 worldPos = mul(unity_ObjectToWorld, float4(input.pos.xyz, 1.0)); 
    output.clipPos = mul(unity_MatrixVP, worldPos);
    return output;
}

float4 UnlitPassFragment(VertexOutput input) : SV_TARGET
{
    return 1; // white
}

#endif // _MYRP_UNLIT_HLSL_
