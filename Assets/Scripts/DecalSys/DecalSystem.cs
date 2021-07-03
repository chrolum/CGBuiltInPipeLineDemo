using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering.Universal;

[ExecuteInEditMode]
public class DecalSystem : MonoBehaviour
{
    
    public Texture texture;
    public Color tint = Color.white;
    public Mesh m_cubeMesh;
    public Material m_mat;

    MaterialPropertyBlock props;

    public Camera cam;
    
    private void OnEnable() 
    {
        props = new MaterialPropertyBlock(); 
    }

    private void Draw(Camera camera)
    {
        if (texture != null)
        {
            props.SetTexture("_MainTex", texture);
        }
        props.SetColor("_Tint", tint);
        Graphics.DrawMesh(m_cubeMesh, transform.localToWorldMatrix, m_mat, 0, null, 0, props, false, true, false);
    }

    private void LateUpdate() 
    {
        // if camera is null, draw for all camera
        Draw(cam); 
    }

    #if UNITY_EDITOR
    private void DrawGizmo(bool selected)
    {
        var col = new Color(0.0f, 0.7f, 1f, 1.0f);
        col.a = selected ? 0.3f : 0.1f;
        Gizmos.color = col;
        Gizmos.matrix = transform.localToWorldMatrix;
        Gizmos.DrawCube(Vector3.zero, Vector3.one);
        col.a = selected ? 0.5f : 0.2f;
        Gizmos.color = col;
        Gizmos.DrawWireCube(Vector3.zero, Vector3.one);
        Handles.matrix = transform.localToWorldMatrix;
        Handles.DrawBezier(Vector3.zero, Vector3.down, Vector3.zero, Vector3.down, Color.red, null, selected ? 4f : 2f);
    }
#endif
  

#if UNITY_EDITOR
    public void OnDrawGizmos()
    {
        DrawGizmo(false);
    }
    public void OnDrawGizmosSelected()
    {
        DrawGizmo(true);
    }
#endif

}
