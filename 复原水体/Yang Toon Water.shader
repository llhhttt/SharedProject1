Shader "Custom/Final Toon Water"
{
Properties{ 
	
	

	 
	[Main(WaterBaseSettings,_,off,off)]
	_WaterBaseSettings("水体基础设置",float) =  1
	[Sub(WaterBaseSettings)]_Roughness("粗糙度",range(0,1)) = 0.5  
	[Sub(WaterBaseSettings)]_Anisotropy("各项异性程度",range(0,1)) = 0.5
	[Sub(WaterBaseSettings)]_WaterBaseRamp("基础水贴图",2D) = "white"{}

	[SubToggle(WaterBaseSettings,_PHYSICALWATER)] _Physicalwater_On ("开启基于物理的水体",int) = 1
	[SubToggle(WaterBaseSettings,_WAVECONTROL)] _WaveControl_On("海浪 OR 池塘",int) = 1
	
	[Sub(WaterBaseSettings)]_shadowIntensity("阴影强度",range(0,1)) = 0.2
	
	
	
	[Main(WaveNormalSettings,_,off,off)] 
    _WaveNormalSettings("法线设置",float) = 0.0
	//双层法线贴图
	[Tex(WaveNormalSettings, _MainStrength)]_MainWaveNormal("主波浪法线贴图",2D) = "Bump"{}
	[HideInInspector]_MainStrength("主波浪强度",Range(0,4)) = 1	
	[Tex(WaveNormalSettings,_SecondStrength)]_SecondWaveNormal("二层波浪贴图",2D) = "Bump"{}
	[HideInInspector]_SecondStrength("主体波浪强度",range(0,4)) = 1
	[Sub(WaveNormalSettings)]_WWTS("FFT脚本传入: 波浪贴图",2D) = "Bump"{}
	[Sub(WaveNormalSettings)]_WaveNormalPropt("FFT法线占比/暂时禁用",Range(0,1)) = 0.01
	[Sub(WaveNormalSettings)]_FFTWaveNormalPropt("FFT法线GGXGGY占比",range(0,1)) = 0.5
	
	
    [Main(WaterColorSettings,_,off,off)]
    _WaterColorSettings("水体颜设置",float) = 0
	[Sub(WaterColorSettings)]_WaterMuddyColor("水体泥泞颜色",color) = (1,1,1,1)
	[Sub(WaterColorSettings)]_WaterMuddyScale("反射： 水体泥泞颜色强度",range(0,30)) = 5
	[Sub(WaterColorSettings)]_WaterDepthOffset("水体颜色深度偏移",range(0,0.5)) = 0.05 	
	[Sub(WaterColorSettings)]_WaterAlphaScale("反射：水体透明度强弱",range(0,1)) = 0.005
	[Sub(WaterColorSettings)]_WaterAlphaDepth("水体透明度深度",range(0,1)) = 0.02
	[Sub(WaterColorSettings)]_WaterDistortScale("水体折射程度",range(0,10)) = 1

	
    [Main(SpecularSettings,_,off,off)]
    _SpecularSettings("高光设置",float) = 0
    [Sub(SpecularSettings)]_WaterSpecularPow("暂时禁用：高光强度",range(0.001,10000)) = 1

	
	[Main(SSRSettings,_,off,off)]
    _SSR("屏幕空间反射设置",float) = 0
	[Sub(SSRSettings)]_UVJillterIntensity("SSR噪点采样等级",range(0.01,2)) = 0.1
    [Sub(SSRSettings)]_SSRSampleStep("SSR采样步长",range(0,256)) = 16
    [Sub(SSRSettings)]_SSRMaxSampleCount("SSR最大采样次数",range(4,100)) = 16
    [Sub(SSRSettings)]_SSRIntensity("SSR强度",range(0,5)) = 1
	
	
    [Main(EdgeFoamSettings,_,off,off)]
    _EagleFoamSettings("边缘泡沫设置",float) = 0
	[Sub(EdgeFoamSettings)]_HeightIntensity("浪面高度",float) = 0
	[Sub(EdgeFoamSettings)]_FoamColor("边缘浮沫颜色",Color) = (1,1,1,1)
	[Sub(EdgeFoamSettings)]_FoamWaveMaskExp("边缘浮沫遮罩",range(0,1)) = 0.1
	[Sub(EdgeFoamSettings)]_FoamWidth ("边缘浮沫宽度",range(0,10)) = 0.2
	[Sub(EdgeFoamSettings)]_FoamFrequency("卡通浮沫条纹数量",range(0,75)) = 1 
    _FoamSpeed("浮沫速度",float) = 0.1
	_FoamNoiseSizeX("卡通浮沫噪波 X ",range(0,200)) = 200
    _FoamNoiseSizeY("卡通浮沫噪波 Y",range(0,200)) = 150
	[Sub(EdgeFoamSettings)]_FoamDisslove ("卡通浮沫溶解程度",range(0,10)) = 1
	[Sub(EdgeFoamSettings)]_FoamBlend ("卡通浮沫混合",range(0,1)) = 1

	[Main(FFTWaveSettings,_,off,off)]
    _FFTWaveFoamSettings("FFT浮沫设置",float) = 0
	[SubToggle(FFTWaveSettings,_ISFFT)] _IsFFT("使用FFT水面",int) = 1
	[Sub(FFTWaveSettings)]_Displace("FFTRT贴图",2D) = "black"{}
    [Sub(FFTWaveSettings)]_DisplaceTiling("fftTiling",float) = 1
	[Sub(FFTWaveSettings)]_FFTStrength("置换图强度",float) = 0
	[Sub(FFTWaveSettings)]_FoamTex("浮沫贴图",2D) = "black"{}
	//FFT三层浪花大小
	_FoamTiling0("浮沫Tiling A",float) = 10
	[Sub(FFTWaveSettings)]_TopWaveMask0("暂时弃用/浪尖浮沫遮罩 A",range(0,10)) = 0.5
	[Sub(FFTWaveSettings)]_MainWaveTiling("浪尖浮沫大小 A",Vector) = (15,15,0.03,0.03)
	[Sub(FFTWaveSettings)][HDR]_BinCol0("浪尖浮沫颜色 A",Color) = (1,1,1,1)
	
	
	_FoamTiling1("浮沫Tiling B",float) = 5
	[Sub(FFTWaveSettings)]_TopWaveMask1("浪尖浮沫遮罩 B",range(0,1)) = 0.2
	[Sub(FFTWaveSettings)]_SecondWaveTiling("浪尖浮沫大小 B",Vector) = (20,20,0.01,0.01) 
	[Sub(FFTWaveSettings)][HDR]_BinCol1("浪尖浮沫颜色 B",Color) = (0.7,0.7,0.7,1)	

	_FoamTiling2("浮沫Tiling C",float) = 0.1
	[Sub(FFTWaveSettings)]_TopWaveMask2("浪尖浮沫遮罩 C",range(0,1)) = 0.4
	[Sub(FFTWaveSettings)]_ThirdWaveTiling("浪尖浮沫大小 C",Vector) = (50,50,0.02,0.02)
	[Sub(FFTWaveSettings)][HDR]_BinCol2("浪尖浮沫颜色 C",Color) = (0.5,0.5,0.5,1)
	
	
	[Sub(FFTWaveSettings)]_GestnerWaveInfo1("x:gestner波Y轴旋转 y:gestner随机叠加方向 z:gestner波叠加数量",vector) = (0,0,0,0)
	[Sub(FFTWaveSettings)]_GestnerWaveInfo2("x:波长最大 y:波长最小 z:最陡波 w:最缓波",vector) = (1,0,1.5,0.5)

	
	
	
	
	
	
    [Main(UXFoamSettings,_,off,off)] 
    _UXFoamSettings("交互浮沫设置",float) = 1
	[Sub(UXFoamSettings)]_WaterRTSizeMul("交互浮沫比例",range(0,5)) = 1
    

    [Main(OtherWaveSettings,_,off,off)]
    _GestnerWave("其他浪花设置(gestner，sin)",float) = 1
    [Sub(OtherWaveSettings)]_WaveA("波浪A",Vector) = (0.025,0.045,0.6,1.56)
	[Sub(OtherWaveSettings)]_WaveB("波浪B",Vector) = (-0.01,0.05,0.4,3)
	[Sub(OtherWaveSettings)]_WaveC("波浪C",Vector) = (-0.06,-0.26,0.2,0.1)
	[Sub(OtherWaveSettings)]_WaveSpeed("波浪速度",range(0.01,4)) = 0.01
	[Sub(OtherWaveSettings)]_SineWaveA("波浪A x:波高,y:波长,z:波速度",vector) = (1,1,1,1)
	[Sub(OtherWaveSettings)]_SineWaveB("波浪B x:波高,y:波长,z:波速",vector) = (1,1,1,1)

	    
    [Main(CausticsSettings,_,off,off)]
    _Caustic("焦散设置",float) = 1
	[SubToggle(CausticsSettings,_DISABLE_DEPTH_TEX)]  _CausticOn("开启焦散",int) = 1
	[Sub(CausticsSettings)]_CausticsTex("焦散遮罩贴图",2D) = "black"{}
	[Sub(CausticsSettings)]_CausticsBrightness ("焦散亮度",float) = 2
	[HideInInspector]_CausticsATiling ("焦散贴图拉伸A",float) = 0.2
	[HideInInspector]_CausticsBTiling ("焦散贴图拉伸B",float) = 0.5
    [Sub(CausticsSettings)]_CausticSpeed("焦散速度",float) = 1
	[Sub(CausticsSettings)]_CausticsDistortion("焦散法线范围",range(-5,5)) = 0.15

    
	
    [Main(SubSurfaceLightSettings,_,off,off)]
    _SubSurfaceLight("次表面散射",float) = 1
	[Sub(SubSurfaceLightSettings)]_SubSurfaceSunFallOff("次表面落日切口",float) = 1
	[Sub(SubSurfaceLightSettings)]_SubSurfaceBase("基础次表面参数",float) = 1
	[Sub(SubSurfaceLightSettings)]_SubSurfaceSun("太阳光次表面参数",float) = 1
	[Sub(SubSurfaceLightSettings)][HDR]_SurfaceColor("次表面颜色",color) = (1,1,1,1)
   
	
	[Main(TessellationSettings,_,off,off)]
    _TessellationSettings("曲面细分设置",float) = 0.0
    [SubToggle(TessellationSettings_TESSELLATION)] _Tessellation_On ("开启距离曲面细分",int) = 1
    [Sub(TessellationSettings)]_TessValue ("最大细分数",Range(1,1024)) = 16
	[Sub(TessellationSettings)]_TessMin ("最小细分数",float) = 10 
	[Sub(TessellationSettings)]_TessMax ("最大细分距离",float) = 25

	
	[Main(BaseSettings,_, off,off)]
	_BaseSettings ("BaseSettings",float) = 0 
	[Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull",float) = 2
	[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("SrcBlend",float) = 1
	[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("DstBlend",float) = 0
	[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlendAlpha("SrcAlpha",float) = 1.0
	[Enum(UnityEngine.Rendering.BlendMode)] _DstBlendAlpha("DstAlpha",float) = 0.0
	[HideInInspector] _ZWrite("Z Write",float) = 1.0
	
}
    
    
Subshader{
    Tags{
	"RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent" "IgnorProjector" = "True"
    }
    
    HLSLINCLUDE
    ENDHLSL

    
    Pass{
     Name"ForwardLit"
     Tags{
             "LightMode" = "UniversalForward"
     }
        
     Blend[_SrcBlend][_DstBlend], [_SrcBlendAlpha][_DstBlendAlpha]
     ZWrite[_ZWrite]
     Cull[_Cull]
     Ztest LEqual

     HLSLPROGRAM
     #pragma vertex vert
     #pragma fragment frag
     #pragma hull HullFunction
     #pragma domain DomainFunction
     #pragma target 5.0

     #pragma shader_feature  _DISABLE_DEPTH_TEX
     #pragma multi_compile _ _ISFFT
     #pragma multi_compile _ TOONFOAM
     #pragma multi_compile _ _TESSELLATION
     #pragma multi_compile _ _PHYSICALWATER
     #pragma multi_compile _ _WAVECONTROL


     #include "Assets/com.unity.render-pipelines.universal@14.0.11/ShaderLibrary/Core.hlsl"
     #include "Assets/com.unity.render-pipelines.universal@14.0.11/ShaderLibrary/Lighting.hlsl"
     #include "Assets/Shader/YangWaterStruct.hlsl"
     
     ENDHLSL
    }

}
FallBack "VertexLit"
CustomEditor "LWGUI.LWGUI"
} 
