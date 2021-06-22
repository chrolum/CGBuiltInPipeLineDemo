Shader "Saltsuica/MySnow"
{
    Properties
    {
        [Header(Snow setting)]
        _SnowNoise("Snow Noise", 2D) = "" {}
        _SnowNoiseScale("Snow Noise Scale", Range(0, 2)) = 0.1
        _SnowHeight("Snow Height", Range(0, 5)) = 1
        _SnowNoiseWeight("Noise Weight", Range(0, 1)) = 0.1

        _SnowDepth("Snow Depth", Range(0, 10)) = 0.5
        _SnowInteractRadius("Interactive radius", Range(0, 5)) = 1
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
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            // snow base
            sampler2D _SnowNoise;
            float _SnowHeight; 
            float _SnowNoiseScale;
            float _SnowNoiseWeight;
            float _SnowDepth;

            // snow trail
            uniform float3 _PlayerPos;
            float _SnowInteractRadius;


            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 color : COLOR0;
            };

            v2f vert(appdata_full v)
            {
                v2f o;
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
                float snowNoise = tex2Dlod(_SnowNoise, float4(worldPos.xz * _SnowNoiseScale, 0,0));

                o.color = v.color;
                o.vertex = v.vertex;

                // basic snow Bump
                o.vertex.xyz += normalize(v.normal) * _SnowHeight + snowNoise * _SnowNoiseWeight;

                // snow Snow marks
                float dis = distance(_PlayerPos.xz, worldPos.xz);
                float radius = 1 - saturate(dis / _SnowInteractRadius);
                o.vertex.xyz -= normalize(v.normal) * _SnowDepth * radius;
                o.vertex = UnityObjectToClipPos(o.vertex);
                return o;
            }

            fixed4 frag(appdata_full i) : SV_TARGET
            {
                return float4(1,1,1,1);
            }

            ENDCG
        }
    }
}