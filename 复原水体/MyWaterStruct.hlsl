#ifndef  MYWATERWAVE
#define  MYWATERWAVE


//instance技术: 待使用
//Vertex shader struct
struct WaterAttributes
{
    float4 positionOS : POSITION;
    float4 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 texcoord : TEXCOORD0;
};

//Hull shader struct   
struct WaterTessellationControl
{
    float4 positionOS : INTERNALTESSPOS;
    float4 normalOS : NORMAL;
    float4 tangent : TANGENT;
    float2 texcoord : TEXCOORD0; 
};


struct WaterTessellationFactors
{
    float edge[3] : SV_TessFactor; 
    float inside : SV_InsideTessFactor; 
};



struct WaterVaryings
{
    float4 positionCS : SV_POSITION;
    float4 positionOS : TEXCOORD0;
    float4 positionWS : TEXCOORD1;
    float4 positionSS : TEXCOORD2;
    float4 NormalWS : TEXCOORD3;
    float4 TangentWS : TEXCOORD4;
    float4 BitangentWS : TEXCOORD5;
    
    float4 MainWaveUV : TEXCOORD6;
    float4 SecondWaveUV : TEXCOORD7;
    float4 ThirdWaveUV : TEXCOORD8;

    float2 displaceUV : TEXCOORD9;
    
    float3 Test : TEXCOORD10;
};



struct WaterLightData
{
    float3 shadow;
    float3 lightColor;
    float3 specularColor;
    float2 screenUV;
    float3 positionWS;
    float3 normalWS;
    float3 lightDirWS;
    float3 viewDirWS;
    float3 halfDirWS;
    float3 reflectDirWS;
    float NdotV;
    float NdotL;
    float LdotH;
    
};



struct MyDepth
{
    float raw;
    float linear01;
    float eye;
};
 

#endif