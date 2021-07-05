using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ScanEffectsProcessor : MonoBehaviour
{
    public float scanTime = 0;
    public float scanSpeed = 10;
    public Camera scanCamera;

    public Material scanMat;

    private void Awake() 
    {
        scanMat.SetFloat("_CamFar", scanCamera.farClipPlane);
    }
    private void Update() 
    {
        scanTime += Time.deltaTime * scanSpeed / scanCamera.farClipPlane;
        scanMat.SetFloat("_ScanDepth", scanTime);
    }

    public void StartProcess()
    {
        scanTime = 0;
    }
}
