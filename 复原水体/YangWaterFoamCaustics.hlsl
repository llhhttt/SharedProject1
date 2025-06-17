#ifndef YANGWATERFOAMCAUSTICS
#define YANGWATERFOAMCAUSTICS


#include"Assets/Shader/YangWaterStruct.hlsl"
#include"Assets/Shader/MyWaterStruct.hlsl"

half FoamMask(WaterVaryings output,WaterLightData light)
{
    half2 screenUV = light.screenUV;
    half3 worldViewDir = normalize(light.viewDirWS);
    half worldViewDirY = abs(worldViewDir.y);

   half depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV), _ZBufferParams);

    depth = depth - output.positionSS.z;

    half2 deltaUV = light.normalWS.xz * _WaterDistortScale * saturate(depth) * worldViewDirY / output.positionSS.z;


    half newDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV + deltaUV), _ZBufferParams);

    newDepth = newDepth - output.positionSS.z;

    half signDepth = saturate(newDepth * 10);
    //depth = lerp(depth, newDepth, signDepth);

    half viewAlphaMultiplier = pow((worldViewDirY + _WaterAlphaScale) * _WaterAlphaDepth * _WaterAlphaDepth, _FoamWaveMaskExp);
    half AlphaDepth = depth * viewAlphaMultiplier;
    AlphaDepth = 1 - saturate(AlphaDepth);
    return depth;
}


float2 randomVec(float2 uv)
{
	float vec = dot(uv, float2(127.1, 311.7));
	return -1.0 + 2.0 * frac(sin(vec) * 43758.5453123);
}

//生成perlin噪声
float perlinNoise(float2 uv) 
{				
	float2 pi = floor(uv);
	float2 pf = uv - pi;
	float2 w = pf * pf * (3.0 - 2.0 *  pf);
          	
	float2 lerp1 = lerp(
		dot(randomVec(pi + float2(0.0, 0.0)), pf - float2(0.0, 0.0)),
		dot(randomVec(pi + float2(1.0, 0.0)), pf - float2(1.0, 0.0)), w.x);
                     
	float2 lerp2 = lerp(
	   dot(randomVec(pi + float2(0.0, 1.0)), pf - float2(0.0, 1.0)),
	   dot(randomVec(pi + float2(1.0, 1.0)), pf - float2(1.0, 1.0)), w.x);
     		
	return lerp(lerp1, lerp2, w.y);
}


float3 FoamToon(WaterVaryings output, WaterLightData light)
{
	float2 screenUV = light.screenUV;
	float3 viewDirWS = normalize(light.viewDirWS);
	float worldViewDirY = abs(viewDirWS.y);
	float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,sampler_CameraDepthTexture,screenUV),_ZBufferParams);
	float depthZ = LinearEyeDepth(output.positionSS.z/(output.positionSS.w + 1e-5),_ZBufferParams);
	depth = depth - depthZ;
	
	half viewAlphaMultiplier = (worldViewDirY + _WaterAlphaScale) * _FoamWaveMaskExp * _FoamWaveMaskExp;
	half FoamAlphaDepth = 1 - clamp(0, 1, depth * viewAlphaMultiplier);
	half EageFoamSub = (1 - FoamAlphaDepth) - _FoamWidth;

	half EageFoamMask = (sin((FoamAlphaDepth) * _FoamFrequency + _Time.y * _FoamSpeed)+ perlinNoise(output.MainWaveUV.xy * float2(_FoamNoiseSizeX, _FoamNoiseSizeY)) - _FoamDissolve ); // _FoamNoiseSize ;
	half EageFoam = step(EageFoamSub, EageFoamMask);
	
	return  smoothstep(_FoamBlend, 1, FoamAlphaDepth) * EageFoam * 0.75 * _FoamColor;
}



float WaveHeight( WaterVaryings output)
{
	float height = 0;
	height = ((output.positionOS.y) *  0.5 + 0.5);
	float foamMask = lerp(1, saturate(height), _HeightIntensity);
	return foamMask;
}




// 深度结构体 (存入些深度) raw:原始深度  eye:线性深度  linear01:归一化的深度值
MyDepth SampleDepth(float4 screenPos)
{
	MyDepth depth = (MyDepth)0;
	#ifndef _DISABLE_DEPTH_TEX
	depth.raw = 1.0;
	depth.eye = 1.0;
	depth.linear01 = 1.0;
	#else
	screenPos.xyz /= screenPos.w;
	depth.raw = SampleSceneDepth(screenPos.xy) ;
	depth.eye = LinearEyeDepth(depth.raw, _ZBufferParams);
	depth.linear01 = Linear01Depth(depth.raw,_ZBufferParams);
	#endif
	return depth;
}


// 相机重建视空间坐标
float3 ReconstructViewPos(float4 screenPos, float3 viewDirWS, float raw,float eye)
{
	//判断z值是否反向   反向：（1, 0）到（0，1）非线性深度  正向：
	#if UNITY_REVERSED_Z
	float rawDepth = raw;
	#else
	// Adjust z to match NDC for OpenGL
	float  rawDepth = lerp(UNITY_NEAR_CLIP_VALUE, 1, raw);
	#endif

	//Projection to world position
	#if defined(ORTHOGRAPHIC_SUPPORT)
	float4 viewPos = float4((screenPos.xy/screenPos.w) * 2.0 - 1.0, rawDepth, 1.0);
	float4x4 viewToWorld = UNITY_MATRIX_I_VP;
	#if UNITY_REVERSED_Z 
	viewToWorld._12_22_32_42 = -viewToWorld._12_22_32_42;              
    #endif
	float4 viewWorld = mul(viewToWorld, viewPos);
	float3 viewWorldPos = viewWorld.xyz / viewWorld.w;
 	#endif
	
	float3 cameraposition = _WorldSpaceCameraPos.xyz;
	float3 viewPos = eye * (viewDirWS/(screenPos.w + 1e-5)) - cameraposition;
	float3 perspWorldPos = -viewPos;

	
	#if defined(ORTHOGRAPHIC_SUPPORT)
	return lerp(perspWorldPos, viewWorldPos, unity_OrthoParams.w);
	#else
	return perspWorldPos;
	#endif

}

//双层采样焦散
half3 SampleCaustics(float2 uv, float2 time)
{
	half3 caustics1 = SAMPLE_TEXTURE2D(_CausticsTex, sampler_CausticsTex, (uv * _CausticsATiling ) + (time.xy)).rgb;
	half3 caustics2 = SAMPLE_TEXTURE2D(_CausticsTex, sampler_CausticsTex, (uv * _CausticsBTiling ) - (time.xy)).rgb;
	half3 caustics = min(caustics1, caustics2);
	#if WAVE_SIMULATION
	SampleWaveCaustics(half4(uv.x, 0, uv.y), caustics);
	#endif
	
	return caustics;
}


//焦散遮罩
half CausticsMask(WaterVaryings output,WaterLightData light)
{
	half2 screenUV = light.screenUV;
	half worldViewDirY = abs(light.viewDirWS.y);

	half depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV), _ZBufferParams);
	float depthZ = LinearEyeDepth(output.positionSS.z / (output.positionSS.w + 1e-5),_ZBufferParams);
	depth = depth - depthZ;
	depth = saturate(depth);
	half2 deltaUV = light.normalWS.xz * _WaterDistortScale * depth * worldViewDirY / depthZ;
	half newDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV + deltaUV), _ZBufferParams);
	newDepth = newDepth - depthZ;

	half signDepth = saturate(newDepth * 10);
	depth = lerp(depth, newDepth, signDepth);

	half viewAlphaMultiplier = pow((worldViewDirY + _WaterAlphaScale) * _WaterAlphaDepth * _WaterAlphaDepth, _CausticsDistortion);
	half AlphaDepth = depth * viewAlphaMultiplier;
	AlphaDepth = 1 - saturate(AlphaDepth);

	return AlphaDepth;
}

//焦散
float3 WaterCaustics(WaterVaryings output,WaterLightData light)
{
	
	float3 viewDirWS = _WorldSpaceCameraPos - output.positionWS;
	MyDepth d = SampleDepth(output.positionSS);
	//重建相机空间
	float3 rebuildpositionVS = ReconstructViewPos(output.positionSS,viewDirWS, d.raw, d.eye);
    //法线偏移值
	float3 NormalsCombined = float3(0.5, 0.5, 1);
    float3 caustics = SampleCaustics( rebuildpositionVS.xz + lerp(output.NormalWS.xz,NormalsCombined.xz,_CausticsDistortion), _Time.r * _CausticSpeed) * _CausticsBrightness;
	half causticsMask = CausticsMask(output,light);
	caustics = caustics * causticsMask;
	
	return caustics;
}
 

#endif