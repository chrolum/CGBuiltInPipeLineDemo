Shader "Saltsuica/InteractWater"
{
    Properties
    {
        _Color("Tint", Color) = (1, 1, 1, .5)//discard
        _NightColor("Night Color", Color) = (1, 1, 1, .5)
        _FoamC("Foam", Color) = (1, 1, 1, .5)
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex("Noise", 2D) = "" {}
        _TextureDistort("TextureDistort", Range(0,1)) = 0.1

        _Scale("Scale", Range(0, 1)) = 0.5
        _Speed("Wave Speed", Range(0, 1)) = 0.5
        _Amount("Wave Amount", Range(0, 1)) = 0.6
        _Height("Wave Height", Range(0, 1)) = 0.1

        _TessellationUniform("Tessellation Uniform", Range(1, 64)) = 1

        _Foam("Foamline Thickness", Range(0,10)) = 8
    }
    SubShader
    {
        Tags 
        {
            "RenderType"="Opaque" 
            "Queue" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
            
        }
        LOD 100
        Cull Off
        Blend OneMinusDstColor one

        // GrabPass
        // {
        //     Name "BASE"
        //     Tags{ "LightMode" = "Always" }
        // }

        HLSLINCLUDE
        #pragma vertex vert
        #pragma fragment frag
        // make fog work
        #pragma multi_compile_fog

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"

        struct Attributes 
        {
        float4 positionOS   : POSITION;
        float2 uv           : TEXCOORD0;
        float3 normal       : NORMAL;
        };

        struct Varyings 
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS : TEXCOORD0;
            float4 positionSS : TEXCOORD1;
            float2 uv : TEXCOORD2;
            float3 normal : NORMAL;
        };
        ENDHLSL

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            HLSLPROGRAM
            

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _Color;
            float4 _NightColor;
            sampler2D _CameraDepthTexture;
            float _Scale;
            sampler2D _NoiseTex;

            //for wave
            float _Speed;
            float _Height;
            float _Amount;

            //for foam line
            float _Foam;
            float _FoamC;

            uniform float3 _Position;
            uniform sampler2D _GlobalWaterEffectRT;
            uniform float _OrthographicCamSize;

            float _TextureDistort;

            Varyings vert (Attributes v)
            {
                Varyings o;
                //make some wave
                // 几种不同的波形
                // v.vertex.y += sin(_Time.z * _Speed + v.vertex.x * _Amount);
                // v.vertex.y += sin(_Time.z * _Speed + v.vertex.z * _Amount);
                // v.vertex.y += sin(_Time.z * _Speed + v.vertex.x * _Amount + v.vertex.z * _Amount);
                v.positionOS.y += sin(_Time.z * _Speed + v.positionOS.x * v.positionOS.z * _Amount) * _Height;
                VertexPositionInputs vertInput = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = vertInput.positionCS;
                o.positionWS = vertInput.positionWS;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.positionSS = ComputeScreenPos(o.positionCS);
                o.normal = v.normal;
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                // sample the texture
                float distortx = tex2D(_NoiseTex, (i.positionWS.xz * _Scale) + (_Time.x * 2)).r;
                half4 col = tex2D(_MainTex, (i.positionWS.xz * _Scale) - (distortx * _TextureDistort));
                
                half depth = LinearEyeDepth(tex2Dproj(_CameraDepthTexture, float4(i.positionSS.xz / i.positionSS.w, 0, 0)), _ZBufferParams);
                // apply fog

                //for foamline
                half4 foamLine = 1-saturate(_Foam * (depth - i.positionSS.w));
                // float3 ambient = ShadeSH9(float4(i.normal, 1));
                //TODO: use NdotL
                float NdotL = saturate(dot(i.normal, _MainLightPosition));
                NdotL = max(clamp(NdotL + 0.3, 0, 1), 0.3);// 防止晚上水消失了
                col *= _MainLightColor * NdotL; //改用直接光照，不再自定义颜色

                float2 uv = i.positionWS.xz - _Position.xz;
                uv = uv / (_OrthographicCamSize * 2);
                uv += 0.5;
                float ripples = tex2D(_GlobalWaterEffectRT, uv).b;
                ripples = step(0.6, ripples * 2);
                distortx += (ripples * 2);

                col += (step(0.4 * distortx, foamLine) *_FoamC);
                // TODO: foamline 应该根据直接光照的颜色亮度计算明暗
                col += foamLine;

                return col + ripples * _MainLightColor;
            }
            ENDHLSL
        }
    }
    Fallback off
}
