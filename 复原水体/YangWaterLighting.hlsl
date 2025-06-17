#ifndef YANGWATERLIGHTING
#define YANGWATERLIGHTING
/*#include "Assets/Shader/ToonScene/Water/YangWaterBASEStruct.hlsl"
#include  "Assets/Shader/ToonScene/Water/YangWaterStruct.hlsl"
#include "Assets/Shader/ToonScene/Water/MyPBRLibrary.hlsl"
#include "Assets/Shader/ToonScene/Water/YangWaterFoamCaustics.hlsl"
#include "Assets/Shader/ToonScene/Water/WaterSSR.hlsl"
#include "Assets/Shader/ToonScene/Water/MyVariousCompute.hlsl"*/

//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Assets/Shader/MyWaterStruct.hlsl"
#include "Assets/Shader/MyPBR/MyPBRLibrary.hlsl"
#include "Assets/Shader/YangWaterFoamCaustics.hlsl"



//把浪花法线计算出来
float3 WaveNormal(WaterVaryings input)
{
    float3 bitangent = input.BitangentWS.xyz;
    float3 tangent = input.TangentWS.xyz;
    float3 normalWS = input.NormalWS.xyz;

    half3 waterN1 = SAMPLE_TEXTURE2D(_MainWaveNormal,sampler_MainWaveNormal,input.MainWaveUV.xy).xyz;
    half3 waterN2 = SAMPLE_TEXTURE2D(_MainWaveNormal,sampler_MainWaveNormal,input.SecondWaveUV.xy).xyz;
    half3 waterN3 = SAMPLE_TEXTURE2D(_SecondWaveNormal,sampler_SecondWaveNormal,input.ThirdWaveUV.xy).xyz;

    half3 FFTNormal = SAMPLE_TEXTURE2D(_WWTS,sampler_WWTS,float2(input.MainWaveUV.xy * _DisplaceTiling * 0.02)).xyz;
    FFTNormal = float3(FFTNormal.x,FFTNormal.y,0);
    normalWS = lerp(normalWS,FFTNormal, _WaveNormalPropt);

    
    half3 waterNormal = ((waterN1 + waterN2) * 0.6667 - 0.6667) * half3( _MainStrength , _MainStrength,1);
    waterN3 =  waterN3 * 2 - 1;

    waterNormal += (waterN3 * half3(_SecondStrength, _SecondStrength,1));
 
    waterNormal = normalize(TransformTangentToWorld(waterNormal,float3x3(tangent,bitangent,normalWS)));
         
    return waterNormal;
}




float3 SpecNormal(WaterVaryings input)
{

    
    //使用DDX DDY法还原法线
    float3 dpdx = ddx(input.positionWS);
    float3 dpdy = ddy(input.positionWS);
    float3 tangentWS = normalize(dpdx);
    float3 bitangentWS = normalize(dpdy);
    float3 normalWS =  normalize(cross(bitangentWS, tangentWS));
    
    
    float3 bitangent = input.BitangentWS.xyz;
    float3 tangent = input.TangentWS.xyz;
    float3 normal = input.NormalWS.xyz;
    
    
    //第一层波浪纹理法线
    float3 normalLayera = SAMPLE_TEXTURE2D(_MainWaveNormal, sampler_MainWaveNormal,input.MainWaveUV.xy).xyz;
    float3 normalLayerb = SAMPLE_TEXTURE2D(_MainWaveNormal,sampler_MainWaveNormal,input.SecondWaveUV.xy).xyz;
    float3 normalLayerc = SAMPLE_TEXTURE2D(_SecondWaveNormal,sampler_SecondWaveNormal,input.ThirdWaveUV.xy).xyz;
    //float3 normalLayerC =  UnpackNormal(normalLayerc);

    half3 FFTNormal = SAMPLE_TEXTURE2D(_WWTS,sampler_WWTS,float2(input.MainWaveUV.xy * _DisplaceTiling * 0.02)).xyz;
    FFTNormal = float3(FFTNormal.x,FFTNormal.y,0);
    normalWS = lerp(normalWS,FFTNormal, _WaveNormalPropt);



    float3 waterNormal = ((normalLayera + normalLayerb) * 0.6667 - 0.6667) * float3(_MainStrength,_MainStrength, 1);
    normalLayerc = normalLayerc * 2 - 1;
    waterNormal += (normalLayerc * float3(_SecondStrength,_SecondStrength,1));
    
    
    //waterNormal += (waterN3 * half3(_MWTStrength +  _SpecNormalStrength, _MWTStrength +  _SpecNormalStrength, 1));
    normal = normalize(mul(waterNormal,float3x3(tangent, bitangent, normal)));

    float3 WATERNORMAL = normalize(normal * _FFTWaveNormalPropt + normalWS * (1 - _FFTWaveNormalPropt));

    return  WATERNORMAL;
}

   

half3 DirectSpecular(WaterVaryings output,WaterLightData light)
{
    float3 N  = SpecNormal(output);
    /*
    float3 L = normalize(light.lightDirWS);
    float3 V = normalize(light.viewDirWS);
    float3 H = normalize(L + V);
    float NdotH = saturate(dot(N,H));
    float NdotV = saturate(dot(N,V));
    */


    
    half3 H = normalize(light.lightDirWS + light.viewDirWS);
    half NdotH = saturate(dot(N,H));
    
    float D = (-0.004)/(NdotH * NdotH - 1.005);
    D *= D;

    half x = 1 - light.LdotH;
    half x2 = x * x;
    half x5 = x2 * x2 * x;

    half F = light.specularColor + (1 - light.specularColor) * x5;
    return light.lightColor * D * F * PI * _WaterSpecularPow * 1.12 * light.shadow;
}




//次表面散射
float3 waterSSS(WaterVaryings output, WaterLightData light)
{
    float SSSIntensity = WaveHeight(output);
    float v = abs(light.viewDirWS.y);
    half towardsSun = pow(max(0., dot(light.lightDirWS, -light.viewDirWS)), _SubSurfaceSunFallOff);
    half3 subsurface = (_SubSurfaceBase + _SubSurfaceSun * towardsSun) *  _SurfaceColor.rgb * light.lightColor;
    subsurface *= (1.0 - v * v) * SSSIntensity;
    return subsurface;
}




WaterLightData PrepareLighting(WaterVaryings output)
{
    WaterLightData l = (WaterLightData)0;

    //计算阴影坐标
    float4 SHADOW_COORDS = TransformWorldToShadowCoord(l.positionWS);
    //得到阴影
    Light light = GetMainLight(SHADOW_COORDS);
    l.shadow = light.shadowAttenuation;
    half shadow = l.shadow * _shadowIntensity;
    l.lightColor = light.color;
    l.specularColor = light.color;
    l.screenUV = output.positionSS.xy/output.positionSS.w;
    l.positionWS = float3(output.NormalWS.w,output.TangentWS.w,output.BitangentWS.w);
    l.normalWS = WaveNormal(output);
    l.lightDirWS =  light.direction;
    l.viewDirWS = normalize(_WorldSpaceCameraPos.xyz - l.positionWS);
    l.halfDirWS = normalize(l.lightDirWS + l.viewDirWS); 
    l.reflectDirWS = normalize(reflect(-l.viewDirWS,l.normalWS));
    l.NdotV = saturate(dot(l.normalWS, l.viewDirWS));
    return  l;
}




//接入
float3  finalCol(WaterVaryings output,WaterLightData light)
{
    //准备UV
    float2 screenUV = output.positionSS.xy /(output.positionSS.w + 1e-5);
    float Depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,sampler_CameraDepthTexture,screenUV),_ZBufferParams) ;
    float objectDepth = output.positionSS.w ;
    float depthdistance = Depth -  objectDepth;
    float depth = clamp(depthdistance,0.01,0.99);
    
    float3 Albedo = SAMPLE_TEXTURE2D(_WaterBaseRamp,sampler_WaterBaseRamp,float2(depth, 0.5));
    float3 FFTnormalWS = SpecNormal(output);

    //基于BRDF计算的水面 
    //#if _PHYSICALWATER 
    float3 DIRECTSPECULAR = DirectSpecular(output,light);//DisneyDirectBRDFSpecular(SpecNormal(output),light.lightDirWS,light.viewDirWS,output.TangentWS.xyz,output.BitangentWS.xyz,0,Albedo,_Roughness,_Anisotropy) * light.lightColor;
    
    float3 DIRECTDIFFUSE = DisneyDirectBRDFDiffuse(Albedo,output.NormalWS,light.viewDirWS,light.halfDirWS,light.lightDirWS,_Roughness);
    float3 WATERSSS = waterSSS(output ,light);
    half3 finalCol = DIRECTSPECULAR + DIRECTDIFFUSE  + WATERSSS;
    /*#else 
    half3 DIRECTSPECULAR = DirectSpecular(output,light) * light.lightColor;
    float2 flowmap = (1,1);
    half3 DirectDiffuse = lerp(float3(0.6,0.6,0.6),light.lightColor,light.NdotL);
    half3 finalCol =  DirectDiffuse;
    #endif*/

    
    //加入水体焦散
    finalCol  +=  WaterCaustics(output,light);
    

    //finalCol += UX_Foam(light);
    
    return finalCol;
}

float4 GetRefraction(WaterVaryings output,WaterLightData light)
{
    float3 FFTnormalWS = SpecNormal(output);
    float2 screenUV = light.screenUV;
    
    float3 worldViewDir = light.viewDirWS;
    float worldViewDirY = abs(worldViewDir.y);
    
    float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV), _ZBufferParams) ;
    float depthZ =  LinearEyeDepth(output.positionSS.z/(output.positionSS.w + 1e-5),_ZBufferParams);
    depth = depth - depthZ;
    
    depth = saturate(depth);


    

    float2 deltaUV = FFTnormalWS.xz * _WaterDistortScale * depth * worldViewDirY / depthZ;
    float newDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV + deltaUV), _ZBufferParams);

    newDepth = newDepth - depthZ;
    float signDepth = saturate(newDepth * 10);
    screenUV = screenUV + deltaUV * signDepth;

    depth = lerp(depth, newDepth, signDepth);

    
    
    float viewMultiplier = (worldViewDirY + _WaterMuddyScale) * _WaterDepthOffset * _WaterDepthOffset;
    float colorDepth = depth * viewMultiplier;
    
    float viewAlphaMultiplier = (worldViewDirY + _WaterAlphaScale) * _WaterAlphaDepth * _WaterAlphaDepth;
    float AlphaDepth = depth * viewAlphaMultiplier;

    
    float3 gradientColor = SAMPLE_TEXTURE2D(_WaterRamp ,sampler_WaterRamp, float2(colorDepth,1)) * _WaterMuddyColor.rgb;

    
    float alpha = saturate(1 - AlphaDepth);
    alpha = saturate(1.02 - pow(alpha, dot(FFTnormalWS, worldViewDir) *  5 * 6));

    float4 refraction = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, screenUV);
    float4 REFRAC = float4(0,0,0,0);
    REFRAC.rgb = lerp(refraction.rgb,refraction.rgb * gradientColor * _WaterMuddyScale,alpha);
    REFRAC.a = alpha;
    

    return float4(REFRAC.rgb,REFRAC.a);//AlphaDepth;
}



#endif


