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
