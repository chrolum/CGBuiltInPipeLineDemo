Shader "Saltsuica/3DTextureDebug"
{
    Properties
    {
        _MainTex("Main Texture", 2D) = "" {}
        _Noise3D("3D Noise Texture", 3D) = "" {}
        _NoiseScale("Noise scale", Range(0, 2)) = 0.2
        _Speed("UV offset speed", Range(0,2)) = 0.3
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 uv : TEXCOORD0;
            };

            struct v2f
            {
                float3 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler3D _Noise3D;
            sampler2D _MainTex;
            float2 _MainTex_ST;
            float _NoiseScale;
            float _Speed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half3 flowUV = i.uv.xyz / _NoiseScale + _Time.x * _Speed * half3(1, 1, 1);
                half3 noise = tex3D(_Noise3D, flowUV);

                return float4(noise, 1);
            }
            ENDCG
        }
    }
}
