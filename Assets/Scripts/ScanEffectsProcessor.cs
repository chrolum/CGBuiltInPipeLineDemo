using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class ScanEffectsProcessor : MonoBehaviour
{
    public float scanTime = 0;
    public float scanSpeed = 10;
    public Camera scanCamera;

    public Material scanMat;

    bool isScanning = false;

    float radius;

    public UniversalRenderPipelineAsset asset;
    private void Awake() 
    {
        scanCamera.depthTextureMode = DepthTextureMode.Depth;
        scanMat.SetFloat("_CamFar", scanCamera.farClipPlane);
    }
    private void Update() 
    {
        if (isScanning)
        {
            scanTime += Time.deltaTime * scanSpeed / scanCamera.farClipPlane;
            scanMat.SetFloat("_ScanDepth", scanTime);
            if (scanTime * scanCamera.farClipPlane > radius)
            {
                StopProcess();
            }
        }
    }

    public void StartProcess(float radius)
    {
        this.radius = radius;
        scanTime = 0;
        ScriptableRendererFeatureManager.instance.EnableRenderFeature<ScanRendererFeature>(asset);
        isScanning = true;
    }

    public void StopProcess()
    {
        isScanning = false;
        scanTime = 0;
        ScriptableRendererFeatureManager.instance.DisableRenderFeature<ScanRendererFeature>(asset);
    }
}
