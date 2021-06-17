Shader "Saltsuica/MySkyBox"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        [Header(Sun Settings)]
		 _SunColor("Sun Color", Color) = (1,1,1,1)
		_SunRadius("Sun Radius",  Range(0, 2)) = 0.1

        _MoonColor("Moon Color", Color) = (1,1,1,1)
		_MoonRadius("Moon Radius",  Range(0, 2)) = 0.1
        //TODO: 优化offet滑条[-1,1]表示两个满月的月相
        _MoonOffset("Moon Offset", Range(-2, 2)) = 0.1

        _DayTopColor("Day Top Color", Color) = (1,1,1,1)
        _DayBottomColor("Day Bottome Color", Color) = (1,1,1,1)
        _NightTopColor("Night Top Color", Color) = (1,1,1,1)
        _NightBottomColor("Night Bottom Color", Color) = (1,1,1,1)
        _HorizonColorDay("Horizon Color", Color) = (1,1,1,1)
        _HorizonIntensity("HorizonIntensity", range(0, 20)) = 0.1
        _HorizonOffset("HorizonIntensity", range(-20, 20)) = 0.1
        
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

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _SunColor;
            float _SunRadius;

            float4 _MoonColor;
            float _MoonRadius;
            float _MoonOffset;

            // color config
            float4 _DayTopColor;
            float4 _DayBottomColor;
            float4 _NightTopColor;
            float4 _NightBottomColor;
            float4 _HorizonColorDay;
            float _HorizonIntensity;
            float _HorizonOffset;


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

                // get horizon
                float horizon = abs(i.uv.y * _HorizonIntensity) + _HorizonOffset;
                float horizonGlow = saturate((1-horizon) * saturate(_WorldSpaceLightPos0.y));
                float3 horizonDayColor = horizonGlow * _HorizonColorDay.xyz;

                float sunDist = distance(i.uv.xyz, _WorldSpaceLightPos0);
                float moonDist = distance(i.uv.xyz, -_WorldSpaceLightPos0);
                float sun = 1 - saturate(sunDist / _SunRadius);
                // fuzzy color for moon
                // float moon = 1 - saturate(moonDist / _MoonRadius);
                // solid moon color
                float moon = 1- step(_MoonRadius, moonDist);

                // crescentMoon 
                float crescentMoonDist = distance(float3(i.uv.x + _MoonOffset, i.uv.yz), -_WorldSpaceLightPos0);
                
                float crescentMoon = 1 - step(_MoonRadius, crescentMoonDist);
                moon = saturate(moon - crescentMoon);
                float3 sunAndMoon = (sun * _SunColor) + (moon * _MoonColor);

                // gradient sky color
                float3 gradientDay = lerp(_DayBottomColor, _DayTopColor, saturate(i.uv.y));
                float3 gradientNight = lerp(_NightBottomColor, _NightTopColor, saturate(i.uv.y));
                float3 skyGradient = lerp(gradientNight, gradientDay, saturate(_WorldSpaceLightPos0.y));

                float3 combined = float3(0, 0, 0);
                combined += sunAndMoon + skyGradient + horizonDayColor;
                // return float4(_WorldSpaceLightPos0.xyz, 1);
                // return float4(horizonGlow, horizonGlow, horizonGlow, 1);
                return float4(combined, 1);

            }
            ENDCG
        }
    }
}
