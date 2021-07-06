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
        _NormalCuttoff("Normal Cut off", Range(0, 1)) = 0.1
        _SparkleNoise("Sparkle Noise", 2D) = "" {}
        _SparkleScale("SparkScale", Range(0, 10)) = 1
        _SparkleCutoff("Spark Cut Off", Range(0, 1)) = 0.1

        _Mask("Mask", 2D) = "" {}

        _SnowDepth("Snow Depth", Range(-10, 10)) = 0.5
        _SnowColor("Snow Color", Color) = (0.5,0.5,0.5,1)
        _SnowPathColor("Path color", Color) = (0.5,0.5,0.7,1)
        

        [Header(Tess setting)]
        _Tess("Tess Amount", Range(0, 64)) = 1
        _MaxTessDistance("Max Tess Distance", Range(0, 100)) = 1

        [Header(Rim setting)]
        _RimPower("Rim Power", Range(0,20)) = 20
		_RimColor("Rim Color Snow", Color) = (0.5,0.5,0.5,1)

        [Header(Addtion setting)]
        _SnowNightColor("Snow Night Color", Color) = (1,1,1,1)
        _EdgeColor("Snow Edge Color", Color) = (0.5,0.5,0.5,1)
        _Edgewidth("Snow Edge Width", Range(0,0.2)) = 0.1
        _BaseTexture("Base Texture", 2D) = "" {}
        _DaySnowInsensity("Snow Insensity", Range(0, 1)) = 1
    }
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"

    #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION
    #pragma multi_compile _ LIGHTMAP_ON
    #pragma multi_compile _ DIRLIGHTMAP_COMBINED
    #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
    #pragma multi_compile _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
    #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
    #pragma multi_compile _ _SHADOWS_SOFT
    #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
    #pragma multi_compile _ SHADOWS_SHADOWMASK

    struct Varyings
    {		
        float3 worldPos : TEXCOORD1; // world position built-in value				
        float4 color : COLOR;
        float3 normal : NORMAL;
        float4 vertex : SV_POSITION;
        float2 uv : TEXCOORD0;
        float4 screenPos : TEXCOORD2;
        float3 viewDir : TEXCOORD3;
        float fogFactor : TEXCOORD5;
        float4 shadowCoord : TEXCOORD7;
        float3 planeNormal : NORMAL1;
    };

    struct Attributes
    {
        float4 vertex : POSITION;
        float3 normal : NORMAL;
        float2 uv : TEXCOORD0;
        float4 color : COLOR; 
    };


    uniform float3 _Position;
    uniform sampler2D _GlobalEffectRT;
    uniform float _OrthographicCamSize;

    // snow base
    sampler2D _SnowNoise;
    sampler2D _SnowTex;

    float _SnowHeight; 
    float _SnowNoiseScale;
    float _SnowTexScale;
    float _SnowNoiseWeight;
    float _SnowDepth;
    float _SnowTextureOpacity;
    sampler2D _Mask;

    #include "SnowTessellation.hlsl"
    #include "../Tools/MathTools.hlsl"
    ControlPoint tessVert(Attributes v)
    {
        ControlPoint output;
        output.vertex = v.vertex;
        output.uv = v.uv;
        output.color = v.color;
        output.normal = v.normal;

        return output;
    }

    #pragma require tessellation tessHW
    #pragma vertex tessVert
    #pragma hull hull
    #pragma domain domain
    
    ENDHLSL
    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque" 
            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100
        ZWrite On

        

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            HLSLPROGRAM
            // make fog work c 
            #pragma multi_compile_fog
            #pragma fragment frag

            //snow path
            float4 _SnowPathColor;
            float4 _SnowColor;

            // snow trail
            float4 _SnowNightColor;

            float _Edgewidth;
            float4 _EdgeColor;
            float _SparkleScale;
            float _SparkleCutoff;

            sampler2D _BaseTexture;
            sampler2D _SparkleNoise;

            // rim
            float _RimPower;
            float4 _RimColor;
            float _DaySnowInsensity;

            


            float4 frag(Varyings v) : SV_TARGET
            {
                float2 uv = v.worldPos.xz - _Position.xz; // render-texture的uv坐标
                uv = uv / (_OrthographicCamSize * 2);
                uv += 0.5;

                float4 effect = tex2D(_GlobalEffectRT, uv);
                float mask = tex2D(_Mask, uv).a;
                effect *= mask;

                float3 topdownNoise = tex2D(_SnowNoise, v.worldPos.xz * _SnowNoiseScale).rgb;
                float vertexColoredPrimary = step(0.6 * topdownNoise,v.color.r).r;
                float snowTex = tex2D(_SnowTex, v.worldPos.xz * _SnowTexScale).rgb;
                float3 snowTexRes = snowTex * vertexColoredPrimary;

                //for edge
                float vertexColorEdge = ((step((0.6 - _Edgewidth) * topdownNoise, v.color.r)) * (1 - vertexColoredPrimary)).r;
                float3 baseTexture = tex2D(_BaseTexture, v.worldPos.xz).rgb;
                float3 baseTextureResult = baseTexture * (1 - (vertexColoredPrimary + vertexColorEdge));

                float3 maincolorDay = snowTexRes * _SnowTextureOpacity + _SnowColor;
                float3 maincolorNight = snowTexRes * _SnowTextureOpacity + _SnowNightColor;
                // float shadow = SHADOW_ATTENUATION(v);
                float NdotL = saturate(dot(v.planeNormal, _MainLightPosition));
                float NdotLNagetive = dot(v.planeNormal, -_MainLightPosition);
                maincolorDay = lerp(maincolorDay, _SnowPathColor * effect.g * 2, saturate(effect.g * 3)).rgb;
                maincolorNight = lerp(maincolorNight, _SnowPathColor * effect.g * 2, saturate(effect.g * 3)).rgb;

                // add shadow
                float4 shadowCoord = TransformWorldToShadowCoord(v.worldPos);
                #if _MAIN_LIGHT_SHADOWS_CASCADE || _MAIN_LIGHT_SHADOWS
                    Light mainLight = GetMainLight(shadowCoord);
				#else
                    Light mainLight = GetMainLight();
				#endif

                float shadows = mainLight.shadowAttenuation;

                // float4 litMainColors = float4(maincolorDay, 1) * saturate(NdotL) + float4(maincolorNight, 1) * saturate(smoothstep(-0.5, 0.5, NdotLNagetive));
                // float4 litMainColors = float4(maincolorDay, 1) * shadows * (NdotL + 0.2 * cubicPulse(0.02, 0.5, NdotL)) + float4(baseTextureResult, 1);
                float4 litMainColors = float4(maincolorDay, 1) * shadows * saturate(NdotL + 0.2 * (1 - step(0.5, NdotL))) + float4(baseTextureResult, 1);
                // sparles
                float sparklesStatic = tex2D(_SparkleNoise, v.worldPos.xz * _SparkleScale * 5).r;
                float sparklesRes = tex2D(_SparkleNoise, (v.worldPos.xz + v.screenPos) * _SparkleScale) * sparklesStatic;
                litMainColors += step(_SparkleCutoff, sparklesRes);
                // rim
                float rim = 1.0 - dot((v.viewDir), v.normal);
                litMainColors += vertexColoredPrimary * _RimColor * pow(rim, _RimPower);

                float4 extraColors;
                extraColors.rgb = litMainColors * mainLight.color.rgb * (shadows + unity_AmbientSky);
                extraColors.a = 1;
                // return float4(shadows, shadows, shadows, 1);
                float4 finalColors = litMainColors + float4(maincolorNight, 1) * saturate(smoothstep(-0.5, 0.5, NdotLNagetive));

                return finalColors + unity_AmbientSky;
            }

            ENDHLSL
        }

        Pass
        {

            Tags{ "LightMode" = "ShadowCaster" }

            ZWrite Off
            ZTest LEqual

            HLSLPROGRAM
            #pragma fragment frag

            half4 frag(Varyings IN) : SV_Target
            {
                return 0;
            }

            ENDHLSL
        }

        
    }
    Fallback off
}
