#ifndef  YANGWATERSTRUCT
#define  YANGWATERSTRUCT

#include "Assets/com.unity.render-pipelines.universal@14.0.11/ShaderLibrary/Core.hlsl"
#include "Assets/com.unity.render-pipelines.universal@14.0.11/ShaderLibrary/DeclareDepthTexture.hlsl"	
     
     float4 _GestnerWaveInfo1;
     float4 _GestnerWaveInfo2; 
         
     float _Roughness;
     float _Anisotropy;
     float _shadowIntensity;

     float _MainStrength;
     float _SecondStrength;
     float _WaveNormalPropt;
     float _FFTWaveNormalPropt;

     float4 _WaterMuddyColor;
     float _WaterMuddyScale;
     float _WaterDepthOffset;
     float _WaterAlphaScale;
     float _WaterAlphaDepth;
     float _WaterDistortScale;

     float _WaterSpecularPow;

     float _UVJillterIntensity;
     float _SSRSampleStep;
     float _SSRMaxSampleCount;
     float _SSRIntensity;

     float _HeightIntensity;
     float4 _FoamColor;
     float _FoamWaveMaskExp;
     float _FoamWidth;
     float _FoamFrequency;
     float _FoamSpeed;
     float _FoamNoiseSizeX;
     float _FoamNoiseSizeY;
     float _FoamDissolve;
     float _FoamBlend; 

     float _WaveFoam;
     float _FoamSMA;
     float _FoamSMI; 
     float _FoamTip;



     float _DisplaceTiling;
     float _FFTStrength;
     float4 _MainWaveTiling;
     float4 _SecondWaveTiling;
     float4 _ThirdWaveTiling;
     float _TopWaveMask0;
     float _TopWaveMask1;
     float _TopWaveMask2;
     float _FoamTiling0;
     float _FoamTiling1;
     float _FoamTiling2;
     float4 _BinCol0;
     float4 _BinCol1;
     float4 _BinCol2;
     

    float4 _WaveA;
    float4 _WaveB;
    float4 _WaveC;
    float _WaveSpeed;
    float4 _SineWaveA;
    float4 _SineWaveB;
    
    
    float _CausticsBrightness;
    float _CausticsATiling; 
    float _CausticsBTiling; 
    float _CausticSpeed;
    float _CausticsDistortion;

    
     float _SubSurfaceSunFallOff;
     float _SubSurfaceBase;
     float _SubSurfaceSun;
     float4 _SurfaceColor;


     float _TessValue;
     float _TessMin; 
     float _TessMax;


     TEXTURE2D(	_WaterBaseRamp); SAMPLER(sampler_WaterBaseRamp);
     TEXTURE2D (_MainWaveNormal); SAMPLER(sampler_MainWaveNormal);  
     TEXTURE2D(_SecondWaveNormal); SAMPLER(sampler_SecondWaveNormal);

     TEXTURE2D(_CausticsTex); SAMPLER(sampler_CausticsTex);
     TEXTURE2D(_Displace); SAMPLER(sampler_Displace);
     TEXTURE2D(_FoamTex); SAMPLER(sampler_FoamTex);
     TEXTURE2D(_WaterRamp); SAMPLER(sampler_WaterRamp);
     TEXTURE2D(_WWTS); SAMPLER(sampler_WWTS); 

     TEXTURE2D(_CameraOpaqueTexture);  SAMPLER(sampler_CameraOpaqueTexture);


     TEXTURE2D(_displaceXYZ); SAMPLER(sampler_displaceXYZ);


#include "Assets/com.unity.render-pipelines.universal@14.0.11/ShaderLibrary/Core.hlsl"
//#include "Assets/Shader/ToonScene/Water/YangWaterWave.hlsl"
//#include "Assets/Shader/ToonScene/Water/WaterTessellation.hlsl"

#include "Assets/Shader/YangWaterLighting.hlsl"
#include "Assets/Shader/MyWaterStruct.hlsl"
#include "Assets/Shader/MyTessellation.hlsl"
//#include "Assets/Shader/ToonScene/Water/YangWaterFoamCaustics.hlsl"
//#include "Assets/Shader/ToonScene/Water/YangWaterBASEStruct.hlsl"

//Sine波浪
    float3 SineWave1(float3 position, float3 SineWaveA){
        float k = 2 * PI / SineWaveA.y;
        float waveY = SineWaveA.x * sin(k * (position.x - SineWaveA.z * _Time.y));
        return float3(0,waveY,0);
    }
      
    float3 SineWave2(float3 position, float3 SineWaveB){
        float k = 2 * PI / SineWaveB.y;
        float waveY = SineWaveB.x * sin(k * (position.z - SineWaveB.z * _Time.y));
        return float3(0,waveY,0);
    }

     

     float Random(int seed)
            {
                            
                return frac(sin(dot(float2(seed,2), float2(12.9898, 78.233))) ) * 2 - 1;
            }

            struct Gerstner
            {
                float3 positionWS;
                float3 bitangentTS;
                float3 tangentTS;
                float3 normalTS;
                float3 bitangentWS;
                float3 tangentWS;
                float3 normalWS;
            };

            Gerstner GerstnerWaveTest(float4 direction,float3 positionWS,int waveCount,float wavelengthMax,float wavelengthMin,float steepnessMax,float steepnessMin,float randomdirection)
            {
                Gerstner gerstner;

                float3 P;
                float3 B;
                float3 T;


                for (int i = 0; i < waveCount; i++)
                {
                    float step = (float) i / (float) waveCount;

                    float2 d = float2(Random(i),Random(2*i));
                    d = normalize(lerp(normalize(direction.xy), d, randomdirection));

                    float wavelength = lerp(wavelengthMax, wavelengthMin, step);
                    float steepness = lerp(steepnessMax, steepnessMin, step)/waveCount;

                    float k = 2 * PI / wavelength;
                    float g = 9.81f;
                    float w = sqrt(g * k);
                    float a = steepness / k;
                    float2 wavevector = k * d;
                    float value = dot(wavevector, positionWS.xz) - w * _Time.y * _WaveSpeed;

                    P.x += d.x * a * cos(value);
                    P.z += d.y * a * cos(value);
                    P.y += a * sin(value);

                    T.x += d.x * d.x * k * a * -sin(value);
                    T.y += d.x * k * a * cos(value);
                    T.z += d.x * d.y * k * a * -sin(value);

                    B.x += d.x * d.y * k * a * -sin(value);
                    B.y += d.y * k * a * cos(value);
                    B.z += d.y * d.y * k * a * -sin(value);
                }
                gerstner.positionWS.x = positionWS.x + P.x;
                gerstner.positionWS.y = positionWS.y + P.y;
                gerstner.positionWS.z = positionWS.z + P.z;
                gerstner.tangentTS = float3(1 + T.x, T.y, T.z);
                gerstner.bitangentTS = float3(B.x,B.y,1 + B.z);
                gerstner.normalTS = cross(gerstner.tangentTS,gerstner.bitangentTS);

                float3x3 TBN = float3x3(normalize(gerstner.tangentTS),normalize(gerstner.bitangentTS),normalize(gerstner.normalTS));
                gerstner.normalWS = TransformTangentToWorld(gerstner.normalTS,TBN);
                gerstner.bitangentWS = TransformTangentToWorld(gerstner.bitangentTS,TBN);
                gerstner.tangentWS = TransformTangentToWorld(gerstner.tangentTS,TBN);
                return gerstner;
                
            }


//切线空间计算Gerstner
float3 GerstnerWave (
    float4 wave, float3 p, inout float3 tangent, inout float3 binormal
) {
    float steepness = wave.z ;
    float wavelength = wave.w;
    float k = 2 * 3.1415926 / wavelength;
    float c = sqrt(9.8 / k);
    float2 d = normalize(wave.xy);
    float f = k * (dot(d, p.xz) - c * _Time.y * _WaveSpeed);
    float a = steepness / k;

    tangent += float3(
        -d.x * d.x * (steepness * sin(f)),
        d.x * (steepness * cos(f)),
        -d.x * d.y * (steepness * sin(f))
    );
    binormal += float3(
        -d.x * d.y * (steepness * sin(f)),
        d.y * (steepness * cos(f)),
        -d.y * d.y * (steepness * sin(f))
    );
    return float3(
        d.x * (a * cos(f)),
        a * sin(f),
        d.y * (a * cos(f))
    );
}




//顶点着色器
WaterVaryings VertexMain(WaterAttributes input)
{
    WaterVaryings output = (WaterVaryings)0;

    
    output.MainWaveUV.xy = input.texcoord * _MainWaveTiling.xy + _Time.y * _MainWaveTiling.zw ;
    output.SecondWaveUV.xy = input.texcoord * _SecondWaveTiling.xy + _Time.y * _SecondWaveTiling.zw ;
    output.ThirdWaveUV.xy = input.texcoord * _ThirdWaveTiling.xy + _Time.y * _ThirdWaveTiling.zw;
    output.displaceUV = input.texcoord;
    

    

    //#if defined(_ISFFT)
    
    float3 fftpositionWS = TransformObjectToWorld(input.positionOS);
    float4 fftpositionCS = TransformObjectToHClip(input.positionOS);
    float4 fftpostiionSS = ComputeScreenPos(fftpositionCS);
    float2 screenUV = fftpostiionSS.xy / fftpostiionSS.w;
    float3 viewDirWS =  normalize(_WorldSpaceCameraPos.xyz - fftpositionWS);
    float viewDirWSY = viewDirWS.y;


    
    float4 displace = SAMPLE_TEXTURE2D_LOD(_Displace, sampler_Displace,output.displaceUV.xy * _DisplaceTiling * 0.02,0) * 0.01 *  _FFTStrength;

        
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS,input.tangentOS);
    float3 tangentWS = normalize(normalInput.tangentWS);
    float3 bitangentWS = normalize(normalInput.bitangentWS);
    float3 normalWS = normalize(normalInput.normalWS);



    float4 positionWS = float4(TransformObjectToWorld(input.positionOS),1);
    Gerstner gerstner = GerstnerWaveTest(float4(_GestnerWaveInfo1.x,10,0,0),positionWS,_GestnerWaveInfo1.z,_GestnerWaveInfo2.x,_GestnerWaveInfo2.y,_GestnerWaveInfo2.z,_GestnerWaveInfo2.w,float4(_GestnerWaveInfo1.y,10,0,0));
                
                
    //float p  = 0;
    //float3 gridPoint =  input.positionOS
    //p += GerstnerWave(_WaveA, gridPoint, tangentWS, bitangentWS);
    //p += GerstnerWave(_WaveB, gridPoint, tangentWS, bitangentWS);
    //p += GerstnerWave(_WaveC, gridPoint, tangentWS, bitangentWS);




                
    output.positionWS = float4(gerstner.positionWS,1);
    output.positionCS = TransformWorldToHClip(output.positionWS);
    output.positionSS = ComputeScreenPos(output.positionCS);

                


    output.NormalWS = float4(gerstner.normalWS,positionWS.x);
    output.TangentWS = float4(gerstner.tangentWS,positionWS.y);
    output.BitangentWS = float4(gerstner.bitangentWS,positionWS.z);

    output.Test = gerstner.normalWS;
    
    return output;
    
}

//vertex to hull
WaterTessellationControl vert(WaterAttributes input)
{
    WaterTessellationControl output;
    output.positionOS = input.positionOS;
    output.normalOS = input.normalOS;
    output.tangent = input.tangentOS;
    output.texcoord = input.texcoord;
    return output;
}




//Hull sahder 
[domain("tri")] //控制patch的类型  1.triangle 2.quad  3.isoline                           
[partitioning("fractional_odd")] //控制细分的分布  1.equal 2.fractional_even 3.fractional_odd
[outputtopology("triangle_cw")]//控制三角形环绕顺序 1.cw 2.ccw
[patchconstantfunc("TessellationFunction")] //曲面细分程度
[outputcontrolpoints(3)] //指定了TCS的数量
 WaterTessellationControl HullFunction(InputPatch<WaterTessellationControl,3> patch,uint id : SV_OutputControlPointID)
{
    return patch[id];
}


//hull to domain
WaterTessellationFactors TessellationFunction(InputPatch<WaterTessellationControl,3> input)
{
    WaterTessellationFactors output;
    float4 tf = 1;
    tf = DistanceBasedTess(input[0].positionOS,input[1].positionOS,input[2].positionOS,
        _TessValue,_TessMin,_TessMax,GetObjectToWorldMatrix(),_WorldSpaceCameraPos);
    output.edge[0] = tf.x;
    output.edge[1] = tf.y;
    output.edge[2] = tf.z; 
    output.inside = tf.w; 
    return output;
}




[domain("tri")]
WaterVaryings DomainFunction(WaterTessellationFactors factor3,OutputPatch<WaterTessellationControl,3>patch,float3 bary : SV_DomainLocation)
{
    WaterAttributes output =(WaterAttributes)0;
    output. positionOS = patch[0].positionOS * bary.x + patch[1].positionOS  * bary.y + patch[2].positionOS  * bary.z;
    output.normalOS  = patch[0].normalOS  * bary.x + patch[1].normalOS  * bary.y + patch[2].normalOS  * bary.z;
    output.tangentOS = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
    output.texcoord = patch[0].texcoord * bary.x + patch[1].texcoord * bary.y + patch[2].texcoord * bary.z;
    return VertexMain(output);
}


    
half4 frag(WaterVaryings output) : SV_Target
{
    WaterLightData light = PrepareLighting(output);
    float3 finalColor = finalCol(output,light);
    float4 refract = GetRefraction(output,light);

    //float3 SSR = GetSSRLighting(output,light);

    
    float3 FINAL = lerp(refract, finalColor, refract.a);

    
    float slope = SAMPLE_TEXTURE2D(_WWTS,sampler_WWTS, output.displaceUV.xy * _DisplaceTiling * 0.02).z;
    float displace = SAMPLE_TEXTURE2D_LOD(_Displace, sampler_Displace,output.displaceUV.xy * _DisplaceTiling * 0.02,0).z * _FFTStrength;

    float3 TOONFOAM = FoamToon(output,light);

    float WaveHeight = TransformWorldToObject(output.positionWS).y;
    float slope0 = smoothstep(_TopWaveMask0,1,WaveHeight);
    float slope1 = smoothstep(_TopWaveMask1,_TopWaveMask0,WaveHeight);
    float slope2 = smoothstep(_TopWaveMask2,_TopWaveMask1,WaveHeight);

    
    
    //float tipfoam0 = pow(smoothstep(_FoamSMI,_FoamSMA, slope0 * waveheight(output)), _FoamTip);
    //float tipfoam1 = pow(smoothstep(_FoamSMI,_FoamSMA, slope1 * waveheight(output)), _FoamTip);
    //float tipfoam2 = pow(smoothstep(_FoamSMI,_FoamSMA, slope2 * waveheight(output)), _FoamTip);

    
    float foamtex0 = SAMPLE_TEXTURE2D(_FoamTex ,sampler_FoamTex,output.MainWaveUV.xy * _FoamTiling0).x;
    float foamtex1 = SAMPLE_TEXTURE2D(_FoamTex ,sampler_FoamTex, output.SecondWaveUV.xy * _FoamTiling1).y;		
    float foamtex2 = SAMPLE_TEXTURE2D(_FoamTex ,sampler_FoamTex,output.ThirdWaveUV.xy * _FoamTiling2).z;

    
    float3 tipfoamA = foamtex0 * _BinCol0 * slope0;
    float3 tipfoamB = foamtex1 * _BinCol1 * slope1;
    float3 tipfoamC = foamtex2 * _BinCol2 * slope2;
    float3 TIPFOAM = tipfoamA + tipfoamB + tipfoamC;

    
    float3 FOAM = TOONFOAM + TIPFOAM;

    //float3 Test = SAMPLE_TEXTURE2D(_displaceXYZ,sampler_displaceXYZ,output.uv);
    
    return float4(FINAL + FOAM,1);//float4(FINAL + FOAM,1);//foamtex2;//float4(FINAL,refract.a);//float4(FINAL,1);//float4(FINAL + FOAM + SSR,1);
} 



#endif