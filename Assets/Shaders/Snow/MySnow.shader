Shader "Saltsuica/MySnow"
{
    Properties
    {
        [Header(Snow setting)]
        _SnowNoise("Snow Noise", 2D) = "" {}
        _SnowTex("Snow Tex", 2D) = "" {}
        _SnowNoiseScale("Snow Noise Scale", Range(0, 2)) = 0.1
        _SnowTexScale("Snow texture scale", Range(0, 2)) = 0.1
        _SnowTextureOpacity("Snow Tex Opacity", Range(0, 2)) = 0.3
        _SnowHeight("Snow Height", Range(0, 5)) = 1
        _SnowNoiseWeight("Noise Weight", Range(0, 1)) = 0.1

        _Mask("Mask", 2D) = "" {}

        _SnowDepth("Snow Depth", Range(-10, 10)) = 0.5
        _SnowColor("Snow Color", Color) = (0.5,0.5,0.5,1)
        _SnowPathColor("Path color", Color) = (0.5,0.5,0.7,1)
        

        [Header(Tess setting)]
        _Tess("Tess Amount", Range(0, 64)) = 1
        _MaxTessDistance("Max Tess Distance", Range(0, 100)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex tessVert
            #pragma fragment frag
            #pragma hull hull
            #pragma domain domain
            // make fog work c 
            #pragma multi_compile_fog
            #pragma target 4.0
            #pragma require tessellation tessHW

            #include "UnityCG.cginc"

            // snow base
            sampler2D _SnowNoise;
            sampler2D _SnowTex;

            float _SnowHeight; 
            float _SnowNoiseScale;
            float _SnowTexScale;
            float _SnowNoiseWeight;
            float _SnowDepth;
            float _SnowTextureOpacity;

            //snow path
            float4 _SnowPathColor;
            float4 _SnowColor;

            sampler2D _Mask;
            // snow trail

            uniform float3 _Position;
            uniform sampler2D _GlobalEffectRT;
            uniform float _OrthographicCamSize;

            #include "SnowTessellation.cginc"
            
            ControlPoint tessVert(Attributes v)
            {
                ControlPoint output;
                output.vertex = v.vertex;
                output.uv = v.uv;
                output.color = v.color;
                output.normal = v.normal;

                return output;
            }

            // v2f vert(appdata_full v)
            // {
            //     v2f o;
            //     float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
            //     float snowNoise = tex2Dlod(_SnowNoise, float4(worldPos.xz * _SnowNoiseScale, 0,0));

            //     o.color = v.color;
            //     o.vertex = v.vertex;

            //     float2 uv = worldPos.xz - _Position.xz; // render-texture的uv坐标
            //     uv = uv / (_OrthographicCamSize * 2);
            //     uv += 0.5;

            //     float4 RTEffect = tex2Dlod(_GlobalEffectRT, float4(uv, 0, 0));

            //     // basic snow Bump
            //     o.vertex.xyz += normalize(v.normal) * _SnowHeight + snowNoise * _SnowNoiseWeight;

            //     // snow Snow marks
            //     float dis = distance(_Position.xz, worldPos.xz);
            //     float radius = 1 - saturate(dis / _SnowInteractRadius);
            //     // o.vertex.xyz -= normalize(v.normal) * _SnowDepth * radius;
            //     o.vertex.xyz -= normalize(v.normal) * RTEffect.g * _SnowDepth;
            //     o.vertex = UnityObjectToClipPos(o.vertex);
            //     return o;
            // }

            fixed4 frag(Varyings v) : SV_TARGET
            {
                float2 uv = v.worldPos.xz - _Position.xz; // render-texture的uv坐标
                uv = uv / (_OrthographicCamSize * 2);
                uv += 0.5;

                float4 effect = tex2D(_GlobalEffectRT, uv);
                float mask = tex2D(_Mask, uv).a;
                effect *= mask;

                float3 topdownNoise = tex2D(_SnowNoise, v.worldPos.xz * _SnowNoiseScale).rgb;
                float3 snowTexRes = tex2D(_SnowTex, v.worldPos.xz * _SnowTexScale).rgb;

                float3 maincolor = snowTexRes * _SnowTextureOpacity + _SnowColor;

                maincolor = lerp(maincolor, _SnowPathColor * effect.g * 2, saturate(effect.g * 3)).rgb;

                return float4(maincolor, 1);
            }

            ENDCG
        }

        pass
        {
            Tags{ "LightMode" = "ShadowCaster" }
            CGPROGRAM
            float4 frag(Varyings v) :SV_TARGET
            {
                return 0;
            }
            ENDCG
        }
    }
}
