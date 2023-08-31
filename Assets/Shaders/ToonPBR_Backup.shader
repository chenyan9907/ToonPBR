Shader "Custom/ToonPBR_BackUp"
{
    Properties
    {
        [Main(GroupName)] _group ("Group", float) = 0
        [Sub(GroupName)] _float ("Float", float) = 0


        [Main(Group1, _KEYWORD, on)] _group1 ("Group - Default Open", float) = 1
        [Sub(Group1)] _float1 ("Sub Float", float) = 0
        [Sub(Group1)] _vector1 ("Sub Vector", vector) = (1, 1, 1, 1)
        [Sub(Group1)] [HDR] _color1 ("Sub HDR Color", color) = (0.7, 0.7, 1, 1)

        [Title(Group1, Conditional Display Samples       Enum)]
        [KWEnum(Group1, Name 1, _KEY1, Name 2, _KEY2, Name 3, _KEY3)]
        _enum ("KWEnum", float) = 0

        // Display when the keyword ("group name + keyword") is activated
        [Sub(Group1_KEY1)] _key1_Float1 ("Key1 Float", float) = 0
        [Sub(Group1_KEY2)] _key2_Float2 ("Key2 Float", float) = 0
        [Sub(Group1_KEY3)] _key3_Float3_Range ("Key3 Float Range", Range(0, 1)) = 0
        [SubPowerSlider(Group1_KEY3, 10)] _key3_Float4_PowerSlider ("Key3 Power Slider", Range(0, 1)) = 0

        [Title(Group1, Conditional Display Samples       Toggle)]
        [SubToggle(Group1, _TOGGLE_KEYWORD)] _toggle ("SubToggle", float) = 0
        [Tex(Group1_TOGGLE_KEYWORD)][Normal] _normal ("Normal Keyword", 2D) = "bump" { }
        [Sub(Group1_TOGGLE_KEYWORD)] _float2 ("Float Keyword", float) = 0


        [Main(Group2, _, off, off)] _group2 ("Group - Without Toggle", float) = 0
        [Sub(Group2)] _float3 ("Float 2", float) = 0


        [Main(ShaderSettings, _, off, off)] _shaderSettingsGroup ("着色器设置", Float) = 0
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode("剔除模式",Int) = 0
        [KeywordEnum(Base,Skin,Face,Hair,Eyes)]_ShaderType("渲染类型",Int) = 0

        [Header(General Settings)][Space(10)]
        [HDR] _MainColor("主纹理颜色",Color) = (1,1,1,1)
        _MainTex("主纹理贴图",2D) = "white"{}
        [Toggle(_NORMALMAP)] _EnableBumpMap("启用法线贴图", Int) = 0
        [KeywordEnum(3Channel,2Channel)]_NormalType("法线贴图类型",Int) = 0
        _NormalScale("法线强度",Range(0,1)) = 1.0
        [Normal] _NormalMap("法线贴图",2D) = "bump"{}
        _LightMap("光照贴图（R：粗糙度，G：金属度，B：环境光遮蔽）",2D) = "white"{}
        _RoughnessScale("粗糙度强度",Range(0,1)) = 1.0
        _MetallicScale("金属度强度",Range(0,1)) = 1.0
        _OcclusionScale("环境光遮蔽强度",Range(0,1)) = 1.0
        [Toggle(_ANISOTROPIC_SPEC)] _EnableAnisotropicSpec("启用各向异性高光", Int) = 0
        _AnisotropicIntensity("各向异性强度",Float) = 1
        [HDR] _SpecularColor("高光颜色",Color) = (1.0,1.0,1.0,1.0)
        _DirectSpecularIntensity("直接照明高光强度",Float) = 1
        _IndirectSpecularIntensity("间接照明高光强度",Float) = 1
        [Toggle(_SPHEREMAP)] _EnableSphereCube("启用球面贴图", Int) = 1
        [KeywordEnum(Add,Mul)]_SphereCubeType("球面贴图类型",Int) = 0
        _SphereCube("球面贴图",Cube) = "white"{}
        _DarkLB("NPR暗部柔和过渡下界",Range(0,1)) = 0.3
        _DarkUB("NPR暗部柔和过渡上界",Range(0,1)) = 0.7

        [Header(Skin Settings)][Space(10)]
        _SSSLUTTex("皮肤SSS贴图",2D) = "white"{}
        _CurveFactor("皮肤曲率因子",Float) = 1
        _SkinShadowMap("皮肤阴影贴图",2D) = "white"{}

        [Header(Face Settings)][Space(10)]
        _FaceSDF("脸部SDF贴图",2D) = "white"{}
        _FaceSoftShadow("脸部阴影柔和过渡",Range(0,1)) = 0.2
        _FaceBrightness("脸部亮度",Range(0,0.99)) = 0.85

        [Header(Eyes Settings)][Space(10)]
        [Toggle(_PARALLAX)] _EnableEyeRefraction("启用瞳孔折射", Int) = 0
        _ParallaxHeight("折射视差高度",Float) = 0.2
        _EyeMatCap("MatCap贴图",2D) = "black"{}

        [Header(Hair Settings)][Space(10)]
        _TangentMap("修正切线贴图",2D) = "white"{}
        _Reflection_Anisotropic_Anisotropy_Direction("test",float) = 0
        _JitterMap("扰动贴图",2D) = "black"{}

        [Header(Outline)][Space(10)]
        [Toggle]_EnableOutline("Enable Outline",int) = 1
        _OutlineColor("Outline Color",Color) = (1.0,1.0,1.0,1.0)
        _OutlineWidth("Outline Width",Range(0,4)) = 1
        _OutlineFlag("Outline Flag",int) = 1

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
        #pragma shader_feature _SPHEREMAP
        #pragma shader_feature _SPHERECUBETYPE_ADD _SPHERECUBETYPE_MUL
        #pragma shader_feature _PARALLAX
        #pragma shader_feature_local _SHADERTYPE_BASE _SHADERTYPE_SKIN _SHADERTYPE_HAIR _SHADERTYPE_FACE _SHADERTYPE_EYES
        #pragma shader_feature _ANISOTROPIC_SPEC
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
        float _DarkLB;
        float _DarkUB;
        float _CurveFactor;
        float _FaceSoftShadow;
        float _FaceBrightness;
        float _ParallaxHeight;

        float _Reflection_Anisotropic_Anisotropy_Direction;

        int _EnableOutline;
        float4 _OutlineColor;
        float _OutlineWidth;
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
        TEXTURE2D(_TangentMap);
        SAMPLER(sampler_TangentMap);
        TEXTURE2D(_JitterMap);
        SAMPLER(sampler_JitterMap);
        TEXTURE2D(_EyeMatCap);
        SAMPLER(sampler_EyeMatCap);

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


                //-----------------------------------------------------眼睛MatCap---------------------------------------------------------
                //眼睛折射，通过视差实现，重新采样眼睛纹理
                #if defined(_SHADERTYPE_EYES)
                float3 normalVS_MatCap = TransformWorldToViewNormal(normalWS, true);
                float3 viewDirVS_MatCap = normalize(TransformWorldToView(i.positionWS)); //视线向量，由于是在相机空间，所以不用做向量减法，直接将片元坐标变换到相机空间即可
                float3 NcrossV = cross(viewDirVS_MatCap, normalVS_MatCap);
                float2 matCapUV = float2(-NcrossV.y,NcrossV.x)*0.5+0.5;
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
                float3 bakedTangent = SAMPLE_TEXTURE2D(_TangentMap, sampler_TangentMap, i.uv) * 2 - 1;
                // bakedTangent.xy = bakedTangent.yx;
                // bakedTangent.x = -bakedTangent.x;
                // float a = _Reflection_Anisotropic_Anisotropy_Direction / 180 * 3.1415926;
                // float3x3 tangent_roate = float3x3(cos(a), sin(a), 0,
                //                                   sin(a), cos(a), 0,
                //                                   0, 0, 1
                // );

                // bakedTangent = mul(tangent_roate, bakedTangent);
                //切线空间到世界空间
                //transform into render space
                // bakedTangent = bakedTangent.x * s.vertexTangent +
                //     bakedTangent.y * s.vertexBitangent +
                //     bakedTangent.z * s.vertexNormal;
                bakedTangent = mul(bakedTangent, tangentToWorld);

                //project tangent onto normal plane
                // bakedTangent = bakedTangent - normalWS * dot(bakedTangent, normalWS);
                bakedTangent = normalize(bakedTangent);
                float3 bakedbitangent = normalize(cross(normalWS, bakedTangent));
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
                float3 directBRDF = dTerm * fTerm * gTerm / (4.0 * NdotV * NdotL);
                //漫反射部分由能量守恒得到
                float3 Ks = fTerm;
                //金属是没有漫反射的,所以Kd需要乘上1-metallic (折射光中属于金属的部分不会形成漫反射)
                float3 Kd = (1 - Ks) * (1 - metallic);
                float3 diffuseColor = Kd * baseColor.xyz * occlusion;
                float3 directLighting = diffuseColor + directBRDF * _SpecularColor.xyz * _DirectSpecularIntensity;
                // directLighting *= radiance;

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


                //--------------------------------------------------SSS计算（皮肤&脸部）---------------------------------------------------------
                //皮肤SSS(2DRamp)
                #if _SHADERTYPE_SKIN
                float cuv = saturate(_CurveFactor * (length(fwidth(normalWS)) / length(fwidth(i.positionWS))));
                float NoL = dot(normalWS, lightDir);
                NoL = clamp(NoL,0.01,0.99);       //钳制UV，防止采样到边缘
                cuv = clamp(cuv,0.01,0.99);
                float3 skinShadowMap = SAMPLE_TEXTURE2D(_SkinShadowMap,sampler_SkinShadowMap,i.uv).rgb;    //采样皮肤阴影贴图（R通道表示常暗区域，用于过度脖子和脸部，B通道可能是高光）
                NoL *= skinShadowMap.r;
                float3 sssColor = SAMPLE_TEXTURE2D(_SSSLUTTex, sampler_SSSLUTTex, TRANSFORM_TEX(float2(NoL * 0.5 + 0.5, cuv),_SSSLUTTex)).rgb * mainLight.color;
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
                float3 skinShadowMap = SAMPLE_TEXTURE2D(_SkinShadowMap,sampler_SkinShadowMap,i.uv).rgb;    //采样皮肤阴影贴图（R通道表示常暗区域，用于过度脖子和脸部，B通道可能是高光）
                bias *= skinShadowMap.r;

                //以下为皮肤SSS，同_SHADERTYPE_SKIN，但bias替换NoL
                float cuv = saturate(_CurveFactor * (length(fwidth(normalWS)) / length(fwidth(i.positionWS))));
                bias = clamp(bias*0.5+0.5,0.01,_FaceBrightness);       //钳制UV，防止采样到边缘，同时限制一下bias的最大值，防止过亮，与皮肤亮部保持一致
                cuv = clamp(cuv,0.01,0.99);
                float3 sssColor = SAMPLE_TEXTURE2D(_SSSLUTTex, sampler_SSSLUTTex, TRANSFORM_TEX(float2(bias, cuv),_SSSLUTTex)).rgb * mainLight.color;
                // sssColor =float3(skinShadowMap.r, skinShadowMap.r,skinShadowMap.r);
                // finalColor = sssColor+indirectLighting;
                // directLighting = directLighting/NdotL*sssColor;      //皮肤SSS包含了NdotL，最后整合直接间接光照时也会乘上NdotL，所以这里提前除一个（会影响到加算的球面贴图）
                #endif
                //--------------------------------------------------------------------------------------------------------------------------


                //--------------------------------------------------球面贴图计算------------------------------------------------------------
                //球面贴图
                #if defined(_SPHEREMAP)
                float3 normalVS = TransformWorldToViewNormal(normalWS, true);
                float3 viewDirVS = normalize(TransformWorldToView(i.positionWS)); //视线向量，由于是在相机空间，所以不用做向量减法，直接将片元坐标变换到相机空间即可
                float3 uvwSphere = reflect(viewDirVS, normalVS);
                half3 sph = SAMPLE_TEXTURECUBE(_SphereCube, sampler_SphereCube, uvwSphere).rgb;
                #if defined(_SPHERECUBETYPE_ADD)
                indirectLighting += sph;
                #else
                directLighting *= sph;
                #endif
                #endif
                //--------------------------------------------------------------------------------------------------------------------------

                //根据不同部位，整合最终光照
                #if defined(_SHADERTYPE_BASE)
                finalColor = directLighting * radiance + indirectLighting;
                #elif defined(_SHADERTYPE_SKIN)
                //皮肤SSS包含了NdotL和mainLight.color，可替代radiance，shadowAttenuation不知道需不需要乘上
                finalColor = directLighting * sssColor + indirectLighting;
                // finalColor = sssColor;
                #elif defined(_SHADERTYPE_FACE)
                finalColor = directLighting * sssColor + indirectLighting;
                // finalColor = sssColor;
                #elif defined(_SHADERTYPE_EYES)
                finalColor = directLighting;
                #else
                finalColor = directLighting * radiance + indirectLighting;
                // finalColor = i.tangentWS;
                // finalColor = bakedTangent;
                // float2 uv = i.uv * bakedTangent.yx;
                // float shift = SAMPLE_TEXTURE2D(_JitterMap,sampler_JitterMap,TRANSFORM_TEX(i.uv,_JitterMap));
                // bakedTangent = bakedTangent + shift * normalWS;
                // bakedTangent = normalize(bakedTangent);
                // half TdotH = dot(bakedTangent, halfDir);
                // half TsinH = sqrt(1 - TdotH * TdotH);
                // half3 specCol = pow(TsinH, 200);
                // float dirAtten = smoothstep(-1.0,0.0,TdotH);
                // finalColor = finalColor + specCol * dirAtten;
                // finalColor = float3(bakedTangent);
                #endif

                return half4(finalColor, 1);
            }
            ENDHLSL
        }

        Pass
        {
            Name "OutlinePass"
            Tags {}
            Cull Front
            Stencil
            {
                Ref [_OutlineFlag]
                Comp NotEqual
                Pass Replace
            }

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
                o.tangentWS = float4(vertexNormalInputs.tangentWS, 1.0);
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
    }
    FallBack "Hidden/Shader Graph/FallbackError"
    CustomEditor "LWGUI.LWGUI"
}