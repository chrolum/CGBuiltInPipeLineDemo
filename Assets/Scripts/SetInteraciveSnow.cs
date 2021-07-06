using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SetInteraciveSnow : MonoBehaviour
{
    [SerializeField]
    public RenderTexture rt;
    public Transform target;

    private void Awake() {
        Shader.SetGlobalTexture("_GlobalEffectRT", rt);
        Shader.SetGlobalFloat("_OrthographicCamSize", GetComponent<Camera>().orthographicSize);
    }

    private void Update() {
        transform.position = new Vector3(target.transform.position.x, transform.position.y, target.transform.position.z);
        Shader.SetGlobalVector("_Position", target.position);
    }
}