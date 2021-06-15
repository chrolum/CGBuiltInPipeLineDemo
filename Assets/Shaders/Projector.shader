Shader "Saltsuica/Projector"
{
    Properties
    {
        _Mask("Mask", 2D) = ""{}
        _Noise("Noise", 2D) = ""{}
        _Tile("Tile", 2D) = ""{}
        _FalloffTex("Fall off", 2D) = ""{}
        _Color("Main Color", Color) = (0,0,1,0.7)

        [Enum(UnityEngine.Rendering.BlendMode)] _BlendOp ("Blend Op", Int) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _BlendMode ("Blend Mode", Int) = 10
    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque" 
            "Queue" = "Transparent"
        }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include "UnityCG.cginc"

            struct v2f
            {
                float4 uvMask : TEXCOORD0;
                float4 pos : SV_POSITION;
                float4 uvFalloff : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float3 worldNormal : TEXCOORD3;
            };

            float4x4 unity_Projector;
            float4x4 unity_ProjectorClip;

            sampler2D _FalloffTex;
            sampler2D _Mask;    
            float4 _Color;        

            v2f vert (appdata_full v)
            {
                v2f o;

                o.uvFalloff = mul(unity_ProjectorClip, v.vertex);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uvMask = mul(unity_Projector, v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                //法线流？
                o.worldNormal = normalize(mul(float4(v.normal, 0.0), unity_ObjectToWorld).xyz);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float falloff = tex2Dproj(_FalloffTex, UNITY_PROJ_COORD(i.uvFalloff)).a;
                float alphaMask = tex2Dproj(_Mask, UNITY_PROJ_COORD(i.uvMask)).a;
                float alpha = falloff * alphaMask;

                _Color *= alpha * _Color.a;

                return _Color;
            }
            ENDCG
        }
    }
}
