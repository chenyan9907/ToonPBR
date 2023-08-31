using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class ToonHairShadowFeature : ScriptableRendererFeature
{
    //Render Feature参数面板设置
    [System.Serializable]
    public class Setting
    {
        //选择插入位置
        public RenderPassEvent PassEvent = RenderPassEvent.BeforeRenderingOpaques;

        //标记头发模型的Layer
        public LayerMask hairLayer;
        public LayerMask faceLayer;

        //头发阴影颜色
        public Color hairShadowColor;

        //阴影偏移距离
        public float offset = 0.005f;
        public int stencilID = 1;
        public CompareFunction compareFunc;


        //Render Queue的设置
        [Range(1000, 5000)] public int queueMin = 2000;
        [Range(1000, 5000)] public int queueMax = 3000;

        //脸部重绘
        public Texture2D MainTex;
        public Texture2D SSSLutTex;
        public Texture2D FaceSDF;
        public Texture2D SkinShadowMap;
        public float CurveFactor = 1f;
        public float FaceSoftShadow = 0.1f;
        public float SkinSSSDarkBound = 0.43f;
        public float SkinSSSDBrightBound = 0.9f;
        public Color SpecularColor = Color.white;
        public float LobeWeight = 1f;
        public float DirectSpecularIntensity = 5f;
        public float IndirectSpecularIntensity = 2f;


        //使用的Material
        public Material material;
    }

    public Setting setting = new Setting();
    ToonHairShadowPass m_ScriptablePass;

    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new ToonHairShadowPass(setting);

        // Configures where the render pass should be injected.
        m_ScriptablePass.renderPassEvent = setting.PassEvent;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (setting.material != null)
        {
            renderer.EnqueuePass(m_ScriptablePass);
        }
    }

    class ToonHairShadowPass : ScriptableRenderPass
    {
        public ShaderTagId shaderTag = new ShaderTagId("UniversalForward");
        public Setting setting;

        private FilteringSettings Hairfiltering;
        private FilteringSettings Facefiltering;

        //刘海投影渲染Pass构造函数
        public ToonHairShadowPass(Setting setting)
        {
            this.setting = setting;
            RenderQueueRange queue = new RenderQueueRange();
            queue.lowerBound = Mathf.Min(setting.queueMin, setting.queueMax);
            queue.upperBound = Mathf.Max(setting.queueMin, setting.queueMax);
            Hairfiltering = new FilteringSettings(queue, setting.hairLayer);
            Facefiltering = new FilteringSettings(queue, setting.faceLayer);
        }

        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        //每帧执行，在里面申请RenderTexture、设置RenderTarget、和ClearRenderTarget。记得用ConfigureRenderTarget()和ConfigureClear()，不要用cmd.SetRenderTarget()这些方法，用urp推荐的方法。
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            setting.material.SetColor("_Color", setting.hairShadowColor);
            setting.material.SetInt("_StencilID", setting.stencilID);
            setting.material.SetInt("_StencilComp", (int) setting.compareFunc);
            setting.material.SetFloat("_Offset", setting.offset);

            setting.material.SetTexture("_MainTex", setting.MainTex);
            setting.material.SetTexture("_FaceSDF", setting.FaceSDF);
            setting.material.SetTexture("_SSSLUTTex", setting.SSSLutTex);
            setting.material.SetTexture("_SkinShadowMap", setting.SkinShadowMap);
            setting.material.SetFloat("_CurveFactor", setting.CurveFactor);
            setting.material.SetFloat("_FaceSoftShadow", setting.FaceSoftShadow);
            setting.material.SetFloat("_SkinSSSDarkBound", setting.SkinSSSDarkBound);
            setting.material.SetFloat("_SkinSSSBrightBound", setting.SkinSSSDBrightBound);
            setting.material.SetColor("_SpecularColor", setting.SpecularColor);
            setting.material.SetFloat("_LobeWeight", setting.LobeWeight);
            setting.material.SetFloat("_DirectSpecularIntensity", setting.DirectSpecularIntensity);
            setting.material.SetFloat("_IndirectSpecularIntensity", setting.IndirectSpecularIntensity);
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        //每帧执行，在里面做DrawMesh或者Blit之类的操作。可以用CommandBufferPool.Get("String")来申请CommandBuffer，之后要记得通过Context.ExecuteCommandBuffer来提交命令。CommandBuffer用完之后记得释放
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var draw = CreateDrawingSettings(shaderTag, ref renderingData, renderingData.cameraData.defaultOpaqueSortFlags);
            draw.overrideMaterial = setting.material;
            draw.overrideMaterialPassIndex = 0;

            //获取主光源位置，并转换到相机空间
            var visibleLight = renderingData.cullResults.visibleLights[0];
            Vector2 lightDirSS = renderingData.cameraData.camera.worldToCameraMatrix * visibleLight.localToWorldMatrix.GetColumn(2);
            setting.material.SetVector("_LightDirSS", lightDirSS);
            
            //给cmd指定一个名字
            CommandBuffer cmd = CommandBufferPool.Get("DrawHairShadow");
            context.ExecuteCommandBuffer(cmd);
            context.DrawRenderers(renderingData.cullResults, ref draw, ref Hairfiltering);
                        
            draw.overrideMaterialPassIndex = 1;
            context.DrawRenderers(renderingData.cullResults, ref draw, ref Facefiltering);
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        //每帧执行，在这里面释放申请的RT
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
    }
}