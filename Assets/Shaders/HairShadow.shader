Shader "Custom/HairShadow"
{
    Properties
    {
        __CameraOpaqueTexture("当前相机渲染结果",2D) = "white"{}
        _Color("阴影颜色",Color) = (1,1,1,1)
        _Offset("阴影偏移距离",Float) = 0.005
        [Header(Stencil)][Space(10)]
        _StencilID ("_StencilRef", Range(0, 255)) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp ("_StencilComp", float) = 0

        [Header(Face Redraw)][Space(10)]
        _MainTex("主纹理贴图",2D) = "white"{}
        _FaceSDF("脸部SDF贴图",2D) = "white"{}
        _SSSLUTTex("皮肤SSS贴图",2D) = "white"{}
        _SkinShadowMap("皮肤阴影贴图",2D) = "white"{}
        _CurveFactor("皮肤曲率因子",Float) = 1
        _FaceSoftShadow("脸部阴影柔和过渡",Range(0,1)) = 0.1
        _SkinSSSDarkBound("皮肤SSS暗部颜色",Range(0.01,0.5)) = 0.01
        _SkinSSSBrightBound("皮肤SSS亮部颜色",Range(0.5,0.99)) = 0.99
        [HDR] _SpecularColor("高光颜色",Color) = (1.0,1.0,1.0,1.0)
        _LobeWeight("双叶高光权重",Float) = 1
        _DirectSpecularIntensity("直接照明高光强度",Float) = 1
        _IndirectSpecularIntensity("间接照明高光强度",Float) =1
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
            "Queue"="Geometry+0"
        }

        HLSLINCLUDE
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariablesFunctions.hlsl"

        // 常量缓冲区的定义，GPU现在里面某一块区域，这一块区域可以非常快速的和GPU传输数据
        // 因为要占GPU显存，所以其容量不是很大。
        // CBUFFER_START = 常量缓冲区的开始，CBUFFER_END = 常量缓冲区的结束。
        // UnityPerMaterial = 每一个材质球都用这一个Cbuffer，凡是在Properties里面定义的数据(Texture除外)，
        // 都需要在常量缓冲区进行声明，并且都用这一个Cbuffer，通过这些操作可以享受到SRP的合批功能
        CBUFFER_START(UnityPerMaterial)
        // 常量缓冲区所填充的内容
        float4 _Color;
        float _Offset;
        float4 _LightDirSS;

        //Pass2
        half4 _MainColor;
        float4 _MainTex_ST;
        float4 _SpecularColor;
        float _DirectSpecularIntensity;
        float _IndirectSpecularIntensity;

        float _CurveFactor;
        float _LobeWeight;
        float _FaceSoftShadow;
        float _SkinSSSDarkBound;
        float _SkinSSSBrightBound;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_FaceSDF);
        SAMPLER(sampler_FaceSDF);
        TEXTURE2D(_SSSLUTTex);
        SAMPLER(sampler_SSSLUTTex);
        TEXTURE2D(_SkinShadowMap);
        SAMPLER(sampler_SkinShadowMap);
        ENDHLSL

        Pass
        {
            Name "HairShadow"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Stencil
            {
                Ref [_StencilID]
                Comp [_StencilComp]
                Pass Zero
            }
            ZTest LEqual
            ZWrite Off
            Colormask 0

            //在OpenGL ES2.0中使用HLSLcc编译器,目前除了OpenGL ES2.0全都默认使用HLSLcc编译器.
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            #pragma multi_compile_instancing


            // 顶点着色器的输入
            struct vertInput
            {
                float3 positionOS : POSITION;
                float2 uv :TEXCOORD0;
            };

            // 顶点着色器的输出
            struct vertOutput
            {
                float4 positionCS : SV_POSITION;
                float2 uv :TEXCOORD0;
            };


            // 顶点着色器
            vertOutput vert(vertInput v)
            {
                vertOutput o = (vertOutput)0;
                o.uv = v.uv;
                o.positionCS = TransformObjectToHClip(v.positionOS);

                float2 lightOffset = normalize(_LightDirSS.xy);
                //乘以_ProjectionParams.x是考虑裁剪空间y轴是否因为DX与OpenGL的差异而被翻转
                //参照https://docs.unity3d.com/Manual/SL-PlatformDifferences.html
                //"Similar to Texture coordinates, the clip space coordinates differ between Direct3D-like and OpenGL-like platforms"
                lightOffset.y *= _ProjectionParams.x;
                o.positionCS.xy += lightOffset * _Offset;

                return o;
            }

            // 片段着色器
            half4 frag(vertOutput i) : SV_TARGET
            {
                half2 ScreenUV = i.positionCS.xy / _ScreenParams.xy;
                // half4 col = SAMPLE_TEXTURE2D(_SSSLUTTex, sampler_SSSLUTTex, float2(0.5,0.99));
                return half4(0, 0, 0, 1);
                return _Color;
                // return col;
            }
            ENDHLSL
        }

        Pass
        {
            Name "HairShadow_Face"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Stencil
            {
                Ref 0
                Comp Equal
                Pass keep
            }
            ZTest LEqual
            ZWrite Off

            //在OpenGL ES2.0中使用HLSLcc编译器,目前除了OpenGL ES2.0全都默认使用HLSLcc编译器.
            HLSLPROGRAM
            #include "ToonPBRCommon.hlsl"

            #pragma vertex vert
            #pragma fragment frag
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            #pragma multi_compile_instancing

            struct vertInput
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1; //lightmap uv（全展UV）
                float4 vertexColor : COLOR;
            };

            struct vertOutput
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 tangentWS : TEXCOORD2;
                float3 bitangentWS : TEXCOORD3;
                float3 positionWS : TEXCOORD4;
                float4 positionNDC : TEXCOORD5;
                float4 vertexColor : COLOR0;
                DECLARE_LIGHTMAP_OR_SH(lightMapUV, vertexSH, 6);
                //声明光照贴图的纹理坐标，球谐光照名称，纹理坐标索引，根据LIGHTMAP_ON开启与否选择LIGHTMAP或者SH
                //静态物体（Contribute GI 为static）的LIGHTMAP_ON为定义的，动态物体为未定义
            };


            // 顶点着色器
            vertOutput vert(vertInput v)
            {
                vertOutput o = (vertOutput)0;
                // o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                VertexPositionInputs vertexPositionInputs = GetVertexPositionInputs(v.positionOS);
                VertexNormalInputs vertexNormalInputs = GetVertexNormalInputs(v.normalOS, v.tangentOS);
                o.uv = v.uv;
                o.vertexColor = v.vertexColor;
                o.positionCS = vertexPositionInputs.positionCS;
                o.positionWS = vertexPositionInputs.positionWS;
                o.positionNDC = vertexPositionInputs.positionNDC;
                o.normalWS = vertexNormalInputs.normalWS;
                o.tangentWS = vertexNormalInputs.tangentWS;
                o.bitangentWS = vertexNormalInputs.bitangentWS;
                //根据LIGHTMAP_ON开启与否选择返回LIGHTMAP还是SH
                OUTPUT_LIGHTMAP_UV(v.uv2, unity_LightmapST, o.lightmapUV);
                OUTPUT_SH(o.normalWS.xyz, o.vertexSH);
                return o;
            }

            // 片段着色器
            half4 frag(vertOutput i) : SV_TARGET
            {
                //初始化必要参数，主光源接受阴影
                float4 shadowCoord = TransformWorldToShadowCoord(i.positionWS);
                Light mainLight = GetMainLight(shadowCoord);
                float3 lightDir = normalize(mainLight.direction);
                float3 viewDirWS = normalize(_WorldSpaceCameraPos - i.positionWS);
                //问题：这里如果光线与视线反向会出现问题
                float3 halfDir = SafeNormalize(lightDir + viewDirWS);
                float3x3 tangentToWorld = float3x3(i.tangentWS, i.bitangentWS, i.normalWS);

                //采样基本贴图
                float4 baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, TRANSFORM_TEX(i.uv,_MainTex));
                float3 normalWS = i.normalWS;

                //计算各向量点乘结果
                float NdotH = max(0.001, saturate(dot(normalWS, halfDir)));
                float NdotV = max(0.001, saturate(dot(normalWS, viewDirWS)));
                float NdotL = max(0.001, saturate(dot(normalWS, lightDir)));
                float VdotH = max(0.001, saturate(dot(viewDirWS, halfDir)));
                float3 tangentTS = TransformWorldToTangent(i.tangentWS, tangentToWorld);
                float3 bitangentTS = TransformWorldToTangent(i.bitangentWS, tangentToWorld);

                float roughness = 1;
                float metallic = 0;
                float occlusion = 1;

                //初始化基础反射率F0。
                float3 F0 = lerp(float3(0.04, 0.04, 0.04), baseColor.rgb, metallic);

                //--------------------------------------------------PBR光照计算---------------------------------------------------------
                //计算PBR直接光照结果
                float dTerm = NormalDistributionFunc_GGX(NdotH, roughness);
                float3 fTerm = Fresnel_Schlick(VdotH, F0);
                float gTerm = GeometryFunc_SchlickGGX(NdotV, NdotL, roughness);
                // float3 directBRDFSpecFactor = dTerm * fTerm * gTerm / (4.0 * NdotV * NdotL);
                half3 directDualLobeSpecColor = DirectBDRF_DualLobeSpecular(roughness, F0, normalWS, lightDir, viewDirWS, 1, _LobeWeight);
                //漫反射部分由能量守恒得到
                float3 Ks = fTerm;
                //金属是没有漫反射的,所以Kd需要乘上1-metallic (折射光中属于金属的部分不会形成漫反射)
                float3 Kd = (1 - Ks) * (1 - metallic);
                float3 diffuseColor = Kd * baseColor.xyz * occlusion;
                float3 directLighting = diffuseColor + directDualLobeSpecColor * _SpecularColor.xyz * _DirectSpecularIntensity;

                //计算PBR间接光照结果
                //Diffuse部分
                float3 SHcolor = SH_IndirectionDiff(normalWS) * occlusion;
                float3 IndirKS = Indir_Fresnel_Schlick(NdotV, F0, roughness);
                float3 IndirKD = (1 - IndirKS) * (1 - metallic);
                float3 IndirDiffuseColor = SHcolor * IndirKD * baseColor.xyz;
                //间接光specular
                float3 IndirSpeCubeColor = IndirSpeCube(normalWS, viewDirWS, roughness, occlusion);
                float3 BRDFSpeSection = CalcBRDFSpeSection(VdotH, NdotV, NdotL, NdotH, F0, roughness);
                float3 IndirSpeCubeFactor = IndirSpeFactor(roughness, BRDFSpeSection, F0, NdotV);
                float3 IndirSpeColor = IndirSpeCubeColor * IndirSpeCubeFactor;
                float3 indirectLighting = IndirDiffuseColor + IndirSpeColor * _IndirectSpecularIntensity;

                float3 finalColor = float3(0, 0, 0); //初始化最终颜色
                //--------------------------------------------------------------------------------------------------------------------

                //皮肤SSS(2DRamp)(脸部SDF计算值替换NoL)
                //以下为脸部SDF计算
                half4 SDF_L = SAMPLE_TEXTURE2D(_FaceSDF, sampler_FaceSDF,i.uv);
                half4 SDF_R = SAMPLE_TEXTURE2D(_FaceSDF, sampler_FaceSDF,float2(1-i.uv.x,i.uv.y));
                //物体空间的Forward向量和Right向量变换到世界空间中计算
                float3 forwardDirWS = normalize(TransformObjectToWorldDir(float3(0.0,0.0,1.0)));
                float3 rightDirWS = normalize(TransformObjectToWorldDir(float3(1.0,0.0,0.0)));
                float3 lightDirWS = normalize(float3(mainLight.direction.x,0.0,mainLight.direction.z));    //不需要关注光线y方向，相当于把光线向量投影到xOz平面上
                //判断光源在左还是在右（SDF贴图为光源在左侧，如光源在右侧需要调换采样坐标U）
                float RdotL = dot(rightDirWS,lightDirWS);
                //计算光源和正脸夹角，以SDF作为明暗分界，柔和过渡
                float FdotL = dot(forwardDirWS,lightDirWS) * -0.5 + 0.5;
                half4 appliedSDF = RdotL<0?SDF_L:SDF_R;
                float bias = smoothstep(0-_FaceSoftShadow, 0+_FaceSoftShadow, appliedSDF.r-FdotL);
                float3 skinShadowMap = SAMPLE_TEXTURE2D(_SkinShadowMap,sampler_SkinShadowMap,i.uv).rgb;    //采样皮肤阴影贴图（R通道表示AO，用于过度脖子和脸部，B通道可能是高光）
                bias *= skinShadowMap.r;

                //以下为皮肤SSS，同_SHADERTYPE_SKIN，但bias替换NoL
                float cuv = saturate(_CurveFactor * (length(fwidth(normalWS)) / length(fwidth(i.positionWS))));
                bias = clamp(bias,_SkinSSSDarkBound,_SkinSSSBrightBound);       //钳制UV，防止采样到边缘，同时限制一下bias的最大值，防止过亮，与皮肤亮部保持一致（这里把bias从[0, 1]映射到[0.5, 1]了）
                cuv = clamp(cuv,0.01,0.99);
                float3 sssColor = SAMPLE_TEXTURE2D(_SSSLUTTex, sampler_SSSLUTTex, float2(_SkinSSSDarkBound, cuv)).rgb * mainLight.color;
                finalColor = directLighting * sssColor + indirectLighting;
                // return half4(1,1,1, 1);
                return half4(finalColor, 1);
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/Shader Graph/FallbackError"
}