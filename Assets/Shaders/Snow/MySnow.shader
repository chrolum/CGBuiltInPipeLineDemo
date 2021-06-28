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

        [Header(Addtion setting)]
        _SnowNightColor("Snow Night Color", Color) = (1,1,1,1)
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

            


            float4 frag(Varyings v) : SV_TARGET
            {
                float2 uv = v.worldPos.xz - _Position.xz; // render-texture的uv坐标
                uv = uv / (_OrthographicCamSize * 2);
                uv += 0.5;

                float4 effect = tex2D(_GlobalEffectRT, uv);
                float mask = tex2D(_Mask, uv).a;
                effect *= mask;

                float3 topdownNoise = tex2D(_SnowNoise, v.worldPos.xz * _SnowNoiseScale).rgb;
                float3 snowTexRes = tex2D(_SnowTex, v.worldPos.xz * _SnowTexScale).rgb;

                float3 maincolorDay = snowTexRes * _SnowTextureOpacity + _SnowColor;
                float3 maincolorNight = snowTexRes * _SnowTextureOpacity + _SnowNightColor;
                // float shadow = SHADOW_ATTENUATION(v);
                float NdotL = saturate(saturate(dot(v.normal, _MainLightPosition)));
                float NdotLNagetive = dot(v.normal, -_MainLightPosition);
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
                // return float4(shadows, shadows, shadows, 1);
                
                // return float4(shadows, shadows, shadows, 1);

                return float4(maincolorDay, 1) * saturate(NdotL) + float4(maincolorNight, 1) * smoothstep(-0.5, 0.5, NdotLNagetive);
                // return float4(maincolorDay, 1) * saturate(NdotL);
            }

            ENDHLSL
        }

        // Pass
        // {

        //     Tags{ "LightMode" = "ShadowCaster" }

        //     ZWrite On
        //     ZTest LEqual

        //     HLSLPROGRAM
        //     #pragma fragment frag

        //     half4 frag(Varyings IN) : SV_Target
        //     {
        //         return 0;
        //     }

        //     ENDHLSL
        // }

        
    }
    Fallback off
}
