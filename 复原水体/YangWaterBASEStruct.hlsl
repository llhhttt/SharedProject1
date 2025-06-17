#ifndef YANGWATERBASESTRUCT
#define YANGWATERBASESTRUCT



struct LightDate
{
    float3 positionWS;
    float3 normalWS;
    float3 lightDirWS;
    float3 viewDirWS;
    float3 halfDirWS;
    float3 reflectDirWS;
 
    float3 lightColor;
    float3 specularColor;

    float2 screenUV;
    
    float shadow;
    float NdotL;
    float NdotV;
    float NdotH;
    float LdotH;
    
};


//vertex shader输出struct        hull shader输入struct 
struct Attributes
{
    float4 positionOS : POSITION;
    float4 normalOS : NORMAL;
    float4 tangentOS: TANGENT;
    float2 texcoord : TEXCOORD0;
         
};

     
//Domain shader输出struct    Fragment shader输入struct
struct Varyings
{
    
    float4 positionCS : SV_POSITION;
    float2 MainWaveUV : TEXCOORD0;
    float4 SecondWaveUV : TEXCOORD1;
    float4 ThirdWaveUV : TEXCOORD2;
    
    float2 wW_UV : TEXCOORD3;

    float4 NormalWS : TEXCOORD4;
    float4 TangentWS : TEXCOORD5;
    float4 BitangentWS : TEXCOORD6;

    float4  positionSS : TEXCOORD7;
    float3 positionOS : TEXCOORD8;
    float3 positionWS : TEXCOORD9;
    float Test : TEXCOORD10;
    float2 uv : TEXCOORD11;
    float2 depth : TEXCOORD12;
    
};

struct MyDepth
{
    float raw;
    float linear01;
    float eye;
};


#endif