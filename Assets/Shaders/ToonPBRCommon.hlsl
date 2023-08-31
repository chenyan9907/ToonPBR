//D项，法线分布函数：表示微观层面上，表面法线对于表面面积的统计分布，受粗糙度影响
//简而言之就是微观层面上的面片法线分布与宏观层面上该面片的法线的一致程度
float NormalDistributionFunc_GGX(float NdotH, float roughness)
{
    //迪士尼原则中的 a
    float a = roughness * roughness;
    float a2 = a * a;
    float NdotH2 = NdotH * NdotH;
    float num = a2;
    float denom = NdotH2 * (a2 - 1.0) + 1.0;
    denom = PI * denom * denom;
    return num / denom;
}

//各向异性的D法线分布函数
float AnisotropicNormalDistribution_GGX(float NdotH, float HdotX, float HdotY, float anisotropic, float roughness)
{
    float aspect = sqrt(1.0 - 0.9 * anisotropic);
    float a = roughness * roughness;
    float NdotH2 = NdotH * NdotH;
    float ax = a / aspect;
    float ay = a * aspect;
    float HdotX2 = HdotX * HdotX;
    float HdotY2 = HdotY * HdotY;
    float denom = HdotX2 / (ax * ax) + HdotY2 / (ay * ay) + NdotH2;
    return 1 / (PI * ax * ay * denom * denom);
}

//F项，菲涅尔项：反射光线对比被折射的光线所占比重，是渲染方程中的Ks
//垂直观察时，具有基础反射率F0
float3 Fresnel_Schlick(float VdotH, float3 F0)
{
    return F0 + (1 - F0) * pow(1 - VdotH, 5);
}

//G项，几何函数：描述微平面自遮挡比例，同时考虑视线和光线方向的自遮挡，受粗糙度影响
float GeometryFunc_SchlickGGX(float NdotV, float NdotL, float roughness)
{
    float a = roughness * roughness;
    float r = a + 1.0;
    float k = (r * r) / 8.0;
    float GV = NdotV / (NdotV * (1.0 - k) + k); //视线方向
    float GL = NdotL / (NdotL * (1.0 - k) + k); //光线方向
    return GV * GL;
}

float3 DirectBDRF_DualLobeSpecular(float roughness, float3 F0, half3 normalWS, half3 lightDirWS, half3 viewDirWS, half mask, half lobeWeight)
{
    float3 halfDir = SafeNormalize(float3(lightDirWS) + float3(viewDirWS));

    float NoH = saturate(dot(normalWS, halfDir));
    half LoH = saturate(dot(lightDirWS, halfDir));

    float roughness2 = roughness * roughness;
    float roughness2MinusOne = roughness2 - 1.0;
    float normalizationTerm = roughness * 4.0 + 2.0;

    float d = NoH * NoH * roughness2MinusOne + 1.00001f;
    half nv = saturate(dot(normalWS, lightDirWS));
    half LoH2 = LoH * LoH;
    float sAO = saturate(-0.3f + nv * nv);
    sAO = lerp(pow(0.75, 8.00f), 1.0f, sAO);
    half SpecularOcclusion = sAO;
    half specularTermGGX = roughness2 / ((d * d) * max(0.1h, LoH2) * normalizationTerm);
    half specularTermBeckMann = (2.0 * (roughness2) / ((d * d) * max(0.1h, LoH2) * normalizationTerm)) * lobeWeight * mask;
    half specularTerm = (specularTermGGX / 2 + specularTermBeckMann) * SpecularOcclusion;

    float3 color = specularTerm * F0;
    return color;
}

float3 ClearCoatPBR(float clearCoatRoughness, float3 F0, float IOR)
{
    float3 diffuse = kDielectricSpec.aaa; // 1 - kDielectricSpec
    float3 specular = kDielectricSpec.rgb;
    float3 reflectivity = kDielectricSpec.r;

    float Roughness = PerceptualRoughnessToRoughness(clearCoatRoughness); //迪士尼a = roughness^2，从参数调整粗糙度变为计算所使用的粗糙度
    float Roughness2 = Roughness * Roughness;
    float normalizationTerm = Roughness * 4.0 + 2.0;
    float Roughness2MinusOne = Roughness2 - 1.0;
    float grazingTerm = saturate(1.0 - clearCoatRoughness + kDielectricSpec.x);
    float ieta = 1.0 / IOR;
    float coatRoughnessScale = Sq(ieta);
    float sigma = RoughnessToVariance(Roughness);
}

//计算PBR直接光照结果
float3 DirectPBR(float NdotH, float NdotV, float NdotL, float VdotH, float HdotX, float HdotY,
                 float3 baseColor, float3 F0, float roughness, float metallic, float occlusion, float directSpecularIntensity)
{
    //高光部分
    float dTerm = NormalDistributionFunc_GGX(NdotH, roughness);
    float3 fTerm = Fresnel_Schlick(VdotH, F0);
    float gTerm = GeometryFunc_SchlickGGX(NdotV, NdotL, roughness);
    float3 specularColor = dTerm * fTerm * gTerm / (4.0 * NdotV * NdotL);

    //漫反射部分由能量守恒得到
    float3 Ks = fTerm;
    //金属是没有漫反射的,所以Kd需要乘上1-metallic (折射光中属于金属的部分不会形成漫反射)
    float3 Kd = (1 - Ks) * (1 - metallic);
    float3 diffuseColor = Kd * baseColor * occlusion;
    float3 directLight = diffuseColor + specularColor * directSpecularIntensity;
    return directLight;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------间接光照部分-------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------------------------------------

float3 Indir_Fresnel_Schlick(float VdotH, float3 F0, float roughness)
{
    // https://www.jianshu.com/p/d8579d9a4eb6   球面高斯近似（Spherical Gaussian approximation）拟合F_{SG Approx}
    // float Fre=exp2((-5.55473*VdotH-6.98316)*VdotH);
    // return F0+(1-F0)*Fre;
    return F0 + (max(1 - roughness, F0) - F0) * pow(1 - VdotH, 5.0);
}

//间接光漫反射 球谐函数 光照探针
float3 SH_IndirectionDiff(float3 normalWS)
{
    real4 SHCoefficients[7];
    SHCoefficients[0] = unity_SHAr;
    SHCoefficients[1] = unity_SHAg;
    SHCoefficients[2] = unity_SHAb;
    SHCoefficients[3] = unity_SHBr;
    SHCoefficients[4] = unity_SHBg;
    SHCoefficients[5] = unity_SHBb;
    SHCoefficients[6] = unity_SHC;
    float3 Color = SampleSH9(SHCoefficients, normalWS);
    return max(0, Color);
}

//间接光高光 反射探针
float3 IndirSpeCube(float3 normalWS, float3 viewWS, float roughness, float AO)
{
    float3 reflectDirWS = reflect(-viewWS, normalWS);
    roughness = roughness * (1.7 - 0.7 * roughness); //Unity内部不是线性 调整下拟合曲线求近似
    float MidLevel = roughness * 6; //把粗糙度remap到0-6 7个阶级 然后进行lod采样
    float4 speColor = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDirWS, MidLevel); //根据不同的等级进行采样
    #if !defined(UNITY_USE_NATIVE_HDR)
    return DecodeHDREnvironment(speColor, unity_SpecCube0_HDR) * AO;
    //用DecodeHDREnvironment将颜色从HDR编码下解码。可以看到采样出的rgbm是一个4通道的值，最后一个m存的是一个参数，解码时将前三个通道表示的颜色乘上xM^y，x和y都是由环境贴图定义的系数，存储在unity_SpecCube0_HDR这个结构中。
    #else
    return speColor.xyz*AO;
    #endif
}

//间接高光 曲线拟合 放弃LUT采样而使用曲线拟合
float3 IndirSpeFactor(float roughness, float3 BRDFspe, float3 F0, float NdotV)
{
    float smoothness = 1 - roughness;
    #ifdef UNITY_COLORSPACE_GAMMA
    float SurReduction=1-0.28*roughness,roughness;
    #else
    float SurReduction = 1 / (roughness * roughness + 1);
    #endif
    #if defined(SHADER_API_GLES)//Lighting.hlsl 261行
    float Reflectivity=BRDFspe.x;
    #else
    float Reflectivity = max(max(BRDFspe.x, BRDFspe.y), BRDFspe.z);
    #endif
    half GrazingTSection = saturate(Reflectivity + smoothness);
    float Fre = Pow4(1 - NdotV); //lighting.hlsl第501行 
    //float Fre=exp2((-5.55473*NdotV-6.98316)*NdotV);//lighting.hlsl第501行 它是4次方 我是5次方 
    return lerp(F0, GrazingTSection, Fre) * SurReduction;
}

float3 CalcBRDFSpeSection(float VdotH, float NdotV, float NdotL, float NdotH, float3 F0, float roughness)
{
    float dTerm = NormalDistributionFunc_GGX(NdotH, roughness);
    float gTerm = GeometryFunc_SchlickGGX(NdotV, NdotL, roughness);
    float3 fTerm = Fresnel_Schlick(VdotH, F0);

    //max 0.001 保证分母不为0
    float3 specularFactor = dTerm * gTerm * fTerm / (4.0 * max(0.001, NdotV * NdotL));
    return specularFactor;
}

float3 IndirectPBR(float NdotH, float NdotV, float NdotL, float VdotH, float3 normalWS, float3 viewDirWS,
                   float3 baseColor, float3 F0, float roughness, float metallic, float occlusion, float indirectSpecularIntensity)
{
    // roughness = roughness * roughness;
    //间接光diffuse
    float3 SHcolor = SH_IndirectionDiff(normalWS) * occlusion;
    float3 IndirKS = Indir_Fresnel_Schlick(NdotV, F0, roughness);
    float3 IndirKD = (1 - IndirKS) * (1 - metallic);
    float3 IndirDiffuseColor = SHcolor * IndirKD * baseColor;

    //间接光specular
    float3 IndirSpeCubeColor = IndirSpeCube(normalWS, viewDirWS, roughness, occlusion);
    float3 BRDFSpeSection = CalcBRDFSpeSection(VdotH, NdotV, NdotL, NdotH, F0, roughness);
    float3 IndirSpeCubeFactor = IndirSpeFactor(roughness, BRDFSpeSection, F0, NdotV);
    float3 IndirSpeColor = IndirSpeCubeColor * IndirSpeCubeFactor;
    //return float4(IndirSpeColor,1);
    float3 IndirColor = IndirDiffuseColor + IndirSpeColor * indirectSpecularIntensity;
    return IndirColor;
}
