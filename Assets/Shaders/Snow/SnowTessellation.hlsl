#if defined(SHADER_API_D3D11) || defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE) || defined(SHADER_API_VULKAN) || defined(SHADER_API_METAL) || defined(SHADER_API_PSSL)
#define UNITY_CAN_COMPILE_TESSELLATION 1
#   define UNITY_domain                 domain
#   define UNITY_partitioning           partitioning
#   define UNITY_outputtopology         outputtopology
#   define UNITY_patchconstantfunc      patchconstantfunc
#   define UNITY_outputcontrolpoints    outputcontrolpoints
#endif

struct vertexInput
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
};


struct ControlPoint
{
    float4 vertex : INTERNALTESSPOS;
    float2 uv : TEXCOORD0;
    float4 color : COLOR;
    float3 normal : NORMAL;
  
};

struct TessellationFactors 
{
	float edge[3] : SV_TessFactor;
	float inside : SV_InsideTessFactor;
};

float _Tess;
float _MaxTessDistance;
float _NormalCuttoff;

float4 GetShadowPositionHClip(Attributes input)
{
    float3 positionWS = TransformObjectToWorld(input.vertex.xyz);
    float3 normalWS = TransformObjectToWorldNormal(input.normal);

    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, 0));
    
#if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
#else
    positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
#endif
    return positionCS;
}

Varyings vert(Attributes v)
{
    Varyings o;
    float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
    float snowNoise = tex2Dlod(_SnowNoise, float4(worldPos.xz * _SnowNoiseScale, 0,0));

    o.color = v.color;
    o.vertex = v.vertex;

    float2 uv = worldPos.xz - _Position.xz; // render-texture的uv坐标
    uv = uv / (_OrthographicCamSize * 2);
    uv += 0.5;

    float4 RTEffect = tex2Dlod(_GlobalEffectRT, float4(uv, 0, 0));
    float mask = tex2Dlod(_Mask, float4(uv, 0, 0)).a;
    RTEffect *= mask;

    // basic snow Bump
    v.vertex.xyz += normalize(v.normal) * _SnowHeight + snowNoise * _SnowNoiseWeight;

    // snow Snow marks
    // o.vertex.xyz -= normalize(v.normal) * _SnowDepth * radius;
    v.vertex.xyz -= normalize(v.normal) * RTEffect.g * _SnowDepth;

    // o.shadowCoord = TransformWorldToShadowCoord(mul(unity_ObjectToWorld, v.vertex));
    VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
    o.shadowCoord = GetShadowCoord(vertexInput);
    #ifdef SHADERPASS_SHADOWCASTER
        o.vertex = GetShadowPositionHClip(v);
    #else
        o.vertex = TransformObjectToHClip(v.vertex.xyz);
        // or
        // o.vertex = vertexInput.positionCS; // clips space
    #endif
    o.worldPos = vertexInput.positionWS;
    // o.normal = saturate(v.normal * step(_NormalCuttoff, snowNoise * 0.4));
    o.planeNormal = v.normal;
    o.normal = saturate(v.normal * saturate(snowNoise - _NormalCuttoff) * 0.4);
    // o.normal = saturate(v.normal * (step(1-_NormalCuttoff, snowNoise)));
    o.normal.y += (RTEffect.g * 0.4);
    o.uv = uv;
    float4 clipvertex = o.vertex / o.vertex.w;
    o.screenPos = ComputeScreenPos(clipvertex);
    o.viewDir = normalize(_WorldSpaceCameraPos - v.vertex);
    return o;
}

[UNITY_domain("tri")]
[UNITY_outputcontrolpoints(3)]
[UNITY_outputtopology("triangle_cw")]
[UNITY_partitioning("integer")]
[UNITY_patchconstantfunc("patchConstantFunction")]
ControlPoint hull(InputPatch<ControlPoint, 3> patch, uint id : SV_OUTPUTCONTROLPOINTID)
{
    return patch[id];
}

// domain 阶段已经生成了细分后的网格了，但是此时在渲染管线中，已经离开了顶点着色的阶段，因此顶点形变的逻辑要下放到domain阶段中来
// 顶点着色阶段只需要把Attributes里的数据传进来即可
[UNITY_domain("tri")]
Varyings domain(TessellationFactors factors, OutputPatch<ControlPoint, 3> patch, float3 barycentricCoordinates : SV_DomainLocation)
{
    Attributes v;
    #define Tesselationing(fieldName) v.fieldName = \
		patch[0].fieldName * barycentricCoordinates.x + \
		patch[1].fieldName * barycentricCoordinates.y + \
		patch[2].fieldName * barycentricCoordinates.z;
     
	Tesselationing(vertex)
    Tesselationing(uv)
	Tesselationing(color)
	Tesselationing(normal)

    return vert(v);

}

// 根据顶点离摄像机的距离，动态决定网格细分的程度
// 被刷上红色顶点色的顶点将不进行顶点划分
float ColorCalcDistanceTessFactor(float4 vertex, float minDist, float maxDist, float tess, float4 color)
{
    float3 worldPosition = mul(unity_ObjectToWorld, vertex).xyz;
    // float dist = distance(worldPosition, _WorldSpaceCameraPos);
    float dist = distance(worldPosition, _Position);
    float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0);
  // no tessellation on no red vertex colors
    if (color.r < 0.1)
    {
        f = 0.01;
    }
   
    return f * tess;
}

TessellationFactors patchConstantFunction(InputPatch<ControlPoint, 3> patch)
{
    float minDist = 0.1;
    float maxDist = _MaxTessDistance;
    TessellationFactors f;

    float edge0 = ColorCalcDistanceTessFactor(patch[0].vertex, minDist, maxDist, _Tess, patch[0].color);
    float edge1 = ColorCalcDistanceTessFactor(patch[1].vertex, minDist, maxDist, _Tess, patch[1].color);
    float edge2 = ColorCalcDistanceTessFactor(patch[2].vertex, minDist, maxDist, _Tess, patch[2].color);

    // TODO : why
    f.edge[0] = (edge1 + edge2) / 2;
    f.edge[1] = (edge0 + edge2) / 2;    
    f.edge[2] = (edge1 + edge0) / 2;
    f.inside = (edge0 + edge1 + edge2) / 3;

    return f;
}



