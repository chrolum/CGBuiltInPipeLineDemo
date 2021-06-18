Shader "Saltsuica/MySkyBox"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        [Header(Sun Settings)]
		 _SunColor("Sun Color", Color) = (1,1,1,1)
		_SunRadius("Sun Radius",  Range(0, 2)) = 0.1

        [Header(Moon Settings)]
        _MoonColor("Moon Color", Color) = (1,1,1,1)
		_MoonRadius("Moon Radius",  Range(0, 2)) = 0.1
        //TODO: 优化offet滑条[-1,1]表示两个满月的月相
        _MoonOffset("Moon Offset", Range(-2, 2)) = 0.1

        [Header(SunSet Settings)]
        _SunSetColor("Sun Set Color", Color) = (1,1,1,1)

        [Header(Sky Settings)]
        _DayTopColor("Day Top Color", Color) = (1,1,1,1)
        _DayBottomColor("Day Bottome Color", Color) = (1,1,1,1)
        _NightTopColor("Night Top Color", Color) = (1,1,1,1)
        _NightBottomColor("Night Bottom Color", Color) = (1,1,1,1)


        [Header(Horizon Settings)]
        _HorizonColorDay("Horizon Day Color", Color) = (1,1,1,1)
        _HorizonColorNight("Horizon Night Color", Color) = (1,1,1,1)
        _HorizonIntensity("HorizonIntensity", range(0, 20)) = 0.1
        _HorizonOffset("HorizonOffset", range(-1, 1)) = 0.1
        
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
            #pragma shader_feature FUZZY

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
            float4 _HorizonColorNight;
            float4 _SunSetColor;
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

                // get horizon :  close to 0 mean close to horizon
                float horizon = abs((i.uv.y * _HorizonIntensity) - _HorizonOffset);

                float sunDist = distance(i.uv.xyz, _WorldSpaceLightPos0);
                float moonDist = distance(i.uv.xyz, -_WorldSpaceLightPos0);
                // float sun = 1 - saturate(sunDist / _SunRadius);
                float sun  = 1 - (sunDist / _SunRadius);
                sun = saturate(sun * 50);
                // fuzzy color for moon
                // float moon = 1 - saturate(moonDist / _MoonRadius);
                // solid moon color
                // float moon = 1- step(_MoonRadius, moonDist);
                float moon = 1 - (moonDist / _MoonRadius);
                moon = saturate(moon * 50);
                float crescentMoonDist = distance(float3(i.uv.x + _MoonOffset, i.uv.yz), -_WorldSpaceLightPos0);

                
                // float crescentMoon = 1 - step(_MoonRadius, crescentMoonDist);
                float crescentMoon = 1 - (crescentMoonDist / _MoonRadius);
                crescentMoon = saturate(crescentMoon * 50);
                moon = saturate(moon - crescentMoon);
                float3 sunAndMoon = (sun * _SunColor) + (moon * _MoonColor);

                // gradient sky color
                float3 gradientDay = lerp(_DayBottomColor, _DayTopColor, saturate(horizon));
                float3 gradientNight = lerp(_NightBottomColor, _NightTopColor, saturate(horizon));
                float3 skyGradient = lerp(gradientNight, gradientDay, saturate(_WorldSpaceLightPos0.y));

                
                // sun set /rise /horizon glow
                //TODO: what is horizon glow
                // get horizonDay color
                float3 horizonGlow = saturate((1-horizon * 5) * saturate(_WorldSpaceLightPos0.y * 10)) * _HorizonColorDay;
                float3 horizonGlowNight = saturate((1-horizon * 5) * saturate(-_WorldSpaceLightPos0.y * 10)) * _HorizonColorNight;
                horizonGlow += horizonGlowNight;

                // for sun set
                float sunset = saturate((1-horizon)) * saturate(_WorldSpaceLightPos0.y * 5);
                float3 sunsetColor = sunset * _SunSetColor;

                float3 combined = float3(0, 0, 0);
                combined += sunAndMoon + skyGradient + horizonGlow + sunsetColor;
                // return float4(_WorldSpaceLightPos0.xyz, 1);
                // return float4(horizonGlow, horizonGlow, horizonGlow, 1);
                UNITY_APPLY_FOG(i.fogCoord, combined);
                return float4(combined, 1);

            }
            ENDCG
        }
    }
}
