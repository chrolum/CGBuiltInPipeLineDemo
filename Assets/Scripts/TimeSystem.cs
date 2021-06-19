using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TimeSystem : MonoBehaviour
{
    public Transform Sun;

    public float Speed;
    public float beginTimeStamp;

    // pre load area
    Quaternion quatSun;

    private void Awake() {
        beginTimeStamp = Time.time;
    }

    private void Update() {
        quatSun = Quaternion.AngleAxis(Speed, Vector3.right);
        Sun.rotation = Sun.rotation * quatSun;

    }
}
