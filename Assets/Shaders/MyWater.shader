Shader "Unlit/MyWater"
{
    Properties
    {
        _Color("Tint", Color) = (1, 1, 1, .5)
        _MainTex ("Texture", 2D) = "white" {}

        _Scale("Scale", Range(0, 1)) = 0.5
        _Speed("Wave Speed", Range(0, 1)) = 0.5
        _Amount("Wave Amount", Range(0, 1)) = 0.6
        _Height("Wave Height", Range(0, 1)) = 0.1

        _TessellationUniform("Tessellation Uniform", Range(1, 64)) = 1
    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque" 
            "Queue" = "Transparent"
        }
        LOD 100
        Cull Off
        Blend OneMinusDstColor one

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD3;
                // float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 srcPos : TEXCOORD2;
                float4 worldPos : TEXCOORD4;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _Color;
            sampler2D _CamerDepthTexture;
            float _Scale;

            //for wave
            float _Speed;
            float _Height;
            float _Amount;

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                //make some wave
                // 几种不同的波形
                // v.vertex.y += sin(_Time.z * _Speed + v.vertex.x * _Amount);
                // v.vertex.y += sin(_Time.z * _Speed + v.vertex.z * _Amount);
                // v.vertex.y += sin(_Time.z * _Speed + v.vertex.x * _Amount + v.vertex.z * _Amount);
                v.vertex.y += sin(_Time.z * _Speed + v.vertex.x * v.vertex.z * _Amount);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.srcPos = ComputeScreenPos(o.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                half4 col = tex2D(_MainTex, i.worldPos.xz * _Scale);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                col *= _Color; //why
                col = saturate(col) * col.a;
                return col;
                // return float4(i.worldPos.x, 0, i.worldPos.z, 1);
            }
            ENDCG
        }
    }
}
