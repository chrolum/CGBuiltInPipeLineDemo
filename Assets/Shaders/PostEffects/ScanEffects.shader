Shader "Saltsuica/ScanEffects"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ScanDepth ("Scan Depth", float) = 0
        _CamFar ("Camera Far", float) = 0
        _ScanWidth ("Scan Edge width", Range(0, 5)) = 1
    }
    SubShader
    {
        Cull Off
        ZWrite Off 
        ZTest Always

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 depthUV : TEXCOORD1;
            };

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.texcoord;
                OUT.depthUV = IN.texcoord.xy;
                return OUT;
            }

            sampler2D _MainTex;
            float _ScanDepth;
            float _CamFar;
            float _ScanWidth;
            TEXTURE2D(_CameraDepthTexture);

            SAMPLER(sampler_CameraDepthTexture);
            half4 frag (Varyings i) : SV_Target
            {
                float4 col = tex2D(_MainTex, i.uv);
                
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.depthUV);
                float linearDepth = Linear01Depth(depth, _ZBufferParams);

                if (linearDepth < _ScanDepth)
                {
                    float scanPer = 1 - (_ScanDepth-linearDepth) / (_ScanWidth / _CamFar);
                    return lerp(col, float4(1,0,0,1), scanPer);
                }

                return col;
            }
            ENDHLSL
        }
    }
}
