Shader "My Pipeline/Lit"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Pass
        {
            // The new pipeline uses HLSL instead of CG
            HLSLPROGRAM

            #pragma target 3.5 // default is 2.5, we target advanced devices (no opengl es 2)

            // Generates 2 variants of the shader, one with INSTANCING_ON, and one without.
            // Also adds the "Enable GPU Instancing" checkbox.
            #pragma multi_compile_instancing

            // inform unity that we are not using non-uniform scaling, and therefore Unity will not
            // have to pass the world-to-object matrix for each instance.
            #pragma instancing_options assumeuniformscaling

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            #include "../ShaderLibrary/Lit.hlsl"

            ENDHLSL
        }
    }
}
