#ifndef MYPBRLIBRARY
#define MYPBRLIBRARY

#include"Library/PackageCache/com.unity.render-pipelines.core@14.0.11/ShaderLibrary/Macros.hlsl"

//自己实践的PBR光照

//直接光漫反射


//迪斯尼BRDF漫反射
half3 DisneyDirectBRDFDiffuse(float3 Albedo,half3 normalWS,half3 viewDirWS,half3 halfDirWS,half3 lightDirWS,float roughness)
{
    float LdotH =  max(dot(lightDirWS,halfDirWS), 0);
    float VdotH  = max(dot(viewDirWS,halfDirWS), 0);
    float NdotV = max(dot(normalWS,viewDirWS),0);
    float NdotL = max(dot(normalWS,lightDirWS),0);

    float FdV = pow((clamp((1 - NdotV),0,1)),5);
    float FdL = pow((clamp((1 - NdotL),0,1)),5);
    float FD90 = 0.5 + 2 * VdotH * VdotH * roughness;
    FdV = 1.0 + (FD90 - 1.0) * FdV;
    FdL = 1.0 + (FD90 - 1.0) * FdL;
    float3 DirectDiffuse = Albedo * ((1/PI) * FdV * FdL);
    return DirectDiffuse;
}

//基础BRDF
half3 BaseDirectBRDFDiffuse(float3 Albedo,half3 lightDirectionWS,half3 normalWS)
{
    float NdotL = dot(normalWS,lightDirectionWS);
    float3 DirectDiffuse = Albedo/PI * NdotL;
    return DirectDiffuse;
}



//直接光镜面反射
//沙子ShickFresl
float3 SandFresnelSchlick(float3 halfDirWS,float3 viewDirWS)
{
    float3 F0 = float3(0.04,0.04,0.04);
    float HdotV = max(dot(halfDirWS,viewDirWS),0);
    return F0 + (1.0 - F0) * pow((1.0 - HdotV),5.0); 
}


//水体ShickFresl
float3 WaterFresnelSchlick(float3 halfDirWS,float3 viewDirWS)
{
    float3 F0 = float3(0.02,0.02,0.02);
    float HdotV = max(dot(halfDirWS,viewDirWS),0);
    return F0 + (1.0 - F0) * pow((1.0 - HdotV),5.0); 
}


//ShickFresnel微表面菲尼尔项
float3 FresnelSchlick(float3 Albedo,float metallic,float3 halfDirWS,float3 viewDirWS)
{
    float HdotV = dot(halfDirWS,viewDirWS);
    float m = clamp(1 - HdotV,0,1);
    float m2 = m * m;
    return m2 * m2 * m;
    /*float3 F0 = lerp(float3(0.04,0.04,0.04), Albedo,metallic);
    float HdotV = max(dot(halfDirWS,viewDirWS),0);
    return F0 + (1.0 - F0) * pow((1.0 - HdotV),5.0);*/
}

//D项（1.GGX 2.Beckmann 3.Blinn - Phong 4.GTR）
//产生Berry微表面法线分布函数(1.拖尾更长 2.代表基础材质上的清漆 3.用于描述各向异性的非金属材质如clearcoat)
float D_GTR1(float alpha,float3 normalWS,float3 lightDirWS,float3 viewDirWS)
{
    if(alpha >= 1) return 1/PI;
    float a2 = alpha * alpha;
    float3 halfDirWS = normalize(viewDirWS + lightDirWS);
    float NdotH = max(dot(normalWS,halfDirWS), 0);
    float cos2th = NdotH * NdotH;
    float den = (1.0 + (a2 - 1.0) * cos2th);
    return (a2 - 1) / (PI * (log(a2) + 1e-5) * den) ;
}

//产生TrowBridge - Reitz法线分布函数(1.传说中的GGX模型拖尾很长  2.代表基础底材质的反射 3.描述各项同性各项异性的金属和非金属)
float D_GTR2(float alpha,float3 normalWS,float3 lightDirWS,float3 viewDirWS)
{
    float a2 = alpha * alpha;
    float3 halfDirWS = normalize(viewDirWS + lightDirWS);
    float NdotH = max(dot(normalWS,halfDirWS), 0);
    float cos2th = NdotH * NdotH;
    float den = (1.0 + (a2 - 1.0) * cos2th);
    return a2 / (PI * den * den );
}

//各项异性版本的 TrowBridge - Reitz微表面法线分布函数
float D_AnisoGTR2(float3 normalWS,float3 lightDirWS,float3 viewDirWS,float3 tangentWS,float3 bitangentWS,float ax,float ay)
{
    float3x3 worldToTangent = float3x3(tangentWS, bitangentWS, normalWS);
    float3 halfDirWS = normalize(viewDirWS + lightDirWS);
    float3 halfDirTS = normalize(mul(worldToTangent,halfDirWS));
    float dotHX = halfDirTS.x;
    float dotHY = halfDirTS.y;
    float NdotH = max(dot(normalWS,halfDirWS),0);
    float deno = dotHX * dotHX / (ax * ax) + dotHY * dotHY / (ay * ay) + NdotH * NdotH;
    return 1.0 / (PI * ax * ay * deno * deno);
}


//Smith GGX微表面几何衰减函数 各项同性版本
float SmithG_GGX(float3 normalWS,float3 viewDirWS,float roughness)
{
    float alphaG = roughness * roughness;
    float a = alphaG * alphaG;
    float NdotV = dot(normalWS, viewDirWS);
    float b = NdotV * NdotV;
    return 1 / (NdotV + sqrt(a + b - a * b));
}

//Smith GGX微表面几何衰减函数 各项异性版本
float SmithG_AnisoGGX(float3 normalWS,float3 viewDirWS,float3 dotVX,float3 dotVY,float ax,float ay)
{
    /*float3x3 worldToTangent = float3x3(tangentWS, bitangentWS, normalWS);
    float3 viewDirTS = normalize(mul(worldToTangent,viewDirWS));*/
    float NdotV = max(dot(normalWS,viewDirWS),0);
    /*float dotVX = viewDirTS.x;
    float dotVY = viewDirTS.y;*/
    return 1.0 / (NdotV + sqrt(pow(dotVX * ax,2) + pow(dotVY * ay,2) + pow(NdotV,2)));
}



//GGX清漆几何项
float ClearCoatG_GGX(float3 normalWS,float3 viewDirWS,float roughness) 
{
    float NdotV = max(dot(normalWS, viewDirWS),0);
    float a2 = roughness * roughness;
    float alphag = a2 * a2;
    float b = NdotV * NdotV;
    return  1.0 / (NdotV + sqrt(alphag + b - alphag * b));
}

//色彩空间转换
float3 GammaTosSRGB(float3 gammacolor)
{
    float3 SRGB = pow(gammacolor,2.2);
    return SRGB;
}

 
//迪斯尼BRDF镜面反射
half3  DisneyDirectBRDFSpecular(float3 normalWS,float3 lightDirectionWS,float3 viewDirectionWS,float3 tangentWS,float3 bitangentWS,float metallic,float3 albedo,float roughness,float anisotropy)
{
    float3 T = normalize(tangentWS);
    float3 B = normalize(bitangentWS);
    float3 N = normalize(normalWS);
    float3 L = normalize(lightDirectionWS);
    float3 V = normalize(viewDirectionWS);
    float NdotL = dot(N,L);
    float NdotV = dot(N,V);
    if(NdotL < 0 || NdotV < 0) return float3(0,0,0);
    float3 H = normalize(L + V);
    float NdotH = dot(N,H);
    float LdotH = dot(L,H);


    
    // Diffuse fresnel - go from 1 at normal incidence to .5 at grazing
    // and mix in diffuse retro-reflection based on roughness
    float FL = FresnelSchlick(albedo,metallic,N,L);
    float FV = FresnelSchlick(albedo,metallic,N,V);
    float Fd90 = 0.5 + 2 * LdotH * LdotH * roughness;
    float Fd = lerp(1.0,Fd90,FL) * lerp(1.0,Fd90,FV);

    // Based on Hanrahan-Krueger brdf approximation of isotropic bssrdf
    // 1.25 scale is used to (roughly) preserve albedo
    // Fss90 used to "flatten" retroreflection based on roughness
    float Fss90 = LdotH * LdotH * roughness;
    float Fss = lerp(1.0,Fss90,FL) * lerp(1.0,Fss90,FV);
    float ss = 1.25 * (Fss * (1 /(NdotL * NdotL) - 0.5) + 0.5);
    
    //specular
    float aspect  = sqrt(1 - anisotropy * 0.9);
    float ax = max(0.001,pow(roughness,2)/aspect);
    float ay = max(0.001,pow(roughness,2) * aspect);

    
    float Ds = D_AnisoGTR2(N,L,V,T,B,ax,ay);

    float FH = FresnelSchlick(albedo, metallic,H,L);
    float3 Fs = lerp(float3(1,1,1),float3(1,1,1),FH);
    
    float Gs;
    Gs = SmithG_AnisoGGX(N, L,dot(L,T),dot(L,B),ax,ay);
    Gs *= SmithG_AnisoGGX(N,V,dot(V,T),dot(V,B),ax,ay);
    

    return   Gs * Fs * Ds;
}



//直接光散射
float GGX_D(float3 halfDirWS,float3 normalWS,float roughness)
{
    float NdotH = saturate(dot(normalWS,halfDirWS));
    float a2 = roughness * roughness;
    float d = (NdotH * NdotH) * (a2 - 1) + 1;
    return a2/(PI * d * d + 0.00001);  
}



//杨实践的PBR光照
//法线表面分布函数
 float D_Function(float3 normalWS,float3 halfDirWS,float roughness)
{
    float NdotH = max(dot(normalWS, halfDirWS),0);
    float a2 = roughness * roughness;
    float NdotH2 = NdotH * NdotH;
    float nom = a2;
    float denom = NdotH2 * (a2 - 1) + 1;
    denom = denom * denom * 3.1415926;
    return nom / denom;
}

//几何衰减函数
float G_section(float dot,float k)
{
    float nom = dot;
    float denom = lerp(dot,1,k);
    return nom/denom;
}
float G_Function(float3 normalWS,float3 lightDirWS,float3 viewDirWS,float roughness)
{
    float NdotL = max(dot(normalWS,lightDirWS),0);
    float NdotV = max(dot(normalWS,viewDirWS),0);
    float k  = pow(1 + roughness,2)/8;
    float GnL= G_section(NdotL,k);
    float GnV = G_section(NdotV,k);
    return GnL * GnV;
}




//菲尼尔项函数
float3  F_Function(float3 halfDirWS,float3 lightDirWS,float3 F0)
{
    float HdotL = max(dot(halfDirWS,lightDirWS),0);
    float Fre = exp2((-5.55473 * HdotL - 6.98316) * HdotL);
    return lerp(Fre,1,F0);
}

//间接光漫反射
float3 IndirF_Function(float3 normalWS,float3 viewDirWS,float3 F0,float roughness)
{
    float NdotV = max(dot(normalWS,viewDirWS),0);
     float Fre = exp2((-5.55473 * NdotV - 6.98316)*NdotV);
    return  F0  + Fre * saturate(1 - roughness - F0);
     
}

//其他光照补充
//OrenNayar漫反射光照模型  适合描述粗糙物体
float OrenNayarDiffuse(float3 lightDirWS, float3 viewDirWS, float3 normalWS, float roughness )
{
    half VdotN = dot( viewDirWS , normalWS);
    half LdotN = dot( lightDirWS, normalWS);
    
    half cos_theta_i = LdotN;
    half theta_r = acos( VdotN );
    half theta_i = acos( cos_theta_i );
    
    half cos_phi_diff = dot( normalize( viewDirWS - normalWS * VdotN ),
                             normalize( lightDirWS - normalWS * LdotN ) );
    
    half alpha = max( theta_i, theta_r ) ;
    half beta = min( theta_i, theta_r ) ;
    half sigma2 = roughness * roughness;
    half A = 1.0 - 0.5 * sigma2 / (sigma2 + 0.33);
    half B = 0.45 * sigma2 / (sigma2 + 0.09);
    
    return saturate( cos_theta_i ) *
        (A + (B * saturate( cos_phi_diff ) * sin(alpha) * tan(beta)));
}




//(Journey修改过的Diffuse)OrenNayar模型  模仿粗糙物体的漫反射模型
half JourneyOrenNayarDiffuse(half3 lightDirWS,half3 viewDirWS,half3 normalWS,half roughness)
{
    half VdotN = dot(viewDirWS,normalWS);
    half LdotN = saturate(4 * dot(lightDirWS,normalWS * float3(1,0.3,1)));
    half cos_theta_i = LdotN;
    half theta_r = acos(VdotN);
    half theta_i = acos(cos_theta_i);
    half cos_phi_diff = dot(normalize(viewDirWS - normalWS * VdotN),normalize(lightDirWS - normalWS * LdotN));
    half alpha = max(theta_i,theta_r);
    half beta = min(theta_i,theta_r);
    half sigma2 = roughness * roughness;
    half A = 1.0 - 0.5 * sigma2 / (sigma2 + 0.33);
    half B = 0.45 * sigma2 / (sigma2 + 0.09);
    return saturate(cos_theta_i) * (A + (B * saturate(cos_phi_diff) * sin(alpha) * tan(beta)));
}

//海洋镜面反射
float OceanSpecular(float3 DirectlightDirWS,float3 viewDirWS,float3 normal,float3 normalDetail , float baseRoughness, float roughness,float edge)
{
 
    float3 halfDirection = normalize( viewDirWS + DirectlightDirWS);
    float baseShine = pow(  max( 0 , dot( halfDirection , normal  ) ) , 10 / baseRoughness );
    float shine = pow( max( 0 , dot( halfDirection , normalDetail  ) ) , 10 / roughness )  ;
    return  lerp(baseShine, shine, edge);
}

#endif