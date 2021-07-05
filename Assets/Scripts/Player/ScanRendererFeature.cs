using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
 
public class ScanRendererFeature : ScriptableRendererFeature {
 
    public class ScanRendererPass : ScriptableRenderPass {  
         
        public RenderTargetIdentifier src;
        private RenderTargetHandle m_TemporaryColorTexture;

        public ScanRendererPass()
        {
            m_TemporaryColorTexture.Init("_TemporaryColorTexture");
        }
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData) 
        {
            CommandBuffer cmd = CommandBufferPool.Get();
            RenderTargetIdentifier dst = BuiltinRenderTextureType.CurrentActive;
            // can't not read and write the same RT at the same time
            // write camera color texture into a tmp texture
            RenderTextureDescriptor opaqueDesc = renderingData.cameraData.cameraTargetDescriptor;
            cmd.GetTemporaryRT(m_TemporaryColorTexture.id, opaqueDesc);
            cmd.Blit(src, m_TemporaryColorTexture.Identifier(), GlobalGameManager.instance.scanMat);
            // write back into camera
            cmd.Blit(m_TemporaryColorTexture.Identifier(), src);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
    ScanRendererPass m_ScanRendererPass;
    public RenderPassEvent TheRenderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;

    public override void Create()
    {
        m_ScanRendererPass = new ScanRendererPass();
        m_ScanRendererPass.renderPassEvent = TheRenderPassEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        m_ScanRendererPass.src =  renderer.cameraColorTarget;
        renderer.EnqueuePass(m_ScanRendererPass);
    }
}