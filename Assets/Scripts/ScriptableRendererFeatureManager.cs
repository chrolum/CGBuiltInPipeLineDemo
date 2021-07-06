using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class ScriptableRendererFeatureManager : MonoBehaviour
{
    public static ScriptableRendererFeatureManager instance;

    private List<ScriptableRendererFeature> m_DisabledRenderFeatures;

    private void Start() 
    {
        instance = this;    
        m_DisabledRenderFeatures = new List<ScriptableRendererFeature>();
    }

    public void DisableRenderFeature<T>(UniversalRenderPipelineAsset asset) where T : ScriptableRendererFeature
    {
        var renderFeature = asset.DisableRenderFeature<T>();
 
        if (renderFeature != null)
        {
            m_DisabledRenderFeatures.Add(renderFeature);
        }
    }

    public ScriptableRendererFeature EnableRenderFeature<T>(UniversalRenderPipelineAsset asset) where T : ScriptableRendererFeature
    {
        //TODO:
        foreach (var renderFeature in m_DisabledRenderFeatures)
        {
            if (renderFeature is T)
            {
                renderFeature.SetActive(true);
                return renderFeature;
            }
        }

        var type = asset.GetType();
        var propertyInfo = type.GetField("m_RendererDataList", BindingFlags.Instance | BindingFlags.NonPublic);
 
        if (propertyInfo == null)
        {
            return null;
        }
 
        var scriptableRenderData = (ScriptableRendererData[])propertyInfo.GetValue(asset);

        foreach (var renderData in scriptableRenderData)
        {
            foreach (var rendererFeature in renderData.rendererFeatures)
            {
                if (rendererFeature is T)
                {
                    rendererFeature.SetActive(true);

                    return rendererFeature;
                }
            }
        }
        Debug.LogWarning("Targer Feature not found");
        return null;
    }
}
