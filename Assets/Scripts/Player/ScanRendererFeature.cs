using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
 
public class ScanRendererFeature : ScriptableRendererFeature {
 
    public class ScanRendererPass : ScriptableRenderPass {  
         
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData) 
        {
            CommandBuffer cmd = CommandBufferPool.Get();
            RenderTargetIdentifier src = BuiltinRenderTextureType.CameraTarget;
            RenderTargetIdentifier dst = BuiltinRenderTextureType.CurrentActive;
            cmd.Blit(src, dst, GlobalGameManager.instance.scanMat);
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
        renderer.EnqueuePass(m_ScanRendererPass);
    }
}