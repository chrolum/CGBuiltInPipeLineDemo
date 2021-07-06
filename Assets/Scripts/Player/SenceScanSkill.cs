using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SenceScanSkill : MonoBehaviour
{
    public float radius = 10f;
    public ScanEffectsProcessor scanEffectsProcessor;

    public LinkedList<GameObject> scanableObj;
    
    float scanTime;

    float scanSpeed = 10f;
    public void StartScan()
    {
        Debug.Log("Start Scan");
        scanEffectsProcessor.StartProcess(radius);
        return;
    }

    private void Update() 
    {
        
    }
}
