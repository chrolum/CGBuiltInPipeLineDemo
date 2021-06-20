Shader "Saltsuica/Grass"
{
    Properties
    {
		[Header(Shading)]
		_TopColor("Top Color", Color) = (1,1,1,1)
		_BottomColor("Bottom Color", Color) = (1,1,1,1)
		_TranslucentGain("Translucent Gain", Range(0,1)) = 0.5
		_BendRotationRandom("Bend Rotation Random", Range(0, 1)) = 0.2

		_BladeWidth("Blade Width", Range(0, 1)) = 0.05
		_BladeWidthRandom("Blade Width Random", Range(0, 1)) = 0.02
		_BladeHeight("Blade Height", Range(0, 3)) = 0.5
		_BladeHeightRandom("Blade Height Random", Range(0, 1)) = 0.3

		_TessellationUniform("Tessellation Uniform", Range(1, 16)) = 1

		_WindDistortionMap("Wind Distortion Map", 2D) = "white" {}
		_WindFrequency("Wind Frequency", Vector) = (0.05, 0.05, 0, 0)
		_WindStrength("Wind Strength", Range(0.01, 2)) = 1

		_BladeForward("Blade Forward Amount", Range(0, 2)) = 0.38
		_BladeCurve("Blade Curvature Amount", Range(1, 4)) = 2
    }

	CGINCLUDE
	#include "UnityCG.cginc"
	#include "Autolight.cginc"
	#include "../CustomTessellation.cginc"

	#define BLADE_SEGMENTS 10

	struct geometryOutput	
	{
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		unityShadowCoord4 _ShadowCoord : TEXCOORD1;
		float3 normal : NORMAL;
	};

	// struct vertexInput
	// {
	// 	float4 vertex : POSITION;
	// 	float3 normal: NORMAL;
	// 	float4 tangent: TANGENT;
	// };

	// struct vertexOutput
	// {
	// 	float4 vertex : SV_POSITION;
	// 	float3 normal : NORMAL;
	// 	float4 tangent : TANGENT;
	// };

	geometryOutput VertexOutput(float3 pos, float2 uv, float3 normal)
	{
		geometryOutput o;
		o.pos = UnityObjectToClipPos(pos); //NDC空间
		o.uv = uv;
		o._ShadowCoord = ComputeScreenPos(o.pos);//在shadow pass生成深度图后，需要计算顶点在屏幕空间的坐标方便采样
		o.normal = UnityObjectToWorldNormal(normal);
		#if UNITY_PASS_SHADOWCASTER
			o.pos = UnityApplyLinearShadowBias(o.pos);
		#endif
		return o; 
	}

	// Simple noise function, sourced from http://answers.unity.com/answers/624136/view.html
	// Extended discussion on this function can be found at the following link:
	// https://forum.unity.com/threads/am-i-over-complicating-this-random-function.454887/#post-2949326
	// Returns a number in the 0...1 range.
	float rand(float3 co)
	{
		return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
	}

	// Construct a rotation matrix that rotates around the provided axis, sourced from:
	// https://gist.github.com/keijiro/ee439d5e7388f3aafc5296005c8c3f33
	float3x3 AngleAxis3x3(float angle, float3 axis)
	{
		float c, s;
		sincos(angle, s, c);

		float t = 1 - c;
		float x = axis.x;
		float y = axis.y;
		float z = axis.z;

		return float3x3(
			t * x * x + c, t * x * y - s * z, t * x * z + s * y,
			t * x * y + s * z, t * y * y + c, t * y * z - s * x,
			t * x * z - s * y, t * y * z + s * x, t * z * z + c
			);
	}

	float _BendRotationRandom;
	float _BladeWidth;
	float _BladeWidthRandom;
	float _BladeHeight;
	float _BladeHeightRandom;

	sampler2D _WindDistortionMap;
	float4 _WindDistortionMap_ST;
	float2 _WindFrequency;
	float _WindStrength;

	float _BladeForward;
	float _BladeCurve;

	geometryOutput GenerateGrassVertex(float3 vertexPos, float x, float y,
		float z, float2 uv, float3x3 transformation, float forward)
	{
		float3 tangentPos = float3(x, y, z);
		float3 localPos = vertexPos + mul(transformation, tangentPos);
		float3 tangentNormal = normalize(float3(0, -1, forward)); //why the normal vertex is(0, -1, 0)
		float3 localNormal = mul(transformation, tangentNormal);
		return VertexOutput(localPos, uv, localNormal);
	}
	// create a geometry shader
	// [maxvertexcount(3)] 
	[maxvertexcount(BLADE_SEGMENTS * 2 + 1)] 
	void geo(triangle vertexOutput IN[3], inout TriangleStream<geometryOutput> triStream)
	{
		geometryOutput o;
		float3 pos = IN[0].vertex;

		float3 vNormal = IN[0].normal; //up (0,0,1)
		float4 vTangent = IN[0].tangent; // RIGHT (1, 0, 0)
		float3 vBinormal = cross(vNormal, vTangent) * vTangent.w; //foward (0, 1, 0)

		float3x3 tangentToLocal = float3x3(
			vTangent.x, vBinormal.x, vNormal.x,
			vTangent.y, vBinormal.y, vNormal.y,
			vTangent.z, vBinormal.z, vNormal.z
			);
		// float3x3 tangentToLocal = float3x3(
		// 	vTangent.x, vNormal.x, vBinormal.x,
		// 	vTangent.y, vNormal.y, vBinormal.y,
		// 	vTangent.z, vNormal.z, vBinormal.z
		// 	); // 把向上方向定义在y轴

		float2 uv = pos.xz * _WindDistortionMap_ST.xy +
			_WindDistortionMap_ST.zw + _WindFrequency * _Time.y;// 根据自身位置和游戏时间生成采样的uv

		//rescale uv range to -1...1
		float2 windSample = (tex2Dlod(_WindDistortionMap, float4(uv, 0,0) * 2 - 1)) * _WindStrength;

		float3 windDir = normalize(float3(windSample.x, windSample.y, 0));//实际上是绕风旋转轴
		// 采样角度乘上0.5 防止草被吹到地下
		// 使用旋转实现的风吹效果是不正确的，整片草都会旋转
		// 正确的效果应该是草的根部不动
		float3x3 windRotation = AngleAxis3x3(UNITY_PI * windSample, windDir);

		float3x3 facingRotationMatrix = AngleAxis3x3(rand(pos) * UNITY_TWO_PI, float3(0, 0, 1));
		float3x3 bendRotationMatrix = AngleAxis3x3(rand(pos.zzx) * _BendRotationRandom * UNITY_PI * 0.5, float3(1, 0, 0));

		//草的顶点单独应用风变换
		float3x3 windTrans = mul(tangentToLocal, windRotation);
		float3x3 facingTrans = mul(tangentToLocal, facingRotationMatrix);
		windTrans = mul(windTrans, facingRotationMatrix);
		windTrans = mul(windTrans, bendRotationMatrix);	

		float height =abs((rand(pos.zyx) * 2 - 1)) * _BladeHeightRandom + _BladeHeight;
		float width = abs((rand(pos.xyz) * 2 - 1)) * _BladeWidthRandom + _BladeWidth;
		float forward = rand(pos.yyz) * _BladeForward;

		for (int i = 0; i < BLADE_SEGMENTS; i++)
		{
			float t = i / (float)BLADE_SEGMENTS;
			float segmentWidth = width * (1-t);
			float segmentHeigth = height * t;
			float segmentForward = forward * pow(t, _BladeCurve);//why pow
			float3x3 trans = i == 0 ? facingTrans : windTrans;
			triStream.Append(GenerateGrassVertex(pos, segmentWidth, segmentForward, segmentHeigth, float2(0, t), trans, segmentForward));
			triStream.Append(GenerateGrassVertex(pos, -segmentWidth, segmentForward, segmentHeigth, float2(1, t), trans, segmentForward));
		}

		triStream.Append(GenerateGrassVertex(pos, 0, forward, height, float2(0.5, 1), windTrans, forward));

		// o.pos = UnityObjectToClipPos(pos + float4(0.5, 0, 0, 1));
		// triStream.Append(o);
		// o.pos = UnityObjectToClipPos(pos + float4(-0.5, 0, 0, 1));
		// triStream.Append(o);
		// o.pos = UnityObjectToClipPos(pos + float4(0, 1, 0, 1));
		// triStream.Append(o);
	}

	



	// vertexOutput vert(vertexInput v)
	// {
	// 	// return UnityObjectToClipPos(vertex);// 这里已经把顶点输出到裁剪空间了
	// 	// return vertex;
	// 	vertexOutput o;
	// 	o.vertex = v.vertex;
	// 	o.normal = v.normal;
	// 	o.tangent = v.tangent;
	// 	return o;
	// }
	ENDCG

    SubShader
    {
		Cull Off

        Pass
        {
			Tags
			{
				"RenderType" = "Opaque"
				"LightMode" = "ForwardBase"
			}

            CGPROGRAM
            #pragma vertex vert
			#pragma geometry geo
            #pragma fragment frag
			#pragma hull hull
			#pragma domain domain
			#pragma target 4.6
			#pragma multi_compile_fwdbase
             
			#include "Lighting.cginc"


			float4 _TopColor;
			float4 _BottomColor;
			float _TranslucentGain;

			float4 frag (geometryOutput i, fixed facing : VFACE) : SV_Target
            {	
				float3 normal = facing > 0 ? i.normal : -i.normal;
				float shadow = SHADOW_ATTENUATION(i);
				float NdotL = saturate(saturate(dot(normal, _WorldSpaceLightPos0)) + _TranslucentGain) * shadow;

				float3 ambient = ShadeSH9(float4(normal, 1));
				float4 lightIntensity = NdotL * _LightColor0 + float4(ambient, 1);
				float4 col = lerp(_BottomColor, _TopColor, i.uv.y);

				return col * lightIntensity;
				// return visibility;
				// return visibility * lerp(_BottomColor, _TopColor, i.uv.y);
				// return lerp(_BottomColor, _TopColor, i.uv.y); //定义一个底部颜色和顶部颜色，更具uv的v来线性插值出颜色
            }
            ENDCG
        }

		// 需要一个shadow pass 计算一次shadow map, 以便草采样阴影
		pass
		{
			Tags
			{
				"LightMode" = "ShadowCaster"
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geo
			#pragma fragment frag
			#pragma hull hull
			#pragma domain domain
			#pragma target 4.6
			#pragma multi_compile_shadowcaster

			float4 frag(geometryOutput i) : SV_TARGET
			{
				SHADOW_CASTER_FRAGMENT(i);
			}

			ENDCG
		}
    }
}