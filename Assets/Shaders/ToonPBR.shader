Shader "Custom/ToonPBR"
{
    Properties
    {
        [Main(ShaderSettings, _, on, off)] _shaderSettingsGroup ("着色器设置", Float) = 0
        [SubEnum(ShaderSettings, UnityEngine.Rendering.CullMode)]_CullMode("剔除模式",Int) = 0
        [SubEnum(ShaderSettings, UnityEngine.Rendering.CompareFunction)]_StencilComp("模板比较模式",Int) = 8
        [Sub(ShaderSettings)] _StencilID("模板ID",int) = 0
        [SubEnum(ShaderSettings, UnityEngine.Rendering.StencilOp)]_StencilOp("模板测试通过操作",Int) = 0
        [SubKeywordEnum(ShaderSettings, Base,Skin,Face,Hair,Eyes)]_ShaderType("渲染类型",Int) = 0

        [Main(GeneralSettings, _, on, off)] _generalSettingsGroup ("基础设置", Float) = 0
        [Sub(GeneralSettings)] [HDR] _MainColor("主纹理颜色",Color) = (1,1,1,1)
        [Sub(GeneralSettings)] _MainTex("主纹理贴图",2D) = "white"{}
        [SubToggle(GeneralSettings, _NORMALMAP)] _EnableBumpMap("启用法线贴图", Int) = 0
        [SubKeywordEnum(GeneralSettings, 3Channel, 2Channel)] _NormalType ("法线贴图类型", float) = 0
        //        [KeywordEnum(3Channel,2Channel)]_NormalType("法线贴图类型",Int) = 0
        [Sub(GeneralSettings)] _NormalScale("法线强度",Range(0,1)) = 1.0
        [Sub(GeneralSettings)] [Normal] _NormalMap("法线贴图",2D) = "bump"{}
        [Sub(GeneralSettings)] _LightMap("光照贴图（R：粗糙度，G：金属度，B：环境光遮蔽）",2D) = "white"{}
        [Sub(GeneralSettings)] _RoughnessScale("粗糙度强度",Range(0,1)) = 1.0
        [Sub(GeneralSettings)] _MetallicScale("金属度强度",Range(0,1)) = 1.0
        [Sub(GeneralSettings)] _OcclusionScale("环境光遮蔽强度",Range(0,1)) = 1.0

        [Main(SpecularSettings, _, on, off)] _specularSettingsGroup("高光设置", Float) = 0
        [SubToggle(SpecularSettings, _ANISOTROPIC_SPEC)] _EnableAnisotropicSpec("启用各向异性高光", Int) = 0
        [Sub(SpecularSettings)] _AnisotropicIntensity("各向异性强度",Float) = 1
        [Sub(SpecularSettings)] [HDR] _SpecularColor("高光颜色",Color) = (1.0,1.0,1.0,1.0)
        [Sub(SpecularSettings)] _DirectSpecularIntensity("直接照明高光强度",Float) = 1
        [Sub(SpecularSettings)] _IndirectSpecularIntensity("间接照明高光强度",Float) =1

//        [Main(ClearCoatSettings, _CLEARCOAT, off)] _clearCoatSettingsGroup("清漆设置（弃用）",Float) = 0
//        [Sub(ClearCoatSettings)] _ClearCoatRoughness("清漆粗糙度",Range(0.0,1.0)) = 0
//        [Sub(ClearCoatSettings)] _ClearCoatIOR("IOR折射率",Float) = 1.45

        [Main(SphereSettings, _SPHEREMAP, on)] _sphereSettingsGroup ("球面贴图设置", Float) = 1
        [SubKeywordEnum(SphereSettings, Add,Mul)]_SphereCubeType("球面贴图类型",Int) = 0
        [Sub(SphereSettings)] _SphereCube("球面贴图",Cube) = "white"{}

//        [Main(DiscardedSettings, _, off, off)] _discardedSettingsGroup("丢弃的设置", Float) = 0
//        [MinMaxSlider(DiscardedSettings, _DarkLB, _DarkUB)] _minMaxSlider("NPR暗部柔和过渡", Range(0.0, 1.0)) = 1.0
//        [Sub(DiscardedSettings)] _DarkLB("NPR暗部柔和过渡下界",Range(0,1)) = 0.3
//        [Sub(DiscardedSettings)] _DarkUB("NPR暗部柔和过渡上界",Range(0,1)) = 0.7

        [Main(SkinSettings, _, off, off)] _skinSettingsGroup("皮肤设置", Float) = 0
        [Sub(SkinSettings)] _SSSLUTTex("皮肤SSS贴图",2D) = "white"{}
        [Sub(SkinSettings)] _CurveFactor("皮肤曲率因子",Float) = 1
        [Sub(SkinSettings)] _SkinShadowMap("皮肤阴影贴图",2D) = "white"{}
        [MinMaxSlider(SkinSettings, _SkinSSSDarkBound, _SkinSSSBrightBound)] _minMaxSlider1("皮肤SSS阈值", Range(0.0, 1.0)) = 1.0
        [Sub(SkinSettings)] _SkinSSSDarkBound("皮肤SSS暗部颜色",Range(0.01,0.5)) = 0.01
        [Sub(SkinSettings)] _SkinSSSBrightBound("皮肤SSS亮部颜色",Range(0.5,0.99)) = 0.99
        [Sub(SkinSettings)] _LobeWeight("双叶高光权重",Float) = 1

        [Main(FaceSettings, _, off, off)] _faceSettingsGroup("脸部设置", Float) = 0
        [Sub(FaceSettings)] _FaceSDF("脸部SDF贴图",2D) = "white"{}
        [Sub(FaceSettings)] _FaceSoftShadow("脸部阴影柔和过渡",Range(0,1)) = 0.1
        //        [Sub(FaceSettings)] _FaceBrightness("脸部亮度",Range(0,0.99)) = 0.85

        [Main(EyesSettings, _, off, off)] _eyesSettingsGroup("眼睛设置", Float) = 0
        [SubToggle(EyesSettings, _PARALLAX)] _EnableEyeRefraction("启用瞳孔折射", Int) = 0
        [Sub(EyesSettings)] _ParallaxHeight("折射视差高度",Float) = 0.2
        [Sub(EyesSettings)] _EyeMatCap("MatCap贴图",2D) = "black"{}
        [Sub(EyesSettings)] _EyeShadowAttenuationFactor("眼睛暗处亮度衰减",Range(0.0,1.0)) = 0.5

        [Main(HairSettings, _, off, off)] _hairSettingsGroup("头发设置", Float) = 0
        [SubToggle(HairSettings, _ANISOTROPIC_HAIR)] _EnableAnisotropicHair("启用发丝各向异性高光", Int) = 1
        [Sub(HairSettings)] _HairUVRotateMask("头发UV旋转遮罩",2D) = "white"{}
        [Sub(HairSettings)] _TangentMap("修正切线贴图",2D) = "white"{}
        [Sub(HairSettings)] _AnisotropicDirection("发丝各向异性高光方向",float) = 90
        [Sub(HairSettings)] _AnisotropicExponent("发丝各向异性高光指数",float) = 200
        [Sub(HairSettings)] _AnisotropicSpecIntensity("发丝各向异性高光强度",Range(0,1)) = 0.5
        [Sub(HairSettings)] _JitterMap("扰动贴图",2D) = "black"{}
        [Sub(HairSettings)] _DirAttenLB("各向异性高光衰减系数下界",Range(-1,1)) = -0.3
        [Sub(HairSettings)] _DirAttenUB("各向异性高光衰减系数上界",Range(-1,1)) = 0.2

        [Main(OutlineSettings, _, off, off)] _outlineSettingsGroup("描边设置", Float) = 0
        [SubToggle(OutlineSettings)]_EnableOutline("Enable Outline",int) = 1
        [Sub(OutlineSettings)] _OutlineColor("Outline Color",Color) = (1.0,1.0,1.0,1.0)
        [Sub(OutlineSettings)] _OutlineWidth("Outline Width",Range(0,4)) = 1
        [Sub(OutlineSettings)] _OutlineFlag("Outline Flag",int) = 128

        [Main(RimSettings, _RIM, off, on)] _rimSettingsGroup("边缘光设置", Float) = 1
        [Sub(RimSettings)] _RimIntensity("边缘光强度",Range(0.0,1.0)) = 1.0
        [Sub(RimSettings)] _RimColor("边缘光颜色",Color) = (1.0,1.0,1.0,1.0)
        [Sub(RimSettings)] _RimOffset("边缘光偏移",float) = 0.2
        [Sub(RimSettings)] _RimThreshold("边缘光阈值",float) = 1

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
        #include "ToonPBRCommon.hlsl"

        // #pragma multi_compile _NORMALMAP
        #pragma shader_feature _NORMALMAP
        #pragma shader_feature _NORMALTYPE_3CHANNEL _NORMALTYPE_2CHANNEL
        #pragma shader_feature _CLEARCOAT
        #pragma shader_feature _SPHEREMAP
        #pragma shader_feature _RIM
        #pragma shader_feature _SPHERECUBETYPE_ADD _SPHERECUBETYPE_MUL
        #pragma shader_feature _PARALLAX
        #pragma shader_feature_local _SHADERTYPE_BASE _SHADERTYPE_SKIN _SHADERTYPE_HAIR _SHADERTYPE_FACE _SHADERTYPE_EYES
        #pragma shader_feature _ANISOTROPIC_SPEC
        #pragma shader_feature _ANISOTROPIC_HAIR
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _SHADOWS_SOFT  //软阴影

        CBUFFER_START(UnityPerMaterial)
        half4 _MainColor;
        float4 _MainTex_ST;
        float _NormalScale;
        float4 _NormalMap_ST;
        float4 _LightMap_ST;
        float4 _SSSLUTTex_ST;
        float4 _JitterMap_ST;

        float _RoughnessScale;
        float _MetallicScale;
        float _OcclusionScale;

        float _AnisotropicIntensity;
        float4 _SpecularColor;
        float _DirectSpecularIntensity;
        float _IndirectSpecularIntensity;

        float _ClearCoatRoughness;
        float _ClearCoatIOR;

        float _DarkLB;
        float _DarkUB;

        float _CurveFactor;
        float _LobeWeight;
        float _SkinSSSDarkBound;
        float _SkinSSSBrightBound;

        float _FaceSoftShadow;
        // float _FaceBrightness;

        float _ParallaxHeight;
        float _EyeShadowAttenuationFactor;

        float _AnisotropicDirection;
        float _AnisotropicExponent;
        float _AnisotropicSpecIntensity;
        float _DirAttenLB;
        float _DirAttenUB;

        int _EnableOutline;
        float4 _OutlineColor;
        float _OutlineWidth;

        float _RimIntensity;
        float4 _RimColor;
        float _RimOffset;
        float _RimThreshold;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_NormalMap);
        SAMPLER(sampler_NormalMap);
        TEXTURE2D(_LightMap);
        SAMPLER(sampler_LightMap);
        TEXTURECUBE(_SphereCube);
        SAMPLER(sampler_SphereCube);
        TEXTURE2D(_SSSLUTTex);
        SAMPLER(sampler_SSSLUTTex);
        TEXTURE2D(_FaceSDF);
        SAMPLER(sampler_FaceSDF);
        TEXTURE2D(_SkinShadowMap);
        SAMPLER(sampler_SkinShadowMap);
        TEXTURE2D(_HairUVRotateMask);
        SAMPLER(sampler_HairUVRotateMask);
        TEXTURE2D(_TangentMap);
        SAMPLER(sampler_TangentMap);
        TEXTURE2D(_JitterMap);
        SAMPLER(sampler_JitterMap);
        TEXTURE2D(_EyeMatCap);
        SAMPLER(sampler_EyeMatCap);
        TEXTURE2D(_CameraDepthTexture);
        SAMPLER(sampler_CameraDepthTexture);

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

        float3 UnpackNormalRG(float2 packedNormal, float scale = 1.0)
        {
            float3 normal = float3(0.0, 0.0, 0.0);
            normal.xy = packedNormal * 2.0 - 1.0;
            normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
            normal.xy *= scale;
            return normal;
        }
        ENDHLSL

        Pass
        {
            Name "ToonPBRPass"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            // Render State
            Cull [_CullMode]
            Stencil
            {
                Ref [_StencilID]
                Comp [_StencilComp]
                Pass [_StencilOp]
            }

            //在OpenGL ES2.0中使用HLSLcc编译器,目前除了OpenGL ES2.0全都默认使用HLSLcc编译器.
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            #pragma multi_compile_instancing
            // #pragma shader_feature _NORMALMAP
            // #pragma shader_feature _NORMALTYPE_3CHANNEL _NORMALTYPE_2CHANNEL
            // #pragma shader_feature _SPHEREMAP
            // #pragma shader_feature _SPHERECUBETYPE_ADD _SPHERECUBETYPE_MUL
            // #pragma shader_feature _PARALLAX
            // #pragma shader_feature_local _SHADERTYPE_BASE _SHADERTYPE_SKIN _SHADERTYPE_HAIR _SHADERTYPE_FACE _SHADERTYPE_EYES
            // #pragma shader_feature _ANISOTROPIC_SPEC
            // #pragma multi_compile _ LIGHTMAP_ON
            // #pragma multi_compile _MAIN_LIGHT_SHADOWS
            // #pragma multi_compile _MAIN_LIGHT_SHADOWS_CASCADE
            // #pragma multi_compile _SHADOWS_SOFT  //软阴影

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
                float4 lightMap = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, TRANSFORM_TEX(i.uv,_LightMap));
                #ifdef _NORMALMAP
                float4 normalMap = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, TRANSFORM_TEX(i.uv,_NormalMap));
                #if _NORMALTYPE_3CHANNEL
                float3 normalTS = UnpackNormalScale(normalMap, _NormalScale);
                float3 normalWS = TransformTangentToWorld(normalTS, tangentToWorld, true);
                #elif _NORMALTYPE_2CHANNEL
                float3 normalTS = UnpackNormalRG(normalMap, _NormalScale);
                float3 normalWS = TransformTangentToWorld(normalTS, tangentToWorld, true);
                #endif
                #else
                float3 normalWS = i.normalWS;
                #endif


                //-----------------------------------------------------眼睛折射（重新采样baseColor）---------------------------------------------------------
                //眼睛折射，通过视差实现，重新采样眼睛纹理
                #if defined(_SHADERTYPE_EYES)
                #if defined(_PARALLAX)
                float3 viewDirOS = normalize(TransformWorldToObjectDir(viewDirWS));
                float2 offset = _ParallaxHeight * viewDirOS.xy;
                offset.y = -offset.y;
                baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, TRANSFORM_TEX(i.uv+offset,_MainTex));
                #endif
                #endif
                //--------------------------------------------------------------------------------------------------------------------------------------

                // float3 positionVS = normalize(TransformWorldToView(i.positionWS));
                // float3 normalVS_matcap = TransformWorldToViewNormal(normalWS, true);
                // float3 var = cross(positionVS,normalVS_matcap);


                //-----------------------------------------------------眼睛MatCap---------------------------------------------------------
                //眼睛折射，通过视差实现，重新采样眼睛纹理
                #if defined(_SHADERTYPE_EYES)
                float3 normalVS_MatCap = TransformWorldToViewNormal(normalWS, true);
                float3 viewDirVS_MatCap = normalize(TransformWorldToView(i.positionWS)); //视线向量，由于是在相机空间，所以不用做向量减法，直接将片元坐标变换到相机空间即可
                float3 VcrossN = cross(viewDirVS_MatCap, normalVS_MatCap);
                float2 matCapUV = float2(-VcrossN.y,VcrossN.x)*0.5+0.5;
                float4 matCapColor = SAMPLE_TEXTURE2D(_EyeMatCap, sampler_EyeMatCap, matCapUV);
                baseColor += matCapColor;
                #endif
                //-----------------------------------------------------------------------------------------------------------------------

                //计算各向量点乘结果
                float NdotH = max(0.001, saturate(dot(normalWS, halfDir)));
                float NdotV = max(0.001, saturate(dot(normalWS, viewDirWS)));
                float NdotL = max(0.001, saturate(dot(normalWS, lightDir)));
                float VdotH = max(0.001, saturate(dot(viewDirWS, halfDir)));
                float3 tangentTS = TransformWorldToTangent(i.tangentWS, tangentToWorld);
                float3 bitangentTS = TransformWorldToTangent(i.bitangentWS, tangentToWorld);

                //此处可以考虑NPR效果
                float NPRShadow = smoothstep(_DarkLB, _DarkUB, NdotL);
                // float3 radiance = mainLight.color * mainLight.shadowAttenuation * NPRShadow;
                float3 radiance = mainLight.color * mainLight.shadowAttenuation * NdotL;

                //初始化粗糙度，金属度，环境光遮蔽
                float roughness = lightMap.r * _RoughnessScale;
                float metallic = lightMap.g * _MetallicScale;
                float occlusion = lightMap.b * _OcclusionScale;

                //初始化基础反射率F0。
                float3 F0 = lerp(float3(0.04, 0.04, 0.04), baseColor.rgb, metallic);

                //-----------------------------------------------------计算TangentMap，解码切线---------------------------------------------------------
                // #if defined(_SHADERTYPE_BASE)
                float3 bakedTangent = SAMPLE_TEXTURE2D(_TangentMap, sampler_TangentMap, i.uv).rgb * 2 - 1;
                bakedTangent = normalize(mul(bakedTangent, tangentToWorld));
                float3 bakedBitangent = normalize(cross(normalWS, bakedTangent));
                // #endif
                //------------------------------------------------------------------------------------------------------------------------------------


                //--------------------------------------------------PBR光照计算---------------------------------------------------------
                //计算PBR直接光照结果
                //高光部分
                #if _ANISOTROPIC_SPEC
                // float HdotX = max(0.001, saturate(dot(bakedTangent, halfDir)));
                // float HdotY = max(0.001, saturate(dot(bakedbitangent, halfDir)));
                float HdotX = max(0.001, saturate(dot(i.tangentWS, halfDir)));
                float HdotY = max(0.001, saturate(dot(i.bitangentWS, halfDir)));
                float dTerm = AnisotropicNormalDistribution_GGX(NdotH, HdotX, HdotY, _AnisotropicIntensity, roughness);
                #else
                float dTerm = NormalDistributionFunc_GGX(NdotH, roughness);
                #endif
                float3 fTerm = Fresnel_Schlick(VdotH, F0);
                float gTerm = GeometryFunc_SchlickGGX(NdotV, NdotL, roughness);
                float3 directBRDFSpecFactor = dTerm * fTerm * gTerm / (4.0 * NdotV * NdotL);
                half3 directDualLobeSpecColor = DirectBDRF_DualLobeSpecular(roughness, F0, normalWS, lightDir, viewDirWS, 1, _LobeWeight);
                //漫反射部分由能量守恒得到
                float3 Ks = fTerm;
                //金属是没有漫反射的,所以Kd需要乘上1-metallic (折射光中属于金属的部分不会形成漫反射)
                float3 Kd = (1 - Ks) * (1 - metallic);
                float3 diffuseColor = Kd * baseColor.xyz * occlusion;
                #if defined(_SHADERTYPE_SKIN)||defined(_SHADERTYPE_FACE)
                float3 directLighting = diffuseColor + directDualLobeSpecColor * _SpecularColor.xyz * _DirectSpecularIntensity;
                // directLighting = directDualLobeSpecColor * _SpecularColor.xyz;
                // directLighting = directBRDFSpecFactor * _SpecularColor.xyz;
                #else
                float3 directLighting = diffuseColor + directBRDFSpecFactor * _SpecularColor.xyz * _DirectSpecularIntensity;
                #endif
                #if defined(_CLEARCOAT)
                //清漆直接光照
                float coatRoughness = _ClearCoatRoughness * _ClearCoatRoughness;
                float fresnelTerm = pow(1 - NdotV,4.0);
                float coatFresnel = 0.04 + fresnelTerm;
                float coatdTerm = NormalDistributionFunc_GGX(NdotH, _ClearCoatRoughness);
                float3 coatfTerm = Fresnel_Schlick(VdotH, F0);
                float coatgTerm = GeometryFunc_SchlickGGX(NdotV, NdotL, _ClearCoatRoughness);
                float3 coatDirectBRDFSpecFactor = coatdTerm * coatfTerm * coatgTerm / (4.0 * NdotV * NdotL);
                float coatDirectSpecular = coatDirectBRDFSpecFactor * _SpecularColor.xyz * _DirectSpecularIntensity;
                directLighting = directLighting * (1.0 - coatFresnel) + coatDirectSpecular;
                #endif
                // directLighting *= radiance;

                //计算PBR间接光照结果
                //Diffuse部分
                float3 SHcolor = SH_IndirectionDiff(normalWS) * occlusion;
                float3 IndirKS = Indir_Fresnel_Schlick(VdotH, F0, roughness);
                float3 IndirKD = (1 - IndirKS) * (1 - metallic);
                float3 IndirDiffuseColor = SHcolor * IndirKD * baseColor.xyz;
                //间接光specular
                float3 IndirSpeCubeColor = IndirSpeCube(normalWS, viewDirWS, roughness, occlusion);
                float3 BRDFSpeSection = CalcBRDFSpeSection(VdotH, NdotV, NdotL, NdotH, F0, roughness);
                float3 IndirSpeCubeFactor = IndirSpeFactor(roughness, BRDFSpeSection, F0, NdotV);
                float3 IndirSpeColor = IndirSpeCubeColor * IndirSpeCubeFactor;
                float3 indirectLighting = IndirDiffuseColor + IndirSpeColor * _IndirectSpecularIntensity;
                #if defined(_CLEARCOAT)
                //清漆间接光照
                float3 CoatIndirSpeCubeColor = IndirSpeCube(normalWS, viewDirWS, coatRoughness, occlusion);
                float3 CoatBRDFSpeSection = CalcBRDFSpeSection(VdotH, NdotV, NdotL, NdotH, F0, coatRoughness);
                float3 CoatIndirSpeCubeFactor = IndirSpeFactor(coatRoughness, CoatBRDFSpeSection, F0, NdotV);
                float3 CoatIndirSpeColor = IndirSpeCubeColor * IndirSpeCubeFactor;
                indirectLighting = indirectLighting * (1.0 - coatFresnel) + CoatIndirSpeColor;
                #endif

                float3 finalColor = float3(0, 0, 0); //初始化最终颜色
                //--------------------------------------------------------------------------------------------------------------------


                //--------------------------------------------------SSS计算（皮肤&脸部）---------------------------------------------------------
                //皮肤SSS(2DRamp)
                #if _SHADERTYPE_SKIN
                float cuv = saturate(_CurveFactor * (length(fwidth(normalWS)) / length(fwidth(i.positionWS))));
                // float NoL = dot(normalWS, lightDir);
                float NoL = dot(normalWS, lightDir) * 0.5 + 0.5;       //[-1, 1] -> [0, 1]
                NoL = clamp(NoL,_SkinSSSDarkBound,_SkinSSSBrightBound);       //钳制UV，防止采样到边缘
                cuv = clamp(cuv,0.01,0.99);
                // float3 skinShadowMap = SAMPLE_TEXTURE2D(_SkinShadowMap,sampler_SkinShadowMap,i.uv).rgb;    //采样皮肤阴影贴图（R通道表示AO，用于过度脖子和脸部，B通道可能是高光）
                // NoL *= skinShadowMap.r;
                // float3 sssColor = SAMPLE_TEXTURE2D(_SSSLUTTex, sampler_SSSLUTTex, TRANSFORM_TEX(float2(NoL * 0.5 + 0.5, cuv),_SSSLUTTex)).rgb * mainLight.color;
                float3 sssColor = SAMPLE_TEXTURE2D(_SSSLUTTex, sampler_SSSLUTTex, TRANSFORM_TEX(float2(NoL, cuv),_SSSLUTTex)).rgb * mainLight.color;
                // finalColor = sssColor+indirectLighting;
                // directLighting = directLighting/NdotL*sssColor;      //皮肤SSS包含了NdotL，最后整合直接间接光照时也会乘上NdotL，所以这里提前除一个（会影响到加算的球面贴图）
                #endif

                //皮肤SSS(2DRamp)(脸部SDF计算值替换NoL)
                #if _SHADERTYPE_FACE
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
                float3 sssColor = SAMPLE_TEXTURE2D(_SSSLUTTex, sampler_SSSLUTTex, TRANSFORM_TEX(float2(bias, cuv),_SSSLUTTex)).rgb * mainLight.color;
                #endif
                //--------------------------------------------------------------------------------------------------------------------------

                //根据不同部位，整合最终光照
                #if defined(_SHADERTYPE_BASE)
                finalColor = directLighting * radiance + indirectLighting;
                // finalColor = directLighting;
                #elif defined(_SHADERTYPE_SKIN)
                //皮肤SSS包含了NdotL和mainLight.color，可替代radiance，shadowAttenuation不知道需不需要乘上
                finalColor = directLighting * sssColor + indirectLighting;
                // finalColor = directLighting;
                // finalColor = sssColor;
                // finalColor = directLighting;
                // finalColor = directBRDFSpecFactor * _SpecularColor.xyz * _DirectSpecularIntensity;
                // finalColor = directDualLobeSpecColor * _SpecularColor.xyz * _DirectSpecularIntensity;
                // finalColor = half3(skinShadowMap.r,skinShadowMap.r,skinShadowMap.r);
                #elif defined(_SHADERTYPE_FACE)
                finalColor = directLighting * sssColor + indirectLighting;
                // finalColor = directLighting;
                // finalColor = directBRDFSpecFactor * _SpecularColor.xyz * _DirectSpecularIntensity;
                // finalColor = directDualLobeSpecColor * _SpecularColor.xyz * _DirectSpecularIntensity;
                // finalColor = half3(FdotL,FdotL,FdotL);
                // finalColor = half3(appliedSDF.r-FdotL,appliedSDF.r-FdotL,appliedSDF.r-FdotL);
                // finalColor = half3(bias,bias,bias);
                // finalColor = half3(skinShadowMap.r,skinShadowMap.r,skinShadowMap.r);
                #elif defined(_SHADERTYPE_EYES)
                float3 forwardDirWS = normalize(TransformObjectToWorldDir(float3(0.0,0.0,1.0)));
                float3 lightDirWS = normalize(float3(mainLight.direction.x,0.0,mainLight.direction.z));
                float FdotL = dot(forwardDirWS,lightDirWS)*0.5+0.5;
                float3 finalColor_bright = directLighting;
                float3 finalColor_dark = directLighting * _EyeShadowAttenuationFactor;
                finalColor = lerp(finalColor_dark,finalColor_bright,FdotL);
                #else   //_SHADERTYPE_HAIR
                finalColor = directLighting * radiance + indirectLighting;
                #if defined(_ANISOTROPIC_HAIR)
                float hairUVRotate = SAMPLE_TEXTURE2D(_HairUVRotateMask, sampler_HairUVRotateMask, i.uv);
                float hairUVRotateMask = step(0.8, hairUVRotate);
                float a = _AnisotropicDirection / 180 * 3.1415926;
                float2x2 rotateMat = float2x2(cos(a), sin(a), -sin(a), cos(a));
                float2 rotatedUV = mul(rotateMat, i.uv);
                float2 uv = hairUVRotateMask > 0 ? rotatedUV : i.uv;
                float shift = SAMPLE_TEXTURE2D(_JitterMap, sampler_JitterMap, TRANSFORM_TEX(uv,_JitterMap));
                bakedTangent = bakedTangent + shift * normalWS;
                bakedTangent = normalize(bakedTangent);
                half TdotH = dot(bakedTangent, halfDir);
                half sinTH = sqrt(1 - TdotH * TdotH);
                // float dirAtten = smoothstep(-1.0, 0.0, TdotH);
                float dirAtten = smoothstep(_DirAttenLB, _DirAttenUB, TdotH);
                half3 specCol = dirAtten * pow(sinTH, _AnisotropicExponent) * _AnisotropicSpecIntensity;
                finalColor = finalColor + specCol;
                // finalColor = float3(bakedTangent);
                #endif
                #endif

                //--------------------------------------------------球面贴图计算------------------------------------------------------------
                //球面贴图
                #if defined(_SPHEREMAP)
                float3 normalVS = TransformWorldToViewNormal(normalWS, true);
                float3 viewDirVS = normalize(TransformWorldToView(i.positionWS)); //视线向量，由于是在相机空间，所以不用做向量减法，直接将片元坐标变换到相机空间即可
                float3 uvwSphere = reflect(viewDirVS, normalVS);
                half3 sph = SAMPLE_TEXTURECUBE(_SphereCube, sampler_SphereCube, uvwSphere).rgb;
                #if defined(_SPHERECUBETYPE_ADD)
                finalColor += sph;
                #else
                finalColor *= sph;
                #endif
                #endif
                //--------------------------------------------------------------------------------------------------------------------------

                //--------------------------------------------------屏幕空间深度等宽边缘光计算------------------------------------------------------------
                //屏幕空间深度等宽边缘光
                #if defined(_RIM)
                float2 ScreenUV = float2(i.positionCS.x / _ScreenParams.x, i.positionCS.y / _ScreenParams.y);
                float3 bakedNormal = normalize(UnpackNormalRG(i.vertexColor.rg));
                float3 bakedNormalWS = normalize(mul(bakedNormal, tangentToWorld));
                float3 bakedNormalVS = TransformWorldToViewNormal(bakedNormalWS, true);
                float3 positionVS = TransformWorldToView(i.positionWS);
                float3 samplePositionVS = float3(positionVS.xy + bakedNormalVS.xy * _RimOffset * 0.001, positionVS.z); //保持z不变（CS.w = -VS.z）
                float4 samplePositionCS = TransformWViewToHClip(samplePositionVS);
                float4 positionSS = ComputeScreenPos(samplePositionCS, _ProjectionParams.x);
                float2 sampleUV = positionSS.xy / positionSS.w; //屏幕空间坐标做齐次除法得到视口空间坐标，此坐标作为UV采样深度图
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, ScreenUV);
                float linearEyeDepth = LinearEyeDepth(depth, _ZBufferParams);
                float offsetDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, sampleUV); //Unity深度图同样使用的是z/w非线性深度
                float linearEyeOffsetDepth = LinearEyeDepth(offsetDepth, _ZBufferParams);
                float depthDiff = linearEyeOffsetDepth - linearEyeDepth;
                float rimMask = step(_RimThreshold * 0.01, depthDiff);
                half3 rimColor = float3(rimMask * _RimColor.rgb);
                finalColor = lerp(finalColor, finalColor + rimColor, _RimIntensity);
                #endif
                //----------------------------------------------------------------------------------------------------------------------------------
                

                // return half4(sampleUV,0, 1);
                // return half4(depthDiff,depthDiff,depthDiff, 1);
                // return half4(samplePositionVS, 1);
                // return half4(normalWS, 1);
                // return half4(IndirDiffuseColor, 1);
                // return rimColor;
                return half4(finalColor, 1);
            }
            ENDHLSL
        }

        Pass
        {
            Name "OutlinePass"
            Tags {}
            Cull Front
            //            Stencil
            //            {
            //                Ref [_OutlineFlag]
            //                Comp Always
            //                Pass Replace
            //            }

            HLSLPROGRAM
            #pragma vertex OutlineVertex
            #pragma fragment OutlineFrag

            vertOutput OutlineVertex(vertInput v)
            {
                vertOutput o = (vertOutput)0;
                o.vertexColor = v.vertexColor;
                o.uv = v.uv;
                VertexPositionInputs vertexPositionInputs = GetVertexPositionInputs(v.positionOS);
                VertexNormalInputs vertexNormalInputs = GetVertexNormalInputs(v.normalOS, v.tangentOS);
                o.positionCS = vertexPositionInputs.positionCS;
                o.positionWS = vertexPositionInputs.positionWS;
                o.normalWS = vertexNormalInputs.normalWS;
                o.tangentWS = vertexNormalInputs.tangentWS;
                float3 bitangentWS = vertexNormalInputs.bitangentWS;
                float3x3 tangentToWorld = float3x3(o.tangentWS.xyz, bitangentWS, o.normalWS);

                float3 bakedNormal = normalize(UnpackNormalRG(v.vertexColor.rg));
                float3 OutlineNormalWS = normalize(mul(bakedNormal, tangentToWorld));
                float3 OutlinePositionWS = o.positionWS.xyz + 0.001 * OutlineNormalWS.xyz * _OutlineWidth * _EnableOutline;
                o.positionCS = TransformWorldToHClip(OutlinePositionWS);
                return o;
            }

            half4 OutlineFrag(vertOutput i):SV_TARGET
            {
                // half4 col = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                half4 lightMap = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, i.uv);
                // half4 col = RampLUT(0, lightMap.a); //以RampTex中最左侧的颜色为描边颜色
                return _OutlineColor;
            }
            ENDHLSL
        }

        pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            ZWrite On
            ZTest LEqual
            Cull[_CullMode]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _GLOSSINESS_FROM_BASE_ALPHA

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Tags
            {
                "LightMode" = "DepthOnly"
            }
        }
    }

    FallBack "Hidden/Shader Graph/FallbackError"
    CustomEditor "LWGUI.LWGUI"
}