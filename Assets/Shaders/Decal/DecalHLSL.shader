Shader "Unlit/DecalHLSL"
{
    Properties
    {
    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="Transparent"
            "RenderPipeline"="UniversalPipeline"
        }
        ZWrite On
		Blend SrcAlpha OneMinusSrcAlpha

        // uncomment to have selective decals
		// Stencil {
        //     Ref 5
        //     Comp Equal
        //     Fail zero
		// }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD;
                float4 screenUV : TEXCOORD1;
                float3 ray : TEXCOORD2;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.texcoord;
                OUT.screenUV = ComputeScreenPos(OUT.positionHCS);
                // float3(1,1,-1) 是交换左右手系的z轴
                //ray 记录了以摄像机为原点，到该顶点的方向
                OUT.ray = TransformWorldToView(TransformObjectToWorld(IN.positionOS)) * float3(1, 1, -1);
                return OUT;
            }

            UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(sampler2D, _MainTex)
            UNITY_DEFINE_INSTANCED_PROP(float4, _Tint)
            UNITY_INSTANCING_BUFFER_END(Props)

            half4 frag(Varyings i) : SV_Target
            {
                // 顶点着色器中，记录了顶点在观察空间的关系，通过深度采样，射线乘上深度后，即可得到当前像素对应在观察空间中的位置
                
                float2 uv = i.screenUV.xy / i.screenUV.w;
                float depth = SampleSceneDepth(uv);
                // 0 camera pos, 1 far plane
                depth = Linear01Depth(depth, _ZBufferParams);
                
                i.ray = i.ray * (_ProjectionParams.z / i.ray.z);
                float4 posVS = float4(i.ray * depth, 1);
                float4 posWS = mul(unity_CameraToWorld, posVS);
                float3 posOS = TransformWorldToObject(posWS).xyz;

                // decal用了一个cube mesh, 标准正方体，这里是将超出正方体的贴图输出给截断掉
                clip(float3(0.5, 0.5, 0.5) - abs(posOS.xyz));

                // 将原点挪回正方体的左下角
                i.uv = posOS.xz + 0.5;

                float4 col = tex2D(UNITY_ACCESS_INSTANCED_PROP(Props, _MainTex), i.uv);
                clip(col.a - 0.1);
                col *= col.a;
                return col;

            }
            ENDHLSL
        }
    }
}
