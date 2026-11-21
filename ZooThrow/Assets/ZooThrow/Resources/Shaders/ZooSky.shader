// Gradient skybox: horizon, zenith and a soft sun disc. Works as RenderSettings.skybox in URP.
Shader "ZooThrow/Sky"
{
    Properties
    {
        _ZenithColor ("Zenith", Color) = (0.30, 0.62, 1.0, 1)
        _HorizonColor ("Horizon", Color) = (0.80, 0.92, 1.0, 1)
        _GroundColor ("Ground", Color) = (0.55, 0.70, 0.55, 1)
        _SunColor ("Sun", Color) = (1, 0.95, 0.75, 1)
        _SunSize ("Sun size", Range(0.001, 0.2)) = 0.04
        _HorizonSharpness ("Horizon sharpness", Range(0.5, 8)) = 2.5
    }
    SubShader
    {
        Tags { "Queue" = "Background" "RenderType" = "Background" "PreviewType" = "Skybox" "RenderPipeline" = "UniversalPipeline" }
        Cull Off
        ZWrite Off
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _ZenithColor;
                half4 _HorizonColor;
                half4 _GroundColor;
                half4 _SunColor;
                half _SunSize;
                half _HorizonSharpness;
            CBUFFER_END
            float3 _ZT_SunDirection;

            struct Attributes { float4 positionOS : POSITION; };
            struct Varyings { float4 positionCS : SV_POSITION; float3 dir : TEXCOORD0; };

            Varyings vert(Attributes v)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.dir = v.positionOS.xyz;
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                float3 d = normalize(i.dir);
                half up = saturate(d.y);
                half down = saturate(-d.y);
                half3 sky = lerp(_HorizonColor.rgb, _ZenithColor.rgb, pow(up, 1.0 / _HorizonSharpness));
                half3 col = lerp(sky, _GroundColor.rgb, saturate(down * 6.0));
                half sun = smoothstep(1.0 - _SunSize, 1.0 - _SunSize * 0.6, dot(d, normalize(_ZT_SunDirection)));
                half halo = pow(saturate(dot(d, normalize(_ZT_SunDirection))), 64.0) * 0.35;
                col += _SunColor.rgb * (sun + halo);
                return half4(col, 1);
            }
            ENDHLSL
        }
    }
    FallBack Off
}
