#ifndef _MYRP_LIT_HLSL_
#define _MYRP_LIT_HLSL_

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

CBUFFER_START(UnityPerFrame)
    float4x4 unity_MatrixVP;
CBUFFER_END

CBUFFER_START(UnityPerDraw)
    float4x4 unity_ObjectToWorld;
    float4 unity_LightIndicesOffsetAndCount;
    float4 unity_4LightIndices0, unity_4LightIndices1;
CBUFFER_END

#define MAX_VISIBLE_LIGHTS 16

CBUFFER_START(_LightBuffer)
    float4 _VisibleLightColors[MAX_VISIBLE_LIGHTS];
    float4 _VisibleLightDirectionsOrPositions[MAX_VISIBLE_LIGHTS];
    float4 _VisibleLightAttenuations[MAX_VISIBLE_LIGHTS];
    float4 _VisibleLightSpotDirections[MAX_VISIBLE_LIGHTS];
CBUFFER_END

#define UNITY_MATRIX_M unity_ObjectToWorld
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

UNITY_INSTANCING_BUFFER_START(PerInstance)
    UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
UNITY_INSTANCING_BUFFER_END(PerInstance)

//
//
//

float3 DiffuseLight(int index, float3 normal, float3 worldPos)
{
    float3 lightColor = _VisibleLightColors[index].rgb;
    float4 lightDirectionOrPosition = _VisibleLightDirectionsOrPositions[index];
    float4 lightAttenuation = _VisibleLightAttenuations[index];
    float3 spotDirection = _VisibleLightSpotDirections[index].xyz;

    float3 lightVector = lightDirectionOrPosition.xyz - (worldPos * lightDirectionOrPosition.w); // w = 0 for directional, cancels the subtract.
    float3 lightDirection = normalize(lightVector);
    float diffuse = saturate(dot(normal, lightDirection));

    float rangeFade = dot(lightVector, lightVector) * lightAttenuation.x;
    rangeFade = saturate(1.0 - rangeFade * rangeFade);
    rangeFade *= rangeFade;
    
    float spotFade = dot(spotDirection, lightDirection);
    spotFade = saturate(spotFade * lightAttenuation.z + lightAttenuation.w);
    spotFade *= spotFade;

    float distanceSqr = max(dot(lightVector,lightVector), 0.00001); // for directional it == 1
    diffuse *= spotFade * rangeFade / distanceSqr;

    return diffuse * lightColor;
}

//
//
//

struct VertexInput {
    float4 pos : POSITION;
    float3 normal: NORMAL;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VertexOutput {
    float4 clipPos : SV_POSITION;
    float3 normal: TEXCOORD0;
    float3 worldPos: TEXCOORD1;
    float3 vertexLighting : TEXCOORD2; // export the 4 lighting done in vertex shader.
    UNITY_VERTEX_INPUT_INSTANCE_ID // need access to perinstance data in the fragment shader
};

VertexOutput LitPassVertex(VertexInput input)
{
    VertexOutput output;
    UNITY_SETUP_INSTANCE_ID(input); // need to do that before using UNITY_MATRIX_M (unpacking???)
    UNITY_TRANSFER_INSTANCE_ID(input, output); // transfer the instanceID from vertex to fragment shader.
    
    float4 worldPos = mul(UNITY_MATRIX_M, float4(input.pos.xyz, 1.0)); // NOTE: by using float4(input.pos.xyz, 1.0) instead of input.pos, we give the compiler an opportunity to optimize.
    output.clipPos = mul(unity_MatrixVP, worldPos);
    output.normal = mul((float3x3)UNITY_MATRIX_M, input.normal); // no need for inverse transpose, scale is uniform
    output.worldPos = worldPos.xyz;

    output.vertexLighting = 0;
    for (int i = 4; i < min(unity_LightIndicesOffsetAndCount.y, 8); i++) 
    {
        int lightIndex = unity_4LightIndices1[i - 4];
        output.vertexLighting += DiffuseLight(lightIndex, output.normal, output.worldPos);
    }

    return output;
}

float4 LitPassFragment(VertexOutput input) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);
    input.normal = normalize(input.normal);
    float3 albedo = UNITY_ACCESS_INSTANCED_PROP(PerInstance, _Color).rgb; // access to the instance array, or the constant.
    float3 diffuseLight = input.vertexLighting; // the 4 last lights, done in vertex shader.
    // The first 4 lightindices
    for (int i = 0; i < min(unity_LightIndicesOffsetAndCount.y,4); i++)
    {
        int lightIndex = unity_4LightIndices0[i];
        diffuseLight += DiffuseLight(lightIndex, input.normal, input.worldPos);
    }
    float3 color = diffuseLight * albedo;
    return float4(color,1);
}

#endif // _MYRP_LIT_HLSL_
