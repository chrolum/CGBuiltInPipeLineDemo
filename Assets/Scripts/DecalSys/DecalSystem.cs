using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DecalSystem : MonoBehaviour
{
    
    public Texture texture;
    public Color tint = Color.white;
    public Mesh m_cubeMesh;
    public Material m_mat;

    MaterialPropertyBlock props;
    
    private void OnEnable() 
    {
        props = new MaterialPropertyBlock();
        Camera.onPreCull -= DrawWithCamera;
        Camera.onPreCull += DrawWithCamera;      
    }

    private void OnDisable() 
    {
        Camera.onPreCull -= DrawWithCamera;
    }

    private void DrawWithCamera(Camera camera) 
    {
        if (camera) 
        {
            Draw(camera);
        }
    }

    private void Draw(Camera camera)
    {
        if (texture)
        {
            props.SetTexture("_MainTex", texture);
        }
        props.SetColor("_Tint", tint);
        Graphics.DrawMesh(m_cubeMesh, transform.localToWorldMatrix, m_mat, 0, camera, 0, props, false, true, false);
    }

}
