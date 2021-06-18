Shader "Unlit/MyWater"
{
    Properties
    {
        _Color("Tint", Color) = (1, 1, 1, .5)//discard
        _MoonColor("Moon light color", Color) = (1,1,1,1)
        _FoamC("Foam", Color) = (1, 1, 1, .5)
        _MainTex ("Texture", 2D) = "white" {}

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
            "LightMode" = "ForwardBase"
            
        }
        LOD 100
        Cull Off
        Blend OneMinusDstColor one

        GrabPass
        {
            Name "BASE"
            Tags{ "LightMode" = "Always" }
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD3;
                // float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 srcPos : TEXCOORD2;
                float4 worldPos : TEXCOORD4;
                float3 normal : NORMAL;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _Color;
            float4 _MoonColor;
            sampler2D _CameraDepthTexture;
            float _Scale;

            //for wave
            float _Speed;
            float _Height;
            float _Amount;

            //for foam line
            float _Foam;
            float _FoamC;

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                //make some wave
                // 几种不同的波形
                // v.vertex.y += sin(_Time.z * _Speed + v.vertex.x * _Amount);
                // v.vertex.y += sin(_Time.z * _Speed + v.vertex.z * _Amount);
                // v.vertex.y += sin(_Time.z * _Speed + v.vertex.x * _Amount + v.vertex.z * _Amount);
                v.vertex.y += sin(_Time.z * _Speed + v.vertex.x * v.vertex.z * _Amount) * _Height;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.srcPos = ComputeScreenPos(o.vertex);
                o.normal = v.normal;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                half4 col = tex2D(_MainTex, i.worldPos.xz * _Scale);
                half depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.srcPos)));
                
                //for foamline
                half4 foamLine = 1-saturate(_Foam * (depth - i.srcPos.w));
                float3 ambient = ShadeSH9(float4(i.normal, 1));
                float NdotLSun = saturate(dot(i.normal, _WorldSpaceLightPos0));
                float NdotLMoon = saturate(dot(i.normal, -_WorldSpaceLightPos0));
                float4 lightColor = NdotLSun * _LightColor0 + NdotLMoon * _MoonColor;

                col *= lightColor; //改用直接光照，不再自定义颜色
                col += (step(0.4 * 1,foamLine) * _FoamC); // add the foam line and tint to the texture
                // TODO: foamline 应该根据直接光照的颜色亮度计算明暗
                col += foamLine;

                // return float4(ambient, 1);
                return col;
            }
            ENDCG
        }
    }
}
