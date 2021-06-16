Shader "Saltsuica/InteractWater"
{
    Properties
    {
        _Color("Tint", Color) = (1, 1, 1, .5)//discard
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
            uniform sampler2D _GlobalEffectRT;
            uniform float _OrthographicCamSize;

            float _TextureDistort;

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
                float distortx = tex2D(_NoiseTex, (i.worldPos.xz * _Scale) + (_Time.x * 2)).r;
                half4 col = tex2D(_MainTex, (i.worldPos.xz * _Scale) - (distortx * _TextureDistort));
                half depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.srcPos)));
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

                //for foamline
                half4 foamLine = 1-saturate(_Foam * (depth - i.srcPos.w));
                float3 ambient = ShadeSH9(float4(i.normal, 1));
                col *= _LightColor0; //改用直接光照，不再自定义颜色

                float2 uv = i.worldPos.xz - _Position.xz;
                uv = uv / (_OrthographicCamSize * 2);
                uv += 0.5;
                float ripples = tex2D(_GlobalEffectRT, uv).b;
                ripples = step(0.99, ripples * 2);
                distortx += (ripples * 2);

                col += (step(0.4 * distortx, foamLine) *_FoamC);
                // TODO: foamline 应该根据直接光照的颜色亮度计算明暗
                col += foamLine;

                return col + ripples;
            }
            ENDCG
        }
    }
}
