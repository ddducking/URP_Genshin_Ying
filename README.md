# Shader:原神_荧

## 0.原效果：

<img src="C:\Users\Qian Yukang\Pictures\Screenshots\屏幕截图 2026-03-31 210317.png"  />

## 1.半兰伯特漫反射

### 0.半兰伯特漫反射效果图：

![](C:\Users\Qian Yukang\Pictures\Screenshots\屏幕截图 2026-03-31 210403.png)

兰伯特漫反射的光照范围为-1~1，通过（0.5+0.5）使光照范围变为0~1，从而使暗部不会全黑。

```c
Shader "GenshinToon/Body"//着色器名称（在材质面板中可见）
{
    Properties//开放给外界的属性（在材质面板中可见）（大致等于C#中的public变量）
    {
        [Header(Textures)]//属性分组标题（在材质面板中显示为分组标题）
        _BaseMap("Base Map", 2D) = "white" {}//基础贴图属性（名称、类型、默认值）
    }
    SubShader//子着色器（包含一个或多个Pass）
    {
        Tags//标签（告诉Unity这个着色器是什么类型的）
        {
            "RenderPipeline" = "UniversalPipeline"//指定渲染管线（URP）
            "RenderType" = "Opaque"//指定渲染类型（不透明）
        }
        HLSLINCLUDE//公共代码块开始（可以在多个Pass中共享）
                //包含公共代码（如预处理指令、函数、结构体、头文件、常量定义、函数定义等）
                #pragma multi_compile _MAIN_LIGHT_SHADOWS // 主光源阴影
                #pragma multi_compile _MAIN_LIGHT_SHADOWS_CASCADE // 主光源阴影级联
                #pragma multi_compile _MAIN_LIGHT_SHADOWS_SCREEN // 主光源阴影屏幕空间

                #pragma multi_compile_fragment _LIGHT_LAYERS // 光照层
                #pragma multi_compile_fragment _LIGHT_COOKIES // 光照饼干
                #pragma multi_compile_fragment _SCREEN_SPACE_OCCLUSION // 屏幕空间遮挡
                #pragma multi_compile_fragment _ADDITIONAL_LIGHT_SHADOWS // 额外光源阴影
                #pragma multi_compile_fragment _SHADOWS_SOFT // 阴影软化

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" // 核心库
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl" // 光照库

                TEXTURE2D(_BaseMap);//声明基础贴图（纹理）变量
                SAMPLER(sampler_BaseMap);//声明基础贴图采样器变量
            ENDHLSL//公共代码块结束
        pass//渲染通道
        {
            Name"UniversalForward"//通道名称（可选）
            Tags
            {
                "LightMode" = "UniversalForward"//指定光照模式（URP前向渲染）
            }
            HLSLPROGRAM //着色器程序开始

                #pragma vertex MainVS//声明顶点着色器函数
                #pragma fragment MainFS//声明片元着色器函数

                //顶点着色器函数输入结构体（包含顶点属性，如位置、法线、UV等）
                struct Attributes
                {
                    float4 positionOS : POSITION;//本地空间顶点坐标
                    float2 uv0 : TEXCOORD0;//第一套纹理坐标
                    float3 normalOS : NORMAL; //本地坐标法线
                };

                //由顶点着色器，传递给片元着色器函数输入结构体（包含从顶点着色器传递过来的数据，如位置、法线、UV等）
                struct Varyings
                {
                    float4 positionCS : SV_POSITION;//裁剪空间顶点坐标
                    float2 uv0 : TEXCOORD0;//第一套纹理坐标
                    float3 normalWS : TEXCOORD1;//世界坐标法线
                };

                //顶点着色器函数：处理顶点（如位置、法线、UV等）（返回裁剪空间坐标）
                Varyings MainVS(Attributes input)
                {
                    Varyings output;//定义顶点着色器返回值

                    //position
                    VertexPositionInputs vertexInputs = GetVertexPositionInputs(input.positionOS.xyz);//转换顶点空间
                    output.positionCS = vertexInputs.positionCS;//将裁剪空间坐标传递给输出变量

                    //normal
                    VertexNormalInputs vertexNormalInputs = GetVertexNormalInputs(input.normalOS);//转换法线空间
                    output.normalWS = vertexNormalInputs.normalWS;//将世界坐标法线传递给输出变量

                    //uv
                    output.uv0 = input.uv0;//将纹理坐标传递给输出变量

                    return output;//返回输出变量
                }
                //片元着色器函数：处理像素（如颜色、纹理采样、光照等）（返回最终颜色）
                half4 MainFS(Varyings input): SV_TARGET
                {
                    Light light = GetMainLight();//获取主光源信息（如方向、颜色等）

                    //normalize vector
                    half3 N = normalize(input.normalWS);//法线向量归一化
                    half3 L = normalize(light.direction);//光照方向向量归一化
                    half NoL = saturate(dot(N, L));//法线与光照方向的点积（用于计算漫反射强度）

                    //texture sampling
                    half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv0);//从基础贴图采样颜色（使用纹理坐标）

                    //lambert diffuse lighting
                    half Lambert = NoL; //兰伯特漫反射（基于法线与光照方向的点积）（此时为-1~1）
                    half halfLambert = NoL * 0.5 + 0.5; //半兰伯特漫反射（增加了环境光照的影响，使阴影部分更亮）（此时为0~1）
                    halfLambert *= pow(halfLambert,2); 
                    //(a *= b 等同于 a = a * b)(pow为C语言内置函数，幂函数)（pow(halfLambert,2)等同于halfLanbert的2次方

                    //final color calculation
                    half3 finalColor = baseMap.rgb * halfLambert * light.color;//最终颜色（RGB来自基础贴图）

                    return half4(finalColor, baseMap.a);//返回最终颜色（RGB来自基础贴图，Alpha来自基础贴图）
                }

            ENDHLSL//着色器程序结束
        }
    }
}

```



## 2.环境光遮蔽（AO）

### 0.环境光遮蔽效果图：

![](C:\Users\Qian Yukang\Pictures\Screenshots\屏幕截图 2026-04-01 000817.png)

通过添加lightmap贴图实现环境光遮蔽

```c
Shader "GenshinToon/Body"//着色器名称（在材质面板中可见）
{
    Properties//开放给外界的属性（在材质面板中可见）（大致等于C#中的public变量）
    {
        [Header(Textures)]//属性分组标题（在材质面板中显示为分组标题）
        _BaseMap("Base Map", 2D) = "white" {}//基础贴图属性（名称、类型、默认值）
        _LightMap("LightMap",2D) = "white" {}//光照贴图属性（名称、类型、默认值）
        [Toggle(_USE_LIGHTMAP_AO)] _UseLightMapAO("Use LightMap AO", Range(0,1)) = 1//是否使用光照贴图AO属性（名称、类型、默认值）
    }
    SubShader//子着色器（包含一个或多个Pass）
    {
        Tags//标签（告诉Unity这个着色器是什么类型的）
        {
            "RenderPipeline" = "UniversalPipeline"//指定渲染管线（URP）
            "RenderType" = "Opaque"//指定渲染类型（不透明）
        }
        HLSLINCLUDE//公共代码块开始（可以在多个Pass中共享）
                //包含公共代码（如预处理指令、函数、结构体、头文件、常量定义、函数定义等）
                #pragma multi_compile _MAIN_LIGHT_SHADOWS // 主光源阴影
                #pragma multi_compile _MAIN_LIGHT_SHADOWS_CASCADE // 主光源阴影级联
                #pragma multi_compile _MAIN_LIGHT_SHADOWS_SCREEN // 主光源阴影屏幕空间

                #pragma multi_compile_fragment _LIGHT_LAYERS // 光照层
                #pragma multi_compile_fragment _LIGHT_COOKIES // 光照饼干
                #pragma multi_compile_fragment _SCREEN_SPACE_OCCLUSION // 屏幕空间遮挡
                #pragma multi_compile_fragment _ADDITIONAL_LIGHT_SHADOWS // 额外光源阴影
                #pragma multi_compile_fragment _SHADOWS_SOFT // 阴影软化

                #pragma shader_feature_local _USE_LIGHTMAP_AO // 是否使用光照贴图AO（局部定义的着色器特性）

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" // 核心库
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl" // 光照库

                TEXTURE2D(_BaseMap);//声明基础贴图（纹理）变量
                SAMPLER(sampler_BaseMap);//声明基础贴图采样器变量
                TEXTURE2D(_LightMap);//声明光照贴图（纹理）变量
                SAMPLER(sampler_LightMap);//声明光照贴图采样器变量

            ENDHLSL//公共代码块结束
        Pass//渲染通道
        {
            Name"UniversalForward"//通道名称（可选）
            Tags
            {
                "LightMode" = "UniversalForward"//指定光照模式（URP前向渲染）
            }
            HLSLPROGRAM //着色器程序开始

                #pragma vertex MainVS//声明顶点着色器函数
                #pragma fragment MainFS//声明片元着色器函数

                //顶点着色器函数输入结构体（包含顶点属性，如位置、法线、UV等）
                struct Attributes
                {
                    float4 positionOS : POSITION;//本地空间顶点坐标
                    float2 uv0 : TEXCOORD0;//第一套纹理坐标
                    float3 normalOS : NORMAL; //本地坐标法线
                };

                //由顶点着色器，传递给片元着色器函数输入结构体（包含从顶点着色器传递过来的数据，如位置、法线、UV等）
                struct Varyings
                {
                    float4 positionCS : SV_POSITION;//裁剪空间顶点坐标
                    float2 uv0 : TEXCOORD0;//第一套纹理坐标
                    float3 normalWS : TEXCOORD1;//世界坐标法线
                };

                //顶点着色器函数：处理顶点（如位置、法线、UV等）（返回裁剪空间坐标）
                Varyings MainVS(Attributes input)
                {
                    Varyings output;//定义顶点着色器返回值

                    //position
                    VertexPositionInputs vertexInputs = GetVertexPositionInputs(input.positionOS.xyz);//转换顶点空间
                    output.positionCS = vertexInputs.positionCS;//将裁剪空间坐标传递给输出变量

                    //normal
                    VertexNormalInputs vertexNormalInputs = GetVertexNormalInputs(input.normalOS);//转换法线空间
                    output.normalWS = vertexNormalInputs.normalWS;//将世界坐标法线传递给输出变量

                    //uv
                    output.uv0 = input.uv0;//将纹理坐标传递给输出变量

                    return output;//返回输出变量
                }
                //片元着色器函数：处理像素（如颜色、纹理采样、光照等）（返回最终颜色）
                half4 MainFS(Varyings input): SV_TARGET
                {
                    Light light = GetMainLight();//获取主光源信息（如方向、颜色等）

                    //normalize vector
                    half3 N = normalize(input.normalWS);//法线向量归一化
                    half3 L = normalize(light.direction);//光照方向向量归一化
                    half NoL = saturate(dot(N, L));//法线与光照方向的点积（用于计算漫反射强度）

                    //texture sampling
                    half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv0);//从基础贴图采样颜色（使用纹理坐标）
                    half4 lightMap = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, input.uv0);//从光照贴图采样颜色（使用纹理坐标）

                    //lambert diffuse lighting
                    half Lambert = NoL; //兰伯特漫反射（基于法线与光照方向的点积）（此时为-1~1）
                    half halfLambert = NoL * 0.5 + 0.5; //半兰伯特漫反射（增加了环境光照的影响，使阴影部分更亮）（此时为0~1）
                    halfLambert *= pow(halfLambert,2); //增强半兰伯特效果（通过幂函数增加亮度差异，使阴影部分更暗，亮部更亮）

                    //AO
                    #if _USE_LIGHTMAP_AO
                        half ambient = lightMap.g;//环境光（从光照贴图G通道采样）
                    #else
                        half ambient = halfLambert;//环境光（不使用光照贴图AO时默认为半兰伯特漫反射）
                    #endif    
                    half shadow = (ambient + halfLambert) * 0.5;//阴影（环境光与半兰伯特漫反射的平均值）
                    //shadow = 0.95 <= ambient ? 1 : shadow;//阴影修正（如果阴影值大于0.95，则强制为1，避免过亮）
                    //shadow = 0.05 >= ambient ? 0 : shadow;//阴影修正（如果阴影值小于0.05，则强制为0，避免过暗）
                    shadow = lerp(shadow,1,step(0.95,ambient));//阴影修正（使用线性插值函数，根据环境光值调整阴影值，避免过亮）
                    shadow = lerp(shadow,0,step(ambient,0.05));//阴影修正（使用线性插值函数，根据环境光值调整阴影值，避免过暗）

                    //final color calculation
                    half3 finalColor = baseMap.rgb * halfLambert  * (shadow + 0.2);//最终颜色（RGB来自基础贴图）

                    return half4(finalColor.rgb, 1);//返回最终颜色（RGB来自基础贴图，Alpha来自基础贴图）
                }

            ENDHLSL//着色器程序结束
        }
    }
}
```

## 3.色阶阴影

### 0.对比图：

![色阶阴影对比图](C:\Users\Qian Yukang\Pictures\Screenshots\色阶阴影对比图.png)

### 1.手写函数无法获取想要的结果，建议使用官方的标准函数

该函数用于计算ramp图纵向行数

```c
//根据lightMap的Alpha值选择ramp行（手写）
half RampShadowID(half input)
{
    half row = 0.1;//默认第一行

    if (input > 0.8) row = 0.9;//第五行
    else if (input > 0.6) row = 0.7;//第四行
    else if (input > 0.4) row = 0.5;//第三行
    else if (input > 0.2) row = 0.3;//第二行

     return row;//返回
}

// 官方版本的RampShadowID函数
float RampShadowID(float input, float useShadow2, float useShadow3, float useShadow4, float useShadow5, 
    float shadowValue1, float shadowValue2, float shadowValue3, float shadowValue4, float shadowValue5)
{
    // 根据input值将模型分为5个区域
    float v1 = step(0.6, input) * step(input, 0.8); // 0.6-0.8区域
    float v2 = step(0.4, input) * step(input, 0.6); // 0.4-0.6区域
    float v3 = step(0.2, input) * step(input, 0.4); // 0.2-0.4区域
    float v4 = step(input, 0.2);                    // 0-0.2区域

    // 根据开关控制是否使用不同材质的值
    float blend12 = lerp(shadowValue1, shadowValue2, useShadow2);
    float blend15 = lerp(shadowValue1, shadowValue5, useShadow5);
    float blend13 = lerp(shadowValue1, shadowValue3, useShadow3);
    float blend14 = lerp(shadowValue1, shadowValue4, useShadow4);

    // 根据区域选择对应的材质值
    float result = blend12;                // 默认使用材质1或2
    result = lerp(result, blend15, v1);    // 0.6-0.8区域使用材质5
    result = lerp(result, blend13, v2);    // 0.4-0.6区域使用材质3
    result = lerp(result, blend14, v3);    // 0.2-0.4区域使用材质4
    result = lerp(result, shadowValue1, v4); // 0-0.2区域使用材质1

    return result;
}
```



### 2.在片元着色器中，确定ramp图的纵坐标时也要使用官方模板

```c
half rampID = RampShadowID(lightMap.a , _UseRampShadow2 , _UseRampShadow3 , _UseRampShadow4 , _UseRampShadow5 , 1 , 2 , 3 , 4 ,                            5);//根据lightMap的Alpha通道确定ramp行
half rampV = 0.45 - (rampID - 1) * 0.1;//确定纵坐标（根据rampID计算纵坐标）(官方版本方程式)
```



### 3.日夜开关

使用的ramp图分为上下两部分分别对应白天和夜晚

```c
Properties//开放给外界的属性（在材质面板中可见）（大致等于C#中的public变量）
    {
        //日夜切换开关
        [Header(Lighting Options)]
        _DayOrNight ("Day Or Night",Range(0,1)) = 0//日夜切换参数
    }
    
    
//Ramp
                    
half2 rampDayUV = half2(rampU,rampV + 0.5);//确定白天Ramp图UV
half3 rampDayColor = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, rampDayUV).rgb;//从色阶阴影贴图采样颜色（使用计算得到的UV坐标）(白天)
half2 rampNightUV = half2(rampU,rampV);//确定晚上Ramp图UV
half3 rampNightColor = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, rampNightUV).rgb;//从色阶阴影贴图采样颜色（使用计算得到的UV坐标）（夜晚）
                    
half3 rampColor = lerp(rampDayColor,rampNightColor,_DayOrNight);//根据lerp函数来确定选择最终颜色
```



### 4.顶点颜色

顶点颜色中也储存了一些阴影相关的信息，为了使阴影边缘更柔和，额外加入顶点颜色的G通道来计算ramp图的横坐标

```c
//顶点着色器函数输入结构体（包含顶点属性，如位置、法线、UV等）
struct Attributes
{
    float4 color : COLOR0;//顶点颜色
};

//由顶点着色器，传递给片元着色器函数输入结构体（包含从顶点着色器传递过来的数据，如位置、法线、UV等）
struct Varyings
{
	float4 color : TEXCOORD2;//顶点颜色
};

//顶点着色器函数：处理顶点（如位置、法线、UV等）（返回裁剪空间坐标）
Varyings MainVS(Attributes input)
{                   
    //color
    output.color = input.color;//将顶点颜色传递给输出变量

    return output;//返回输出变量
}

//lambert diffuse lighting
half lambertstep = smoothstep(0.01,0.4,halfLambert);//在[0.01,4]区间进行线性插值
half shadowFactor = lerp(0,halfLambert,lambertstep);//计算阴影因子

//AO
half rampWidthFactor = vertexColor * 2 * _ShadowRampWidth;//通过顶点颜色G通道控制Ramp宽度
half ShadowPosition = (_ShadowPosition - shadowFactor) / _ShadowPosition;//带入阴影因子确定阴影位置

//Ramp
half rampU = 1 - saturate(shadowDepth / rampWidthFactor);//确定横坐标
```



## 4.面部阴影（SDF）

### 0.效果对比图

![面部阴影对比图](C:\Users\Qian Yukang\Pictures\Screenshots\面部阴影对比图.png)

### 1.为达到SDF面部阴影需要要使用到一张SDF贴图和一张遮罩贴图

使用两张贴图时要记得在引擎中选中关闭sRGB选项

#### SDF贴图：

<img src="C:\Users\Qian Yukang\Pictures\Screenshots\Avatar_Girl_Tex_FaceLightmap.png" alt="Avatar_Girl_Tex_FaceLightmap" style="zoom:33%;" />

#### 遮罩贴图：

使眼部和脖子不受影响（图看不清是背景原因）

<img src="C:\Users\Qian Yukang\Pictures\Screenshots\Avatar_Tex_Face_Shadow.png" alt="Avatar_Tex_Face_Shadow" style="zoom: 50%;" />

```c
Properties//开放给外界的属性（在材质面板可见 ）（大致等于C#中的public变量)
{
    //SDF面部阴影
    [Header(Shadow Option)]//阴影选项标题
    [Toggle (_USE_SDF_SHADOW)] _UseSDFShadow ("Use SDF Shadow" , Range(0,1)) = 1//SDF阴影开关
    _SDF ("SDF" , 2D) = "white"{}//距离场纹理
    _ShadowMask ("Shadow Mask" , 2D) = "white"{}//阴影遮罩
    _ShadowColor ("Shadow Color" , Color) = (1 , 0.87 , 0.87 , 1)//阴影颜色

    [Header(Head directiontion)]//头部向量标题
    [HideInInspector] _HeadForward ("Head Forward" , Vector) = (0,0,1,0)//面部前方
    [HideInInspector] _HeadRight ("Head Right" , Vector) = (1,0,0,0)//面部右方
    [HideInInspector] _HeadUp ("Head Up" , Vector) = (0,1,0,0)//面部上方
}

HLSLINCLUDE//公共代码块开始（可以在多个Pass中共享)

    #pragma shader_feature_local _USE_SDF_SHADOW//SDF开关

    //Shadow Option
    TEXTURE2D(_SDF);//声明SDF贴图变量
    SAMPLER(sampler_SDF);//声明SDF贴图采样器变量
    TEXTURE2D(_ShadowMask);//声明阴影遮罩变量
    SAMPLER(sampler_ShadowMask);//声明阴影遮罩采样器变量

    CBUFFER_START(UnityPerMaterial)//常量缓冲区开始

        //Shadow Option
        float4 _ShadowColor;//阴影颜色

        //HaedDiraction
        float3 _HeadForward;//阴影前方
        float3 _HeadRight;//阴影右方
        float3 _HeadUp;//阴影上方

    CBUFFER_END//常量缓冲区结束

ENDHLSL//公共代码块结束

half4 MainFS(Varyings input) :SV_TARGET
{
    //normalize vector
    half3 headUpDir = normalize(_HeadUp);//归一化面部上方向量
    half3 headForwardDir = normalize(_HeadForward);//归一化面部前方向量
    half3 headRightDir = normalize(_HeadRight);//归一化面部右方向量

    //Face SDF Shadow
    half3 LpU = dot(L, headUpDir) / pow(length(headUpDir), 2) * headUpDir; // 计算光源方向在面部上方的投影
    half3 LpHeadHorizon = normalize(L- LpU); // 光照方向在头部水平面上的投影
    half value = acos(dot(LpHeadHorizon, headRightDir)) / 3.141592654; // 计算光照方向与面部右方的夹角
    half exposeRight = step(value, 0.5); // 判断光照是来自右侧还是左侧
    half valueR = pow(1 - value * 2, 3); // 右侧阴影强度
    half valueL = pow(value * 2 - 1, 3); // 左侧阴影强度
    half mixValue = lerp(valueL, valueR, exposeRight); // 混合阴影强度
    half sdfLeft = SAMPLE_TEXTURE2D(_SDF, sampler_SDF, half2(1 - input.uv0.x, input.uv0.y)).r; // 左侧距离场
    half sdfRight = SAMPLE_TEXTURE2D(_SDF, sampler_SDF, input.uv0).r; // 右侧距离场
    half mixSdf = lerp(sdfRight, sdfLeft, exposeRight); // 采样SDF纹理
    half sdf = step(mixValue, mixSdf); // 计算硬边界阴影
    sdf = lerp(0, sdf, step(0, dot(LpHeadHorizon, headForwardDir))); // 计算右侧阴影
    sdf *= shadowMask.g; // 使用G通道控制阴影强度
    sdf = lerp(sdf, 1, shadowMask.a); // 使用A通道作为阴影遮罩

    //final color
    #if _USE_SDF_SHADOW
        half3 finalColor = lerp(_ShadowColor*baseMap.rgb , baseMap.rgb , sdf);//合并最终颜色
    #else
        half3 finalColor = baseMap.rgb*halflambert*light.color;//最终颜色
    #endif

    return half4(finalColor,1);//返回最终颜色                
}
```



在使用SDF面部阴影发现旋转人物面部阴影无变化，这是因为shader中写的三个向量没有变化，需额外写一个C#脚本控制向量

```c#
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//该脚本作用：设置面部材质的方向向量

[ExecuteInEditMode]//在编辑器中实现
public class NewBehaviourScript : MonoBehaviour
{
    public Transform Head;//头部骨骼
    public Transform HeadForward;//前方
    public Transform HeadRight;//右方
    public Transform HeadUp;//上方
    public Material FaceMaterial;

    // Update is called once per frame
    void Update()
    {
        //归一化向量
        Vector3 headForward = Vector3.Normalize(HeadForward.position - Head.position);
        Vector3 headRight = Vector3.Normalize(HeadRight.position - Head.position);
        Vector3 headUp = Vector3.Normalize(HeadUp.position - Head.position);

        //传递向量
        FaceMaterial.SetVector("_HeadForward",headForward);
        FaceMaterial.SetVector("_HeadRight",headRight);
        FaceMaterial.SetVector("_HeadUp",headUp);

    }
}
```

之后在头部骨骼下创建三个空物体，分别代表上前右三个方向的向量，将脚本挂载到头部，最后将头部骨骼和三个向量（空物体）和面部材质挂载到脚本上

### 2.添加腮红

观察baseMap的Alpha通道可以发现贴图在腮红处才有白色，可以将其当作一张遮罩贴图来制作腮红

<div align="left">     <img src="C:\Users\Qian Yukang\Pictures\Screenshots\屏幕截图 2026-04-26 171251.png" alt="屏幕截图 2026-04-26 171251" /> </div>

```c
Properties//开放给外界的属性（在材质面板可见 ）（大致等于C#中的public变量)
{
    [Header(Face blush)]//脸部腮红标题
    _FaceBlushColor ("Face Blush Color" , Color) = (1,0,0,1)//腮红颜色
    _FaceBlushStrength ("Face Blush Strength" , Range(0,1)) = 0//腮红强度调节
}

CBUFFER_START(UnityPerMaterial)//常量缓冲区开始

    //Face Blush
    float4 _FaceBlushColor;//腮红颜色
    float _FaceBlushStrength;//腮红强度

CBUFFER_END//常量缓冲区结束

half4 MainFS(Varyings input) :SV_TARGET
{
    //Face Blush
    half blushStrength =lerp (0,baseMap.a,_FaceBlushStrength);

    //final color
    
	finalColor = lerp(finalColor,finalColor * _FaceBlushColor.rgb,blushStrength);

    return half4(finalColor,1);//返回最终颜色

}
```



## 5.阴影投射

### 0.效果图

![屏幕截图 2026-04-26 200821](C:\Users\Qian Yukang\Pictures\Screenshots\屏幕截图 2026-04-26 200821.png)

### 1.代码

额外写一个pass渲染通道

```c
Pass //渲染通道 阴影投射
{
    Name "ShadowCaster"
    Tags
    {
        "LightMode" = "ShadowCaster"//光照模式：阴影投射
    }

    ZWrite On //写入深度缓冲区
    ZTest LEqual //速度测试：小于等于
    ColorMask 0 //不写入颜色缓冲区
    Cull Off //不裁剪

    HLSLPROGRAM //着色器程序开始

        #pragma multi_compile_instancing // 启用GPU实例化编译
        #pragma multi_compile _ DOTS_INSTANCING_ON // 启用DOTS实例化编译
        #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW // 启用点光源阴影

        #pragma vertex ShadowVS //声明顶点着色器函数
        #pragma fragment ShadowFS //声明片元着色器函数

        float3 _LightDirection; // 光源方向
        float3 _LightPosition; // 光源位置

        //顶点着色器输入参数结构体
        struct Attributes
        {
            float4 positionOS : POSITION;//本地空间顶点坐标
            float3 normalOS : NORMAL;//本地空间法线
        };

        //片元着色器输入参数结构体
        struct Varyings
        {
            float4 positionCS : SV_POSITION;//裁剪空间顶点坐标
        };

        // 将阴影的世界空间顶点位置转换为适合阴影投射的裁剪空间位置
        float4 GetShadowPositionHClip(Attributes input)
        {
            float3 positionWS = TransformObjectToWorld(input.positionOS.xyz); // 将本地空间顶点坐标转换为世界空间顶点坐标
            float3 normalWS = TransformObjectToWorldNormal(input.normalOS); // 将本地空间法线转换为世界空间法线

            #if _CASTING_PUNCTUAL_LIGHT_SHADOW // 点光源
                float3 lightDirectionWS = normalize(_LightPosition - positionWS); // 计算光源方向
            #else // 平行光
                float3 lightDirectionWS = _LightDirection; // 使用预定义的光源方向
            #endif

            float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS)); // 应用阴影偏移

            // 根据平台的Z缓冲区方向调整Z值
            #if UNITY_REVERSED_Z // 反转Z缓冲区
                positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE); // 限制Z值在近裁剪平面以下
            #else // 正向Z缓冲区
                positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE); // 限制Z值在远裁剪平面以上
            #endif

            return positionCS; // 返回裁剪空间顶点坐标
        }

        //顶点着色器
        Varyings ShadowVS(Attributes input)
        {
            Varyings output;
            output.positionCS = GetShadowPositionHClip(input);

            return output;
        }

        //片元着色器
        half4 ShadowFS(Varyings input) : SV_TARGET
        {
            return 0;
        }

    ENDHLSL //着色器程序结束
}
```

### 2.注意项

1.写完后如果发现渲染出的阴影分辨率低，找到所使用的URP中将Lighting下的Shadow Resolution调高，Shadow下的Cascade Count调高

## 6.布料反面渲染

### 0.效果图：

![反面渲染对比图](C:\Users\Qian Yukang\Pictures\Screenshots\反面渲染对比图.png)

![翻转法线对比图](C:\Users\Qian Yukang\Pictures\Screenshots\翻转法线对比图.png)

### 1.反面渲染

默认情况下只渲染正面这时需要添加一个pass通道用用于渲染反面

### 2.翻转法线

当增加完反面渲染时，发现布料的正反面一样，这时需要通过翻转法线让布料正确的渲染出背面效果，我们需要新增一个顶点着色器函数来翻转法线

```c
Pass//渲染通道 反面
{
    Name"UniversalForward"//通道名称（可选）
    Tags
    {
        "LightMode" = "SRPDefaultUnlit"//指定光照模式（URP前向渲染）
        "Quene" = "Geometry+1"//渲染队列：确保在正面之后渲染
    }

    //Cull Back //背面剔除
    Cull Front //剔除模式

    HLSLPROGRAM //着色器程序开始

        #pragma vertex BackMainVS//声明顶点着色器函数
        #pragma fragment MainFS//声明片元着色器函数

        UniversalVaryings BackMainVS(UniversalAttributes input)
        {
            UniversalVaryings output = MainVS(input);
            output.uv0 = input.uv1;//将uv0替换成uv1
            output.normalWS = -output.normalWS;//翻转法线方向

            return output;
        }

    ENDHLSL//着色器程序结束
}
```



## 7.边缘光

### 0.效果图

![](C:\Users\Qian Yukang\Pictures\Screenshots\菲涅尔边缘光对比图.png)

### 1.边缘光

我这里使用的是菲涅尔边缘光，原神实际使用的是深度偏移边缘光

```
Properties//开放给外界的属性（在材质面板中可见）（大致等于C#中的public变量）
{
    //菲涅尔边缘光
    [Header(Fresnel Rim Lighting)]
    [Toggle(_USE_RIM_LIGHTING)] _UseRimLighting("Use Rim Lighting", Range(0,1)) = 1
    [HDR] _RimColor ("Rim Color", Color) = (0.3, 0.3, 0.3, 1)// 边缘光颜色（建议 HDR，配合 Bloom 更好看）
    _FresnelPower ("Fresnel Power", Range(0.1, 10)) = 3.0// 边缘光范围（菲涅尔幂次，越大边缘光越窄，推荐 2~5）
    _RimIntensity ("Rim Intensity", Range(0, 5)) = 1.0// 边缘光强度（独立亮度控制，方便脚本驱动）
}

HLSLINCLUDE//公共代码块开始（可以在多个Pass中共享）

    #pragma shader_feature_local _USE_RIM_LIGHTING // 是否使用边缘光

    CBUFFER_START(UnityPerMaterial)//常量缓冲区开始
        //Fresnel Rim Lighting
        float4 _RimColor;//边缘光颜色
        float _FresnelPower;//边缘光范围
        float _RimIntensity;//边缘光强度
    CBUFFER_END//常量缓冲区结束

    //由顶点着色器，传递给片元着色器函数输入结构体（包含从顶点着色器传递过来的数据，如位置、法线、UV等）
    struct UniversalVaryings
    {
        float3 positionWS : TEXCOORD3;
    };

    //顶点着色器函数：处理顶点（如位置、法线、UV等）（返回裁剪空间坐标）
    UniversalVaryings MainVS(UniversalAttributes input)
    {
        output.positionWS = vertexInputs.positionWS;//将世界空间坐标传递给输出变量
    }

    //片元着色器函数：处理像素（如颜色、纹理采样、光照等）（返回最终颜色）
    half4 MainFS(UniversalVaryings input): SV_TARGET
    {
        //Fresnel Rim Lighting
        half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - input.positionWS);//视线方向（从顶点指向摄像机）
        half NdotV = saturate(dot(N,viewDir));//法线与视线方向的点积（视角与法线越垂直，值越接近0）
        half fresnel  = pow(1.0 - NdotV,_FresnelPower);//菲涅尔系数（视角越平行于表面，fresnel越大，边缘越亮）


        //final color calculation
        #if _USE_RIM_LIGHTING
            half3 rimColor = _RimColor.rgb * fresnel * _RimIntensity;
            finalColor += rimColor;
        #endif
	}
ENDHLSL//公共代码块结束
```



## A0.Source code

### 1.身体

```c
Shader "GenshinToon/Body"//着色器名称（在材质面板中可见）
{
    Properties//开放给外界的属性（在材质面板中可见）（大致等于C#中的public变量）
    {
        [Header(Textures)]//属性分组标题（在材质面板中显示为分组标题）
        _BaseMap("Base Map", 2D) = "white" {}//基础贴图属性（名称、类型、默认值）
        _LightMap("LightMap",2D) = "white" {}//光照贴图属性（名称、类型、默认值）
        [Toggle(_USE_LIGHTMAP_AO)] _UseLightMapAO("Use LightMap AO", Range(0,1)) = 1//是否使用光照贴图AO属性（名称、类型、默认值）

        [Header(RampShadow)]
         _RampTex ("Ramp Tex", 2D) = "white" {}//色阶阴影贴图属性（名称、类型、默认值）
        [Toggle(_USE_RAMP_SHADOW)] _UseRampShadow("Use Ramp Shadow", Range(0,1)) = 1//是否使用色阶阴影贴图属性（名称、类型、默认值）
        _ShadowRampWidth ("Shadow Ramp Width" , Float) = 1//阴影色阶宽度属性（名称、类型、默认值）
        _ShadowPosition ("Shadow Position", Float) = 0.55//阴影位置属性（名称、类型、默认值）
        _ShadowSoftness ("Shadow Softness", Float) = 0.5//阴影柔和度属性（名称、类型、默认值）
        [Toggle] _UseRampShadow2 ("Use Ramp Shadow 2" , Range(0,1)) = 1//使用第2行Ramp开关
        [Toggle] _UseRampShadow3 ("Use Ramp Shadow 3" , Range(0,1)) = 1//使用第3行Ramp开关
        [Toggle] _UseRampShadow4 ("Use Ramp Shadow 4" , Range(0,1)) = 1//使用第4行Ramp开关
        [Toggle] _UseRampShadow5 ("Use Ramp Shadow 5" , Range(0,1)) = 1//使用第5行Ramp开关
        
        //日夜切换开关
        [Header(Lighting Options)]
        _DayOrNight ("Day Or Night",Range(0,1)) = 0//日夜切换参数
    }
    SubShader//子着色器（包含一个或多个Pass）
    {
        Tags//标签（告诉Unity这个着色器是什么类型的）
        {
            "RenderPipeline" = "UniversalPipeline"//指定渲染管线（URP）
            "RenderType" = "Opaque"//指定渲染类型（不透明）
        }
        HLSLINCLUDE//公共代码块开始（可以在多个Pass中共享）
                //包含公共代码（如预处理指令、函数、结构体、头文件、常量定义、函数定义等）
                #pragma multi_compile _MAIN_LIGHT_SHADOWS // 主光源阴影
                #pragma multi_compile _MAIN_LIGHT_SHADOWS_CASCADE // 主光源阴影级联
                #pragma multi_compile _MAIN_LIGHT_SHADOWS_SCREEN // 主光源阴影屏幕空间

                #pragma multi_compile_fragment _LIGHT_LAYERS // 光照层
                #pragma multi_compile_fragment _LIGHT_COOKIES // 光照饼干
                #pragma multi_compile_fragment _SCREEN_SPACE_OCCLUSION // 屏幕空间遮挡
                #pragma multi_compile_fragment _ADDITIONAL_LIGHT_SHADOWS // 额外光源阴影
                #pragma multi_compile_fragment _SHADOWS_SOFT // 阴影软化

                #pragma shader_feature_local _USE_LIGHTMAP_AO // 是否使用光照贴图AO（局部定义的着色器特性）
                #pragma shader_feature_local _USE_RAMP_SHADOW // 是否使用色阶阴影贴图（局部定义的着色器特性）

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" // 核心库
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl" // 光照库

                
                //声明纹理和采样器变量
                TEXTURE2D(_BaseMap);//声明基础贴图（纹理）变量
                SAMPLER(sampler_BaseMap);//声明基础贴图采样器变量
                TEXTURE2D(_LightMap);//声明光照贴图（纹理）变量
                SAMPLER(sampler_LightMap);//声明光照贴图采样器变量
                
                //Ramp Shadow
                TEXTURE2D(_RampTex);//声明色阶阴影贴图（纹理）变量
                SAMPLER(sampler_RampTex);//声明色阶阴影贴图采样器变量

                CBUFFER_START(UnityPerMaterial)//常量缓冲区开始
                    //Ramp Shadow
                    float _ShadowRampWidth;//阴影色阶宽度
                    float _ShadowPosition;//阴影位置
                    float _ShadowSoftness;//阴影柔和度
                    float _UseRampShadow2;//使用第2行Ramp开关
                    float _UseRampShadow3;//使用第3行Ramp开关
                    float _UseRampShadow4;//使用第4行Ramp开关
                    float _UseRampShadow5;//使用第5行Ramp开关

                    //日夜切换
                    float _DayOrNight;//日夜切换开关
                CBUFFER_END//常量缓冲区结束

                // 官方版本的RampShadowID函数
                float RampShadowID(float input, float useShadow2, float useShadow3, float useShadow4, float useShadow5, 
                    float shadowValue1, float shadowValue2, float shadowValue3, float shadowValue4, float shadowValue5)
                {
                    // 根据input值将模型分为5个区域
                    float v1 = step(0.6, input) * step(input, 0.8); // 0.6-0.8区域
                    float v2 = step(0.4, input) * step(input, 0.6); // 0.4-0.6区域
                    float v3 = step(0.2, input) * step(input, 0.4); // 0.2-0.4区域
                    float v4 = step(input, 0.2);                    // 0-0.2区域

                    // 根据开关控制是否使用不同材质的值
                    float blend12 = lerp(shadowValue1, shadowValue2, useShadow2);
                    float blend15 = lerp(shadowValue1, shadowValue5, useShadow5);
                    float blend13 = lerp(shadowValue1, shadowValue3, useShadow3);
                    float blend14 = lerp(shadowValue1, shadowValue4, useShadow4);

                    // 根据区域选择对应的材质值
                    float result = blend12;                // 默认使用材质1或2
                    result = lerp(result, blend15, v1);    // 0.6-0.8区域使用材质5
                    result = lerp(result, blend13, v2);    // 0.4-0.6区域使用材质3
                    result = lerp(result, blend14, v3);    // 0.2-0.4区域使用材质4
                    result = lerp(result, shadowValue1, v4); // 0-0.2区域使用材质1

                    return result;
                }

                //顶点着色器函数输入结构体（包含顶点属性，如位置、法线、UV等）
                struct UniversalAttributes
                {
                    float4 positionOS : POSITION;//本地空间顶点坐标
                    float2 uv0 : TEXCOORD0;//第一套纹理坐标
                    float2 uv1 : TEXCOORD1;//第二套纹理坐标
                    float3 normalOS : NORMAL; //本地坐标法线
                    float4 color : COLOR0;//顶点颜色
                };
                
                //由顶点着色器，传递给片元着色器函数输入结构体（包含从顶点着色器传递过来的数据，如位置、法线、UV等）
                struct UniversalVaryings
                {
                    float4 positionCS : SV_POSITION;//裁剪空间顶点坐标
                    float2 uv0 : TEXCOORD0;//第一套纹理坐标
                    float3 normalWS : TEXCOORD1;//世界坐标法线
                    float4 color : TEXCOORD2;//顶点颜色
                };

                //顶点着色器函数：处理顶点（如位置、法线、UV等）（返回裁剪空间坐标）
                UniversalVaryings MainVS(UniversalAttributes input)
                {
                    UniversalVaryings output;//定义顶点着色器返回值

                    //position
                    VertexPositionInputs vertexInputs = GetVertexPositionInputs(input.positionOS.xyz);//转换顶点空间
                    output.positionCS = vertexInputs.positionCS;//将裁剪空间坐标传递给输出变量

                    //normal
                    VertexNormalInputs vertexNormalInputs = GetVertexNormalInputs(input.normalOS);//转换法线空间
                    output.normalWS = vertexNormalInputs.normalWS;//将世界坐标法线传递给输出变量

                    //uv
                    output.uv0 = input.uv0;//将纹理坐标传递给输出变量
                    
                    //color
                    output.color = input.color;//将顶点颜色传递给输出变量

                    return output;//返回输出变量
                }

                //片元着色器函数：处理像素（如颜色、纹理采样、光照等）（返回最终颜色）
                half4 MainFS(UniversalVaryings input): SV_TARGET
                {
                    Light light = GetMainLight();//获取主光源信息（如方向、颜色等）
                    half4 vertexColor = input.color;//获取顶点颜色

                    //normalize vector
                    half3 N = normalize(input.normalWS);//法线向量归一化
                    half3 L = normalize(light.direction);//光照方向向量归一化
                    half NoL = saturate(dot(N, L));//法线与光照方向的点积（用于计算漫反射强度）

                    //texture sampling
                    half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv0);//从基础贴图采样颜色（使用纹理坐标）
                    half4 lightMap = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, input.uv0);//从光照贴图采样颜色（使用纹理坐标）

                    //lambert diffuse lighting
                    half Lambert = NoL; //兰伯特漫反射（基于法线与光照方向的点积）（此时为-1~1）
                    half halfLambert = NoL * 0.5 + 0.5; //半兰伯特漫反射（增加了环境光照的影响，使阴影部分更亮）（此时为0~1）
                    halfLambert *= pow(halfLambert,2); //增强半兰伯特效果（通过幂函数增加亮度差异，使阴影部分更暗，亮部更亮）
                    half lambertstep = smoothstep(0.01,0.4,halfLambert);//在[0.01,4]区间进行线性插值
                    half shadowFactor = lerp(0,halfLambert,lambertstep);//计算阴影因子

                    //AO
                    #if _USE_LIGHTMAP_AO
                        half ambient = lightMap.g;//环境光（从光照贴图G通道采样）
                    #else
                        half ambient = halfLambert;//环境光（不使用光照贴图AO时默认为半兰伯特漫反射）
                    #endif    
                    half shadow = (ambient + halfLambert) * 0.5;//阴影（环境光与半兰伯特漫反射的平均值）
                    //shadow = 0.95 <= ambient ? 1 : shadow;//阴影修正（如果阴影值大于0.95，则强制为1，避免过亮）
                    //shadow = 0.05 >= ambient ? 0 : shadow;//阴影修正（如果阴影值小于0.05，则强制为0，避免过暗）
                    shadow = lerp(shadow,1,step(0.95,ambient));//阴影修正（使用线性插值函数，根据环境光值调整阴影值，避免过亮）
                    shadow = lerp(shadow,0,step(ambient,0.05));//阴影修正（使用线性插值函数，根据环境光值调整阴影值，避免过暗）
                    half isShadowArea = step(shadow,_ShadowPosition);//判断是否处于阴影区域
                    half shadowDepth = saturate(_ShadowPosition - shadow) / _ShadowPosition;//阴影深度
                    shadowDepth = pow(shadowDepth,_ShadowSoftness);//根据柔和度阴影深度
                    shadowDepth = min(shadowDepth,1);//min函数将阴影深度限制在1以下（取shadow和1的较小数）
                    half rampWidthFactor = vertexColor * 2 * _ShadowRampWidth;//通过顶点颜色G通道控制Ramp宽度
                    half ShadowPosition = (_ShadowPosition - shadowFactor) / _ShadowPosition;//带入阴影因子确定阴影位置

                    //Ramp
                    half rampU = 1 - saturate(shadowDepth / rampWidthFactor);//确定横坐标
                    half rampID = RampShadowID(lightMap.a , _UseRampShadow2 , _UseRampShadow3 , _UseRampShadow4 , _UseRampShadow5 , 1 , 2 , 3 , 4 , 5);//根据lightMap的Alpha通道确定ramp行
                    half rampV = 0.45 - (rampID - 1) * 0.1;//确定纵坐标（根据rampID计算纵坐标）(官方版本方程式)
                    
                    half2 rampDayUV = half2(rampU,rampV + 0.5);//确定白天Ramp图UV
                    half3 rampDayColor = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, rampDayUV).rgb;//从色阶阴影贴图采样颜色（使用计算得到的UV坐标）(白天)
                    half2 rampNightUV = half2(rampU,rampV);//确定晚上Ramp图UV
                    half3 rampNightColor = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, rampNightUV).rgb;//从色阶阴影贴图采样颜色（使用计算得到的UV坐标）（夜晚）
                    
                    half3 rampColor = lerp(rampDayColor,rampNightColor,_DayOrNight);//根据lerp函数来确定选择最终颜色
                    

                    //final color calculation
                    #if _USE_RAMP_SHADOW // 使用ramp阴影贴图
                        half3 finalColor = baseMap.rgb * rampColor * (isShadowArea ? 1 : 1.2);//最终颜色，使用ramp阴影
                    #else // 不使用ramp阴影贴图
                        half3 finalColor = baseMap.rgb * halfLambert  * (shadow + 0.2);//最终颜色,使用兰伯特阴影
                    #endif

                    return half4(finalColor.rgb, 1);//返回最终颜色（RGB来自基础贴图，Alpha来自基础贴图）
                }

            ENDHLSL//公共代码块结束
        Pass//渲染通道 正面
        {
            Name"UniversalForward"//通道名称（可选）
            Tags
            {
                "LightMode" = "UniversalForward"//指定光照模式（URP前向渲染）
            }
            
            //Cull Back //背面剔除
            Cull Back //剔除模式

            HLSLPROGRAM //着色器程序开始

                #pragma vertex MainVS//声明顶点着色器函数
                #pragma fragment MainFS//声明片元着色器函数

            ENDHLSL//着色器程序结束
        }

        Pass//渲染通道 反面
        {
            Name"UniversalForward"//通道名称（可选）
            Tags
            {
                "LightMode" = "SRPDefaultUnlit"//指定光照模式（URP前向渲染）
                "Quene" = "Geometry+1"//渲染队列：确保在正面之后渲染
            }
            
            //Cull Back //背面剔除
            Cull Front //剔除模式

            HLSLPROGRAM //着色器程序开始

                #pragma vertex BackMainVS//声明顶点着色器函数
                #pragma fragment MainFS//声明片元着色器函数

                UniversalVaryings BackMainVS(UniversalAttributes input)
                {
                    UniversalVaryings output = MainVS(input);
                    output.uv0 = input.uv1;//将uv0替换成uv1
                    output.normalWS = -output.normalWS;//翻转法线方向

                    return output;
                }

            ENDHLSL//着色器程序结束
        }

        Pass //渲染通道 阴影投射
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"//光照模式：阴影投射
            }

            ZWrite On //写入深度缓冲区
            ZTest LEqual //速度测试：小于等于
            ColorMask 0 //不写入颜色缓冲区
            Cull Off //不裁剪

            HLSLPROGRAM //着色器程序开始

                #pragma multi_compile_instancing // 启用GPU实例化编译
                #pragma multi_compile _ DOTS_INSTANCING_ON // 启用DOTS实例化编译
                #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW // 启用点光源阴影

                #pragma vertex ShadowVS //声明顶点着色器函数
                #pragma fragment ShadowFS //声明片元着色器函数

                float3 _LightDirection; // 光源方向
                float3 _LightPosition; // 光源位置

                //顶点着色器输入参数结构体
                struct Attributes
                {
                    float4 positionOS : POSITION;//本地空间顶点坐标
                    float3 normalOS : NORMAL;//本地空间法线
                };

                //片元着色器输入参数结构体
                struct Varyings
                {
                    float4 positionCS : SV_POSITION;//裁剪空间顶点坐标
                };

                // 将阴影的世界空间顶点位置转换为适合阴影投射的裁剪空间位置
                float4 GetShadowPositionHClip(Attributes input)
                {
                    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz); // 将本地空间顶点坐标转换为世界空间顶点坐标
                    float3 normalWS = TransformObjectToWorldNormal(input.normalOS); // 将本地空间法线转换为世界空间法线

                    #if _CASTING_PUNCTUAL_LIGHT_SHADOW // 点光源
                        float3 lightDirectionWS = normalize(_LightPosition - positionWS); // 计算光源方向
                    #else // 平行光
                        float3 lightDirectionWS = _LightDirection; // 使用预定义的光源方向
                    #endif

                    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS)); // 应用阴影偏移

                    // 根据平台的Z缓冲区方向调整Z值
                    #if UNITY_REVERSED_Z // 反转Z缓冲区
                        positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE); // 限制Z值在近裁剪平面以下
                    #else // 正向Z缓冲区
                        positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE); // 限制Z值在远裁剪平面以上
                    #endif

                    return positionCS; // 返回裁剪空间顶点坐标
                }

                //顶点着色器
                Varyings ShadowVS(Attributes input)
                {
                    Varyings output;
                    output.positionCS = GetShadowPositionHClip(input);

                    return output;
                }

                //片元着色器
                half4 ShadowFS(Varyings input) : SV_TARGET
                {
                    return 0;
                }

            ENDHLSL //着色器程序结束
        }
    }
}
//26，04，22色阶阴影（写到RampShadowID函数）
//26，04，22色阶阴影（完成）
//26，04，24面部阴影（SDF）（完成）
//26，04，26阴影投射（完成）
//26，04，26布料反面渲染（完成）
```

### 2.面部

```c
Shader "GenshinToon/Face"//着色器名称（搁材质面板可见）
{
    Properties//开放给外界的属性（在材质面板可见 ）（大致等于C#中的public变量)
    {
        //基础贴图
        [Header(Textures)]//属性分组标题（在材质面板中显示为分组标题）
        _BaseMap("Base Map",2D) = "white"{}//基础贴图属性（名称、类型、默认值）

        //SDF面部阴影
        [Header(Shadow Option)]//阴影选项标题
        [Toggle (_USE_SDF_SHADOW)] _UseSDFShadow ("Use SDF Shadow" , Range(0,1)) = 1//SDF阴影开关
        _SDF ("SDF" , 2D) = "white"{}//距离场纹理
        _ShadowMask ("Shadow Mask" , 2D) = "white"{}//阴影遮罩
        _ShadowColor ("Shadow Color" , Color) = (1 , 0.87 , 0.87 , 1)//阴影颜色

        [Header(Head directiontion)]//头部向量标题
        [HideInInspector] _HeadForward ("Head Forward" , Vector) = (0,0,1,0)//面部前方
        [HideInInspector] _HeadRight ("Head Right" , Vector) = (1,0,0,0)//面部右方
        [HideInInspector] _HeadUp ("Head Up" , Vector) = (0,1,0,0)//面部上方

        [Header(Face blush)]//脸部腮红标题
        _FaceBlushColor ("Face Blush Color" , Color) = (1,0,0,1)//腮红颜色
        _FaceBlushStrength ("Face Blush Strength" , Range(0,1)) = 0//腮红强度调节

    }
    SubShader//子着色器（包含一个或多个Pass)
    {
        Tags//标签（告诉unity这个着色器是什么类型的）
        {
            "RenderPipeline" = "UniversalPipeline"//指定渲染管线（URP）
            "RenderType" = "Opaque"//指定渲染类型（不透明）
        }
        HLSLINCLUDE//公共代码块开始（可以在多个Pass中共享)
            //包含公共代码（如预处理指令、函数、结构体、头文件、常量定义、函数定义等）
            #pragma multi_compile _MAIN_LIGHT_SHADOWS // 主光源阴影
            #pragma multi_compile _MAIN_LIGHT_SHADOWS_CASCADE // 主光源阴影级联
            #pragma multi_compile _MAIN_LIGHT_SHADOWS_SCREEN // 主光源阴影屏幕空间

            #pragma multi_compile_fragment _LIGHT_LAYERS // 光照层
            #pragma multi_compile_fragment _LIGHT_COOKIES // 光照饼干
            #pragma multi_compile_fragment _SCREEN_SPACE_OCCLUSION // 屏幕空间遮挡
            #pragma multi_compile_fragment _ADDITIONAL_LIGHT_SHADOWS // 额外光源阴影
            #pragma multi_compile_fragment _SHADOWS_SOFT // 阴影软化

            #pragma shader_feature_local _USE_SDF_SHADOW//SDF开关

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" // 核心库
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl" // 光照库

            //Texture
            TEXTURE2D(_BaseMap);//声明基础贴图（纹理）变量
            SAMPLER(sampler_BaseMap);//声明基础贴图采样器变量

            //Shadow Option
            TEXTURE2D(_SDF);//声明SDF贴图变量
            SAMPLER(sampler_SDF);//声明SDF贴图采样器变量
            TEXTURE2D(_ShadowMask);//声明阴影遮罩变量
            SAMPLER(sampler_ShadowMask);//声明阴影遮罩采样器变量

            CBUFFER_START(UnityPerMaterial)//常量缓冲区开始
                
                //Shadow Option
                float4 _ShadowColor;//阴影颜色

                //HaedDiraction
                float3 _HeadForward;//阴影前方
                float3 _HeadRight;//阴影右方
                float3 _HeadUp;//阴影上方

                //Face Blush
                float4 _FaceBlushColor;//腮红颜色
                float _FaceBlushStrength;//腮红强度

            CBUFFER_END//常量缓冲区结束

        ENDHLSL//公共代码块结束

        Pass//渲染通道
        {
            Name"UniversalForward"//通道名称
            Tags
            {
                "LightMode" = "UniversalForward"//指定光照项目（通用前向渲染）
            }
            HLSLPROGRAM//着色器程序开始

                #pragma vertex MainVS//声明顶点着色器函数
                #pragma fragment MainFS//声明片元着色器函数

                //顶点着色器函数输入结构体（包含顶点属性，如位置、法线、UV等）
                struct Attributes
                {
                    float4 positionOS : POSITION;//本地空顶点坐标
                    float2 uv0 : TEXCOORD0;//第一套纹理坐标
                    float3 normalOS : NORMAL;//本地坐标法线
                };

                //由顶点着色器，传递给片元着色器函数输入结构体（包含从顶点着色器传递过来的数据，如位置、法线、uv等）
                struct Varyings
                {
                    float4 positionCS : SV_POSITION;//裁剪空间顶点坐标
                    float2 uv0 : TEXCOORD0;//第一套纹理坐标
                    float3 normalWS : TEXCOORD1;//世界坐标法线
                };
                
                //顶点着色器函数：处理顶点（如位置、法线、uv等）（返回裁剪空间坐标）
                Varyings MainVS(Attributes input)
                {
                    Varyings output;//定义顶点着色器返回值

                    //position
                    VertexPositionInputs vertexInputs = GetVertexPositionInputs(input.positionOS.xyz);//获取顶点位置输入（如本地空间坐标、世界空间坐标、裁剪空间坐标等）
                    output.positionCS = vertexInputs.positionCS;//将裁剪空间坐标传递给输出变量

                    //normal
                    VertexNormalInputs vertexNormalInputs = GetVertexNormalInputs(input.normalOS);//获取顶点法线输入（如世界空间法线等）
                    output.normalWS = vertexNormalInputs.normalWS;//将世界坐标法线传递给输出变量

                    //uv
                    output.uv0 = input.uv0;//将第一套纹理坐标传递给输出变量

                    return output;//返回输出变量
                }

                //片元着色器函数：处理像素（如颜色、纹理采样、光照等）（返回最终颜色)
                half4 MainFS(Varyings input) :SV_TARGET
                {
                    Light light = GetMainLight();//获取主光源信息（如方向、颜色等)

                    //normalize vector
                    half3 N = normalize(input.normalWS);//法线向量归一化
                    half3 L = normalize(light.direction);//光照方向向量归一化
                    half NoL = saturate(dot(N,L));//法线与光照方向的点积（用于计算漫反射强度)
                    half3 headUpDir = normalize(_HeadUp);//归一化面部上方向量
                    half3 headForwardDir = normalize(_HeadForward);//归一化面部前方向量
                    half3 headRightDir = normalize(_HeadRight);//归一化面部右方向量

                    //sample texture
                    half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,input.uv0);//从基础贴图采样颜色（使用纹理坐标）
                    half4 shadowMask = SAMPLE_TEXTURE2D(_ShadowMask,sampler_ShadowMask,input.uv0);//采样阴影遮罩

                    //lambert diffuse lighting
                    half lambert = NoL;//兰伯特漫反射光照强度（等于法线与光照强度的点积）
                    half halflambert = lambert*0.5+0.5;//半兰伯特漫反射
                    halflambert *= pow(halflambert,2);//增强半兰伯特漫反射（使高光更明显）

                    //Face SDF Shadow
                    half3 LpU = dot(L, headUpDir) / pow(length(headUpDir), 2) * headUpDir; // 计算光源方向在面部上方的投影
                    half3 LpHeadHorizon = normalize(L- LpU); // 光照方向在头部水平面上的投影
                    half value = acos(dot(LpHeadHorizon, headRightDir)) / 3.141592654; // 计算光照方向与面部右方的夹角
                    half exposeRight = step(value, 0.5); // 判断光照是来自右侧还是左侧
                    half valueR = pow(1 - value * 2, 3); // 右侧阴影强度
                    half valueL = pow(value * 2 - 1, 3); // 左侧阴影强度
                    half mixValue = lerp(valueL, valueR, exposeRight); // 混合阴影强度
                    half sdfLeft = SAMPLE_TEXTURE2D(_SDF, sampler_SDF, half2(1 - input.uv0.x, input.uv0.y)).r; // 左侧距离场
                    half sdfRight = SAMPLE_TEXTURE2D(_SDF, sampler_SDF, input.uv0).r; // 右侧距离场
                    half mixSdf = lerp(sdfRight, sdfLeft, exposeRight); // 采样SDF纹理
                    half sdf = step(mixValue, mixSdf); // 计算硬边界阴影
                    sdf = lerp(0, sdf, step(0, dot(LpHeadHorizon, headForwardDir))); // 计算右侧阴影
                    sdf *= shadowMask.g; // 使用G通道控制阴影强度
                    sdf = lerp(sdf, 1, shadowMask.a); // 使用A通道作为阴影遮罩

                    //Face Blush
                    half blushStrength =lerp (0,baseMap.a,_FaceBlushStrength);

                    //final color
                    #if _USE_SDF_SHADOW
                        half3 finalColor = lerp(_ShadowColor*baseMap.rgb , baseMap.rgb , sdf);//合并最终颜色
                    #else
                        half3 finalColor = baseMap.rgb*halflambert*light.color;//最终颜色
                    #endif
                        finalColor = lerp(finalColor,finalColor * _FaceBlushColor.rgb,blushStrength);

                    return half4(finalColor,1);//返回最终颜色                
                }
            ENDHLSL//着色器程序结束

        }
    }    
}
```



## A1.初修:26,03,26

