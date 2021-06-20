Shader "Saltsuica/MySkyBox"
{
    Properties
    {

        _BaseNoise("Base Noise", 2D) = "" {}
        _BaseNoiseScale("Base Noise Scale", Range(0, 1)) = 0.2

        [Header(Sun Settings)]
        _SunColor("Sun Color", Color) = (1,1,1,1)
		_SunRadius("Sun Radius",  Range(0, 2)) = 0.1
        _VerticalOffset("Vertical offset", Range(-2, 2)) = 0

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

        [Header(Stars Settings)]
        _StarsTex ("_Stars", 2D) = "white" {}
        _StarsCutoff("Stars Cutoff", Range(0, 1)) = 0.1
        _StarsSkyColor("Stars Sky Color", Color) = (0.0,0.2,0.1,1)
        _StarsScale("Stars Scale", Range(0, 1)) = 0.5
        _StarsSpeed("Stars Speed", Range(0, 1)) = 0.5

        [Header(Horizon Settings)]
        _HorizonColorDay("Horizon Day Color", Color) = (1,1,1,1)
        _HorizonColorNight("Horizon Night Color", Color) = (1,1,1,1)
        _HorizonIntensity("HorizonIntensity", range(0, 20)) = 0.1
        _HorizonOffset("HorizonOffset", range(-1, 1)) = 0.1

        [Header(Cloud Settings)]
        _CloudScrollSpeed("Cloud Scroll Speed", Range(0, 10)) = 1.4
        _DistortTex("Cloud Distort Noise", 2D) = "" {}
        _SecNoiseTex("Second Noise", 2D) = "" {}
        _DistortScale("Distort Noise Scale",  Range(0, 1)) = 0.06
		_SecNoiseScale("Secondary Noise Scale",  Range(0, 1)) = 0.05
		_Distortion("Extra Distortion",  Range(0, 1)) = 0.1
        _CloudCutoff("Cloud Cut Off", Range(0,1)) = 0.3
        _Fuzziness("Fuzziness", Range(0, 1)) = 0.3
        _FuzzinessUnder("FuzzinessUnder", Range(0, 1)) = 0.3

        [Header(CloudDay Settings)]
        _CloudColorDayEdge("Day Edge", Color) = (1,1,1,1)
        _CloudColorDayMain("Day Main", Color) = (1,1,1,1)
        _CloudColorNightMain("Night Main", Color) = (1,1,1,1)

        
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
                float3 worldPos : TEXCOORD1;
            };

            sampler2D _StarsTex;
            sampler2D _BaseNoise;
            sampler2D _DistortTex;
            sampler2D _SecNoiseTex;
            float _BaseNoiseScale;
            float _StarsCutoff;

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
            float4 _StarsSkyColor;
            float _StarsScale;
            float _StarsSpeed;

            float _DistortScale;
            float _Distortion;
            float _SecNoiseScale;
            float _CloudScrollSpeed;
            float _CloudCutoff;
            float _Fuzziness;
            float _FuzzinessUnder;

            float4 _CloudColorDayEdge;
            float4 _CloudColorDayMain;
            float4 _CloudColorNightMain;

            float _VerticalOffset;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
            float parabola( float x, float k )
            {
                return pow( 4.0*x*(1.0-x), k );
            }

            fixed4 frag (v2f i) : SV_Target
            {

                // get horizon :  close to 0 mean close to horizon
                float horizon = abs((i.uv.y * _HorizonIntensity) - _HorizonOffset);
                
                // common
                float2 skyUV = i.worldPos.xz / i.worldPos.y;
                float baseNoise = tex2D(_BaseNoise, (skyUV - _Time.x) * _BaseNoiseScale).x;

                //TODO : 太阳颜色应该随着太阳高度角而变化
                float3 celestialDir = float3(i.uv.x, i.uv.y+_VerticalOffset, i.uv.z);
                // float3 celestialDir1 = float3(i.uv.x-0.2, i.uv.y+_VerticalOffset, i.uv.z);
                // float3 celestialDir2 = float3(i.uv.x+0.2, i.uv.y+_VerticalOffset, i.uv.z);
                // float3 celestialDir3 = float3(i.uv.x+0.4, i.uv.y+_VerticalOffset, i.uv.z);
                celestialDir = normalize(celestialDir);//不归一化天体会变形
                float sunDist = distance(celestialDir, _WorldSpaceLightPos0);
                float moonDist = distance(celestialDir, -_WorldSpaceLightPos0);
                float sun  = 1 - saturate(sunDist / _SunRadius);

                // 四日凌空的沙雕东西
                // float sunDist2 = distance(normalize(celestialDir1), _WorldSpaceLightPos0);
                // float sun2 = 1 - saturate(sunDist2 / _SunRadius);
                // float sunDist3 = distance(normalize(celestialDir2), _WorldSpaceLightPos0);
                // float sun3 = 1 - saturate(sunDist3 / _SunRadius);
                // float sunDist4 = distance(normalize(celestialDir3), _WorldSpaceLightPos0);
                // float sun4 = 1 - saturate(sunDist4 / _SunRadius);

                // sun = saturate(sun * 50);

                float moon = 1 - (moonDist / _MoonRadius);
                moon = saturate(moon * 50);
                float crescentMoonDist = distance(float3(celestialDir.x + _MoonOffset, celestialDir.yz), -_WorldSpaceLightPos0);

                float crescentMoon = 1 - (crescentMoonDist / _MoonRadius);
                crescentMoon = saturate(crescentMoon * 30);
                moon = saturate(moon - crescentMoon);
                float3 sunAndMoon = (sun * _SunColor) + (moon * _MoonColor);

                // star
                float3 stars = tex2D(_StarsTex, (skyUV + _Time.x * _StarsSpeed));
                stars *= saturate(-_WorldSpaceLightPos0.y); // make sure start only appear at night
                stars = step(_StarsCutoff, stars);
                stars += (baseNoise * _StarsSkyColor);

                // gradient sky color
                float3 gradientDay = lerp(_DayBottomColor, _DayTopColor, saturate(i.uv.y));
                float3 gradientNight = lerp(_NightBottomColor, _NightTopColor, saturate(i.uv.y));
                float3 skyGradient = lerp(gradientNight, gradientDay, saturate(_WorldSpaceLightPos0.y));

                // sun set /rise /horizon glow
                //TODO: what is horizon glow
                // get horizonDay color
				float3 horizonGlow = saturate((1 - horizon * 5) * saturate(parabola(_WorldSpaceLightPos0.y * 5, 1.0))) * _HorizonColorDay;// 
				float3 horizonGlowNight = saturate((1 - horizon * 5) * saturate(parabola(-_WorldSpaceLightPos0.y * 4, 1.0))) * _HorizonColorNight;//
				horizonGlow += horizonGlowNight;

                // for sun set
                float sunset = saturate((1 - horizon)) * saturate(parabola(_WorldSpaceLightPos0.y * 2, 1.0));
                float3 sunsetColor = sunset * _SunSetColor;

                //cloud
                float noise1 = tex2D(_DistortTex, ((skyUV + baseNoise) - (_Time.x * _CloudScrollSpeed)) * _DistortScale);
                float noise2 = tex2D(_SecNoiseTex, (skyUV + (noise1 * _Distortion) -(_Time.x * _CloudScrollSpeed * 0.5)) * _SecNoiseScale);
                float finalNoise = saturate(noise1 * noise2) * 2.3 * saturate(i.worldPos.y);

				float clouds = saturate(smoothstep(_CloudCutoff, _CloudCutoff + _Fuzziness, finalNoise));
                float cloudsNagetive = 1 - clouds;

				float cloudsunder = saturate(smoothstep(_CloudCutoff, _CloudCutoff + _Fuzziness + _FuzzinessUnder , noise2) * clouds);

                float4 cloudDayColor = lerp(float4(skyGradient, 1), _CloudColorDayMain, clouds) * clouds; // mul clouds only the cloud will show color
                float4 cloudNightColor = lerp(float4(skyGradient, 1), _CloudColorNightMain, clouds) * clouds;

                float4 cloudsColor = lerp(cloudNightColor, cloudDayColor, saturate(_WorldSpaceLightPos0.y));

                float3 combined = float3(0, 0, 0);
                sunAndMoon *= cloudsNagetive;
                stars *= cloudsNagetive;
                combined += sunAndMoon + skyGradient + stars + cloudsColor + sunsetColor + horizonGlow;
                UNITY_APPLY_FOG(i.fogCoord, combined);
                // return float4(sun2, sun2, sun2, 1);
                // return float4(horizonGlow, 1);
                return float4(combined, 1);

            }
            ENDCG
        }
    }
}
