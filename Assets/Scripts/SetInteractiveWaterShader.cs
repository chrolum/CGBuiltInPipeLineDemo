using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SetInteractiveWaterShader : MonoBehaviour
{
    [SerializeField]
    public RenderTexture water_rt;
    public Transform target;

    private void Awake() {
        Shader.SetGlobalTexture("_GlobalWaterEffectRT", water_rt);
    }

    private void Update() {
        transform.position = new Vector3(target.transform.position.x, transform.position.y, target.transform.position.z);
    }
}
