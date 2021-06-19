using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TimeSystem : MonoBehaviour
{
    public Transform Sun;

    public float Speed;
    

    private void Update() {
        Quaternion quat = Quaternion.AngleAxis(Speed, Vector3.right);
        Sun.rotation = Sun.rotation * quat;
    }
}
