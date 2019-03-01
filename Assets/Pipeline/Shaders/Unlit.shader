Shader "My Pipeline/Unlit"
{
    Properties
    {
        
    }
    SubShader
    {
        Pass
        {
            // The new pipeline uses HLSL instead of CG
            HLSLPROGRAM

            #pragma target 3.5 // default is 2.5, we target advanced devices (no opengl es 2)

            #pragma vertex UnlitPassVertex
            #pragma fragment UnlitPassFragment

            #include "../ShaderLibrary/Unlit.hlsl"

            ENDHLSL
        }
    }
}
