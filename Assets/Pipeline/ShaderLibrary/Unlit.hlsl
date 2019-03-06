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

// We use the macro whether we are instancing or not.
// The include will redefine this same macro to use an array of matrices, per instance.
#define UNITY_MATRIX_M unity_ObjectToWorld
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

//CBUFFER_START(UnityPerMaterial)
//  float4 _Color; // the name of the property we added to the material. Unity will figure out how to pass it.
//CBUFFER_END

// unlike the UNITY_MATRIX_M, custom per instance data have to be handled manually
// This puts _Color in a per instance buffer if instancing is ON, else we have just one variable, in a constant buffer.
UNITY_INSTANCING_BUFFER_START(PerInstance)
    UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
UNITY_INSTANCING_BUFFER_END(PerInstance)


struct VertexInput {
    float4 pos : POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VertexOutput {
    float4 clipPos : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID // need access to perinstance data in the fragment shader
};

VertexOutput UnlitPassVertex(VertexInput input)
{
    VertexOutput output;
    UNITY_SETUP_INSTANCE_ID(input); // need to do that before using UNITY_MATRIX_M (unpacking???)
    UNITY_TRANSFER_INSTANCE_ID(input, output); // transfer the instanceID from vertex to fragment shader.
    float4 worldPos = mul(UNITY_MATRIX_M, float4(input.pos.xyz, 1.0)); // NOTE: by using float4(input.pos.xyz, 1.0) instead of input.pos, we give the compiler an opportunity to optimize.
    output.clipPos = mul(unity_MatrixVP, worldPos);
    return output;
}

float4 UnlitPassFragment(VertexOutput input) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);
    return UNITY_ACCESS_INSTANCED_PROP(PerInstance, _Color); // access to the instance array, or the constant.
}

#endif // _MYRP_UNLIT_HLSL_
